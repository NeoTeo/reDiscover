//
//  TGSongPool.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//


#import "TGSongPool.h"
#import "TGSong.h"
#import "TGSongGridViewController.h"

#import "TGFingerPrinter.h"

#import "TGSongUserData.h"

// The private interface declaration overrides the public one to declare conformity to the Delegate protocols.
@interface TGSongPool () <TGSongDelegate,TGFingerPrinterDelegate>
@end

// constant definitions
static int const kSSCheckCounterSize = 10;
//#define kSSCheckCounterSize 10


@implementation TGSongPool

- (id)init {
    self = [super init];
    if (self != NULL) {
        
        requestedPlayheadPosition = [NSNumber numberWithDouble:0];
        songPoolStartCapacity = 25;
        songPoolDictionary = [[NSMutableDictionary alloc] initWithCapacity:songPoolStartCapacity];
        
        
        playbackQueue = dispatch_queue_create("playback queue", NULL);
        serialDataLoad = dispatch_queue_create("serial data load queue", NULL);
        timelineUpdateQueue = dispatch_queue_create("timeline GUI updater queue", NULL);
        currentlyPlayingSong = NULL;
        
    
        _artArray = [[NSMutableArray alloc] initWithCapacity:100];
        [_artArray addObject:[NSImage imageNamed:@"noCover"]];
        
        songFingerPrinter = [[TGFingerPrinter alloc] init];
        [songFingerPrinter setDelegate:self];

        {
            // Initialize the entity description.
            [self initSongUserDataEntityDescription];
            // Define and init the managed object model.
            [self initSongUserDataManagedObjectModel];
            // Initialize the persistent store coordinator.
            [self initSongPoolPersistentStoreCoordinator];
        }
        songsWithChangesToSave = [[NSMutableSet alloc] init];
        songsWithSaveError = [[NSMutableSet alloc] init];
        fetchedArray = nil;
     
        // Get any user metadata from the local Core Data store.
        [self fetchMetadataFromLocalStore];

        // Register to be notified of idle time starting and ending.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeBegins) name:@"TGIdleTimeBegins" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeEnds) name:@"TGIdleTimeEnds" object:nil];
    }
    return self;
}




- (void)idleTimeBegins {
    NSLog(@"song pool idle start");
    
    [idleTimeFingerprinterTimer invalidate];
    
    // Start a timer that calls idleTimeRequestFingerprint.
    idleTimeFingerprinterTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(idleTimeRequestFingerprint:)
                                                                userInfo:@{@"previousSongID" : [NSNumber numberWithInteger:0]}
                                                repeats:YES];

}


- (void)idleTimeRequestFingerprint:(NSTimer *)theTimer {
    
    NSInteger aSongID = [[[theTimer userInfo] objectForKey:@"previousSongID"] integerValue];
    
    // Stop the fingerprinter timer.
    [idleTimeFingerprinterTimer invalidate];
    
    if (aSongID >= [songPoolDictionary count]) {
        // We've done all the songs. Return without starting a new timer.
        NSLog(@"No more songs to fingerprint");
        return;
    }

    // TEO songid?
    TGSong * aSong = [songPoolDictionary objectForKey:[NSNumber numberWithInteger:aSongID]];
    
    // Unless a fingerprint is actually requested we set the interval until the next timer to as little as possible.
    NSInteger interval = 0;
    
    if ([aSong songUUIDString] == NULL) {
        if ([aSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
            NSLog(@"generating fingerprint for song %@",aSong);
            [aSong setFingerPrintStatus:kFingerPrintStatusRequested];
            [songFingerPrinter requestFingerPrintForSong:aSong];
            interval = 3;
        }
    } else {
        
        // Fetch any sweet spots for this song if it doesn't have a start time or it has been a long time since the last sweet spot server update.
        if ([[aSong startTime] doubleValue] == -1) {
            [self fetchSongSweetSpot:aSong];
        }

    }
    
    // Start a new timer with the next song.
    idleTimeFingerprinterTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                  target:self
                                                                selector:@selector(idleTimeRequestFingerprint:)
                                                                userInfo:@{@"previousSongID" : [NSNumber numberWithInteger:aSongID+1]}
                                                                 repeats:YES];

}


- (void)idleTimeEnds {
//    NSLog(@"song pool idle end");
    
    // Stop the fingerprinter.
    [idleTimeFingerprinterTimer invalidate];
}


//- (NSManagedObjectModel *)managedObjectModel {
- (void)initSongUserDataManagedObjectModel {
    // Create the managed model.
    songUserDataManagedObjectModel = [[NSManagedObjectModel alloc] init];
    // Add the songUserData entity to the managed model.
    [songUserDataManagedObjectModel setEntities:@[songUserDataEntityDescription]];
    
    // Define and add a localization directory for the entities.
    NSDictionary *localizationDictionary = @{
                                             @"Property/songURL/Entity/TGSongUserData": @"song URL",
                                             @"Property/songFingerPrint/Entity/TGSongUserData": @"song finger print",
                                             @"Property/songUUID/Entity/TGSongUserData": @"song UUID",
                                             @"Property/songUserSweetSpot/Entity/TGSongUserData": @"song Sweet Spot",
                                             @"Property/songSweetSpots/Entity/TGSongUserData": @"song Sweet Spots",
                                             @"ErrorString/Song URL missing.": @"The song URL is missing."};
    
    [songUserDataManagedObjectModel setLocalizationDictionary:localizationDictionary];
}


- (void)initSongPoolPersistentStoreCoordinator {
    // We only need one NSPersistentStoreCoordinator per program.
    songPoolDataCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:songUserDataManagedObjectModel];
    NSString *STORE_TYPE = NSSQLiteStoreType;
    NSString *STORE_FILENAME = @"TGSongUserData.sqlite";
    
    NSError *error;
    
    NSURL *url = [[self applicationSongUserDataDirectory] URLByAppendingPathComponent:STORE_FILENAME];
    
    NSPersistentStore *newStore = [songPoolDataCoordinator addPersistentStoreWithType:STORE_TYPE
                                                                        configuration:nil
                                                                                  URL:url
                                                                              options:nil
                                                                                error:&error];
    
    if (newStore == nil) {
        NSLog(@"Store Configuration Failed.\n%@",([error localizedDescription] != nil) ?
              [error localizedDescription] : @"Unknown Error");
    }
}


- (void)initSongUserDataEntityDescription {
    songUserDataEntityDescription = [[NSEntityDescription alloc] init];
    [songUserDataEntityDescription setName:@"TGSongUserData"];
    [songUserDataEntityDescription setManagedObjectClassName:@"TGSongUserData"];
    
//    NSLog(@"The songUserData is %@\n",songUserDataEntityDescription);
    // Define attributes for the user data.
    NSAttributeDescription *songURL = [[NSAttributeDescription alloc] init];
    [songURL setName:@"songURL"];
    [songURL setAttributeType:NSStringAttributeType];
    [songURL setOptional:NO];

    NSAttributeDescription *songFingerPrint = [[NSAttributeDescription alloc] init];
    [songFingerPrint setName:@"songFingerPrint"];
    [songFingerPrint setAttributeType:NSStringAttributeType];
    [songFingerPrint setOptional:YES];
    
    NSAttributeDescription *songUUID = [[NSAttributeDescription alloc] init];
    [songUUID setName:@"songUUID"];
    [songUUID setAttributeType:NSStringAttributeType];
    [songUUID setOptional:YES];
    
    NSAttributeDescription *songUserSweetSpot = [[NSAttributeDescription alloc] init];
    [songUserSweetSpot setName:@"songUserSweetSpot"];
    [songUserSweetSpot setAttributeType:NSFloatAttributeType];
    [songUserSweetSpot setOptional:YES];

    NSAttributeDescription *songSweetSpots = [[NSAttributeDescription alloc] init];
    [songSweetSpots setName:@"songSweetSpots"];
    [songSweetSpots setAttributeType:NSBinaryDataAttributeType];
    [songSweetSpots setOptional:YES];

    // Define the validation predicate and the predicate failure warning.
    NSPredicate *validationPredicate = [NSPredicate predicateWithFormat:@"length > 0"];
    NSString *validationWarning = @"Song URL missing.";
    // Set the validation predicate for the songAssetURL attribute.
    [songURL setValidationPredicates:@[validationPredicate] withValidationWarnings:@[validationWarning]];
    
    // Add the properties to the entity.
    [songUserDataEntityDescription setProperties:@[songURL, songFingerPrint, songUUID, songUserSweetSpot, songSweetSpots]];
}


- (NSURL *)applicationSongUserDataDirectory {
    
    static NSURL *songUserDataDirectory = nil;
    
    if (songUserDataDirectory == nil) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *error;
        NSURL *libraryURL = [fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        
        if (libraryURL == nil) {
            NSLog(@"Could not access the Library directory\n%@",[error localizedDescription]);
        }
        else {
            songUserDataDirectory = [libraryURL URLByAppendingPathComponent:@"ProjectX"];
            songUserDataDirectory = [songUserDataDirectory URLByAppendingPathComponent:@"songUserData"];
            
            NSDictionary *properties = [songUserDataDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
            
            if (properties == nil) {
                if (![fileManager createDirectoryAtURL:songUserDataDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSLog(@"Could not create directory %@\n%@",[songUserDataDirectory path], [error localizedDescription]);
                    songUserDataDirectory = nil;
                }
            }
        }
    }
    
    return songUserDataDirectory;
}


- (NSManagedObjectContext *)managedObjectContext {
    
    if (songPoolManagedContext == nil) {
        songPoolManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [songPoolManagedContext setPersistentStoreCoordinator:songPoolDataCoordinator];
    }
    
    return songPoolManagedContext;
}


- (BOOL)validateURL:(NSURL *)anURL {
    
    // for now just say yes
    return YES;
}

// Traverse the passed in URL, find all music files and load their URLs into a dictionary.
// returns true if the given url is valid and, if so, will initiate the loading of songs.
- (BOOL)loadFromURL:(NSURL *)anURL {


    // init status.
    allURLsRequested = NO;
    allURLsLoaded = NO;
    errorLoadingSongURLs = NO;
    __block int requestedOps = 0;
    __block int completedOps = 0;
    opQueue = [[NSOperationQueue alloc] init];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:anURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error getting the directory. %@",error);
                                             // Return yes to continue traversing.
                                             return YES;
                                         }];
//    NSTimeInterval timerStart = [NSDate timeIntervalSinceReferenceDate];

    // At this point, to avoid blocking with a beach ball on big resources/slow access, we drop this part into a concurrent queue.
    NSOperationQueue *topQueue = [[NSOperationQueue alloc] init];
    NSBlockOperation *topOp = [NSBlockOperation blockOperationWithBlock:^{
        
        for (NSURL *url in enumerator) {
            
            // Increment counter to track number of requested load operations.
            requestedOps++;
            
            NSBlockOperation *theOp = [NSBlockOperation blockOperationWithBlock:^{
                NSError *error;
                NSNumber *isDirectory = nil;

                if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                    // handle error
                    NSLog(@"An error %@ occurred in the enumeration.",error);
                    errorLoadingSongURLs = YES;
    // TEO: handle error by making another delegate method that signals failure.
                    return;
                }
                else if (! [isDirectory boolValue]) {
                    // No error and it’s not a directory; do something with the file
                    
                    // Check the file extension and deal only with audio files.
                    CFStringRef fileExtension = (__bridge CFStringRef) [url pathExtension];
                    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
                    
                    if (UTTypeConformsTo(fileUTI, kUTTypeAudio))
                    {
                        // Since this can occur asynchronously, atomically increment the number of audio urls.
                        int curURLNum = OSAtomicIncrement32(&(loadedURLs))-1;

                        // Create a song object with the given url. This does not start loading it from disk.
                        TGSong *newSong = [[TGSong alloc] initWithURL:url];
                        
                        // Set the song pool to be a song's delegate.
                        [newSong setDelegate:self];
                        
                        // The song id is simply its number in the loading sequence. (for now)
                        [newSong setSongID:curURLNum];
                        
                        dispatch_async(serialDataLoad, ^{
                            
                            // Try and fetch (by URL) the song's metadata from the core data store.
                            [self loadMetadataIntoSong:newSong];
                            
                            // Add the song to the songpool.
                            [songPoolDictionary setObject:newSong forKey:[NSNumber numberWithInt:curURLNum]];
                                                        
                        });
                        
                        // Inform the delegate that another song object has been loaded. This causes a cell in the song matrix to be added.
                        if ((_delegate != Nil) && [_delegate respondsToSelector:@selector(songPoolDidLoadSongURLWithID:)]) {
                            [_delegate songPoolDidLoadSongURLWithID:curURLNum];
                        }
                    }
                }
            }];
            
            [theOp setCompletionBlock:^{
                
                // Atomically increment the counter to track completed operations.
                OSAtomicIncrement32(&completedOps);
                
                // If we're done requesting new urls and
                // the number of completed operations is the same as the requested operations then
                // signal that we're done loading and signal our delegate (the songgridcontroller) that we're all done.
                if (allURLsRequested) {
                    if ( completedOps == requestedOps) {
                        // At this point we know how many songs to display.
                        NSLog(@"Done. Found %d urls",loadedURLs);
                        
                        // Inform the delegate that we've loaded the all the URLs.
                        if ([_delegate respondsToSelector:@selector(songPoolDidLoadAllURLs:)]) {
                                [_delegate songPoolDidLoadAllURLs:loadedURLs];
                        }
                        allURLsLoaded = YES;
                        
                        
                        // At this point we start assigning unmapped songs to a position in the grid.
                    }
                }
            }];
            
            [opQueue addOperation:theOp];
        }
    }];

    [topOp setCompletionBlock:^{
        allURLsRequested = YES;
    }];

    [topQueue addOperation:topOp];
    
    return YES;
}


// This method will attempt to find the image for the song and, if found, will pass it to the given imageHandler block.
- (void)requestImageForSongID:(NSInteger)songID withHandler:(void (^)(NSImage *))imageHandler {
    
    NSLog(@"request image!");
    // First we should check if the song has an image stashed in the songpool local/temporary store.
    TGSong * theSong = [self songForID:songID];
    NSInteger artID = [theSong artID];
    if (artID >= 0) {
        NSImage *songArt = [_artArray objectAtIndex:artID];
        NSLog(@"already had image!");
        imageHandler(songArt);
        return;
    }
    
    // If nothing was found, try asking the song directly.
    // Request a cover image from the song passing in a handler block we want executed on resolution.
    [theSong requestCoverImageWithHandler:^(NSImage *tmpImage) {
        
        if (tmpImage != nil) {
            // Store the image in the local store so we won't have to re-fetch it from the file.
            [_artArray addObject:tmpImage];
            
            // Add the art index to the song.
            [theSong setArtID:[_artArray count]-1];
            
            // Call the image handler with the image we recived from the song.
            imageHandler(tmpImage);
            return;
        } else {
            // Search strategies:
            // 1. Search songs from same album. If they have an image, use that.
            // * currently the songs are not stored or indexed according to album or any other property.
            // 2. Search directory for images.
            //  If there pick one named same as track.
            //  If there pick one named same as filename.
            //  If there pick one named same as album.
            //  Else pick any.
            // 3. Look up track then album then artist name online.

            // Get the song's URL
            NSURL *theURL = [theSong songURL];
            
            tmpImage = [self searchForCoverImageAtURL:theURL];
            if (tmpImage != nil) {
                NSLog(@"found song image");
                imageHandler(tmpImage);
                return;
            }
            
            
        }
        
        // No image was found by any of the methods so we call the given image handler with nil;
        imageHandler(nil);
    }];
}

- (NSImage *)searchForCoverImageAtURL:(NSURL *)theURL {
    
    // Extract the containing directory by removing the trailing file name.
    NSString *theDirectory = [[theURL absoluteString] stringByDeletingLastPathComponent];
    NSString *theTrackName = [[[theURL absoluteString] lastPathComponent] stringByDeletingPathExtension];
    NSURL *jpgURL = [NSURL URLWithString:[theDirectory stringByAppendingPathComponent:[theTrackName stringByAppendingPathExtension:@"jpg"]]];
    NSLog(@"looking for %@",[jpgURL absoluteString]);
    
    NSImage *theImage = [[NSImage alloc] initWithContentsOfURL:jpgURL];;
    if (theImage == nil) {
        return nil;
    }
    
//    NSFileManager *fileManager = [[NSFileManager alloc] init];
//    
//    NSArray *keys = [NSArray arrayWithObject:NSURLIs];
//    
//    NSDirectoryEnumerator *enumerator = [fileManager
//                                         enumeratorAtURL:anURL
//                                         includingPropertiesForKeys:keys
//                                         options:0
//                                         errorHandler:^(NSURL *url, NSError *error) {
//                                             // Handle the error.
//                                             // Return YES if the enumeration should continue after the error.
//                                             NSLog(@"Error getting the directory. %@",error);
//                                             // Return yes to continue traversing.
//                                             return YES;
//                                         }];
    
        
    return theImage;
}

- (void)requestEmbeddedMetadataForSong:(NSInteger) songID {
    dispatch_async(serialDataLoad, ^{
        TGSong *theSong = [self songForID:songID];
        NSAssert(theSong, @"the song is nil.");
        if (theSong != nil) {

            [theSong loadSongMetadata];
            if ([_delegate respondsToSelector:@selector(songPoolDidLoadDataForSongID:)])
                [_delegate songPoolDidLoadDataForSongID:songID];
        }

    });
    
    
}


- (NSInteger)songDurationForSongID:(NSInteger)songID {
    return CMTimeGetSeconds([[self songForID:songID] songDuration]);
}

- (NSURL *)songURLForSongID:(NSInteger)songID {
    return [[self songForID:songID] songURL];
}

- (NSDictionary *)songDataForSongID:(NSInteger)songID {
    return [[self songForID:songID] songData];
}

- (void)offsetSweetSpotForSongID:(NSInteger)songID bySeconds:(Float64)offsetInSeconds {
    TGSong *song = [self songForID:songID];
    if (song != nil) {
        Float64 currentPlayTimeInSeconds = [song getCurrentPlayTime];
        NSLog(@"current playtime in seconds %f and offset in seconds %f",currentPlayTimeInSeconds,offsetInSeconds);
        // Convert the current play time + offset to centiseconds.
        NSNumber *newPlayTime = [NSNumber numberWithDouble:currentPlayTimeInSeconds + offsetInSeconds];
        if (newPlayTime >= 0) {
            [self setSweetSpotForSong:song atTime:newPlayTime];
        }
    }
    
}


- (void)setSweetSpotForSong:(TGSong *)theSong atTime:(NSNumber *)positionInSeconds {
    
            [theSong setStartTime:positionInSeconds];
            [theSong setCurrentPlayTime:positionInSeconds];
            [songsWithChangesToSave addObject:theSong];
}


- (void)sweetSpotToServerForSong:(TGSong *)aSong {
    double sweetSpot = [[aSong startTime] doubleValue] ;
    NSString * songUUID = [aSong songUUIDString];
    
    NSURL *requestIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://localhost:8080/submit?songUUID=%s&songSweetSpot=%lf",[songUUID UTF8String],sweetSpot]];
    NSLog(@"sanity check %@",requestIDURL);
    NSData *requestData = [[NSData alloc] initWithContentsOfURL:requestIDURL];
    
    if (requestData != nil) {
        NSDictionary *requestJSON = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:nil];
        
        // First we check that the return status is ok.
        NSString *status = [requestJSON objectForKey:@"status"];
        //NSLog(@"the status is %@",status);
        
        if ([status isEqualToString:@"ok"]) {
//            id result = [requestJSON objectForKey:@"result"];
//            if ([result isKindOfClass:[NSDictionary class]]) {
//                NSLog(@"the result object is a dictionary.");
//                NSDictionary *resultDict = result;
//                // The first element is the songUUID which hopefully matches the one we sent to the server.
//                NSString *songUUIDFromServer = [resultDict objectForKey:@"songuuid"];
//                NSLog(@"The song uuid from the server is %@",songUUIDFromServer);
//                // We then expect an array of sweetspots.
//            }
        } else
            NSLog(@"ERROR: The server returned status : %@",status);
    } else
        NSLog(@"No data returned from sweetspot server.");
}

- (void)sweetSpotFromServerForSong:(TGSong *)aSong {

    NSString * songUUID = [aSong songUUIDString];

    NSURL *theIDURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:8080/lookup?songUUID=%s",[songUUID UTF8String]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:theIDURL];
    
    [NSURLConnection sendAsynchronousRequest:request queue:opQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data != nil) {
            NSDictionary *requestJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // First we check that the return status is ok.
            NSString *status = [requestJSON objectForKey:@"status"];
            //NSLog(@"the status is %@",status);
            
            if ([status isEqualToString:@"ok"]) {
                id result = [requestJSON objectForKey:@"result"];
                if ([result isKindOfClass:[NSDictionary class]]) {
//                    NSLog(@"the result object is a dictionary.");
                    NSDictionary *resultDict = result;
                    // The first element is the songUUID which hopefully matches the one we sent to the server.
//                    NSString *songUUIDFromServer = [resultDict objectForKey:@"songuuid"];
//                    NSLog(@"The song uuid from the server is %@",songUUIDFromServer);
//                    
                    // We then expect an array of sweetspots.
                    NSArray *sweetSpotsFromServer = [resultDict objectForKey:@"sweetspots"];
                    if ([sweetSpotsFromServer count] > 0) {
                        [aSong setSongSweetSpots:sweetSpotsFromServer];

//                        for (NSNumber *ss in sweetSpotsFromServer) {
//                            NSLog(@"We've got a sweet spot of %@",ss);
//                        }
                        // TEO: temp set the start time to be the first sweet spot
                        NSNumber *sweetSpot = [sweetSpotsFromServer objectAtIndex:0];
                        [aSong setStartTime:sweetSpot];
                    }
                }
            } else
                NSLog(@"ERROR: The server returned status : %@",status);
        } else
            NSLog(@"NSURLConnection request to sweet spot server returned nil data.");
    }];
}

// This will fetch the song "sweet spot" (if we can't find a local one) from a remote server based on a grouping algorithm.
// If the user has set their own "sweet spot" it overrides the server provided time and the user time is uploaded to the server to increase accuracy.
- (NSNumber *)fetchSongSweetSpot:(TGSong *)song {
    
    // Get the song's start time in seconds.
    NSNumber *startTime = [song startTime];
    
    // Request sweetspots from the sweetspot server if the song does not have a start time, has a uuid and has not exceeded its alotted queries.
    if (([[song startTime] doubleValue] == -1) &&
        ([song songUUIDString] != nil) &&
        (song.SSCheckCountdown-- == 0)) {
        
        // Reset the counter.
        song.SSCheckCountdown = (NSUInteger)kSSCheckCounterSize;
        
#pragma TEO finish off the timestamping of server requests instead of using the countdown.
        NSDate *now = [NSDate date];
        [now timeIntervalSinceDate:now];
        [self sweetSpotFromServerForSong:song];
    }
    
    return startTime;
}


-(NSNumber *)requestedPlayheadPosition {
    return requestedPlayheadPosition;
}


// This method sets the playhead position of the currently playing song to the requested position and
// also sets a sweet spot for the song which gets stored on next save.

- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition {
    requestedPlayheadPosition = newPosition;
    [self setSweetSpotForSong:[self songForID:[self lastRequestedSongID]] atTime:newPosition];
}


// TEO: Convenience method. May not need it for long.
- (float)fetchSweetSpotForSongID:(NSInteger)songID {
    TGSong *song = [self songForID:songID];
    return [[self fetchSongSweetSpot:song] floatValue];
}


// updateCache:
// The song pool doesn't know about the layout of the song grid so it cannot decide which songs to cache.
// Therefore it is passed an array of ids that need caching.
// De-cache those songs in the cache that are no longer needed and initiate the caching of the new songs.
// TEO: consider adding an age/counter to the cached songs such that they don't get unloaded immediately (temporal caching).
- (void)updateCache:(NSArray *)songIDArray {
    for (NSNumber *songNumber in songIDArray) {
        NSInteger songID = [songNumber integerValue];
        TGSong * aSong = [self songForID:songID];
        if (aSong != nil) {
            
            NSLog(@"loadTrackData called from updateCache");
            [aSong loadTrackData];
        } else
            NSLog(@"requested song %lu not there",songID);
    }
}

- (NSInteger)lastRequestedSongID {
    return [lastRequestedSong songID];
}

- (TGSong *)currentlyPlayingSong {
    return currentlyPlayingSong;
}

-(TGSong *)songForID:(NSInteger)songID {
    return [songPoolDictionary objectForKey:[NSNumber numberWithInteger:songID]];
}

// Delegate methods:

// TGfingerPrinterDelegate methods.
// Called by the finger printer when it has finished fingerprinting a song.
- (void)fingerprintReady:(NSString *)fingerPrint ForSong:(TGSong *)song {
    //NSLog(@"fingerprintReady received for song %@",[song songURL]);
    
    // At this point we should check if the fingerprint resulted in a songUUID.
    // If it did not we keep the finger print so we don't have to re-generate it, otherwise we can delete the it.
    if ([song songUUIDString] == nil) {
        NSLog(@"No UUID found, keeping fingerprint.");
        [song setFingerprint:fingerPrint];
    }
    else {
        // The song has a UUID, so there's no need to keep the fingerprint.
        [song setFingerprint:nil];
    }
    
    [song setFingerPrintStatus:kFingerPrintStatusDone];
    
    // Check the song user data DB to see if we have song data for the UUID/fingerprint.
    // If found, load the data into the song.
    if (![self loadMetadataIntoSong:song]) {
        // If not found in the user data file, add the song to a songsWithChangesToSave dictionary so any changes to it are stored.
        [songsWithChangesToSave addObject:song];
    }    
}

- (NSArray *)floatArrayFromFloatString:(NSString *)floatString {
    // First we split the floatString into individual float strings.
    NSArray *splitString = [floatString componentsSeparatedByString:@","];
    // Then we turn each into a float and drop it into the final array.
    NSMutableArray *floatArray = [[NSMutableArray alloc] initWithCapacity:[splitString count]];
    for (NSString *aFloatString in splitString) {
        NSNumber *floatNumber = [NSNumber numberWithFloat:[aFloatString floatValue]];
        [floatArray addObject:floatNumber];
    }
    
    return floatArray;
}

- (NSString *)floatStringFromFloatArray:(NSArray *)floatArray {
    return [[floatArray valueForKey:@"description"] componentsJoinedByString:@","];
}

// TSGSongDelegate methods.
- (void)songDidFinishPlayback:(TGSong *)song {
    // Pass this on to the delegate (which should be the controller).
    NSLog(@"song %lu did finish playback. The last requested song is %lu",(unsigned long)[song songID],[lastRequestedSong songID]);
    if ([[self delegate] respondsToSelector:@selector(songPoolDidFinishPlayingSong:)]) {
        [[self delegate] songPoolDidFinishPlayingSong:[song songID]];
    }
}


- (void)songDidLoadEmbeddedMetadata:(TGSong *)song {
    
    if ([[self delegate] respondsToSelector:@selector(songPoolDidLoadDataForSongID:)]) {
        [[self delegate] songPoolDidLoadDataForSongID:[song songID]];
    }
    
}

// Delegate method that allows a song to set the songpool's playhead position tracker variable.
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition {
    [self setValue:playheadPosition forKey:@"playheadPos"];
}

// songReadyForPlayback is called (async'ly) by the song once it is fully loaded.
- (void)songReadyForPlayback:(TGSong *)song {
    
    // If the song has a undefined (-1) start time, set it to whatever fetchSongSweetSpot returns.
    if ([[song startTime] doubleValue] == -1) {
        [song setStartTime:[self fetchSongSweetSpot:song]];
    }
    
    // Make sure the last request for playback is put on a serial queue so it always is the last song left playing.
    if (song == lastRequestedSong) {
        dispatch_async(playbackQueue, ^{
            NSLog(@"putting song %lu on the playbackQueue",(unsigned long)[song songID]);
            [self playbackSong:song];
        });
    } else {
        
//        NSLog(@"songReadyForPlayback overridden. Song is %lu and lastRequestedSong is %lu",(unsigned long)[song songID],(unsigned long)[lastRequestedSong songID]);
    }
}


- (void)preloadSongArray:(NSArray *)songArray {
    NSLog(@"preloading");
    for (NSNumber * songID in songArray) {
        TGSong *aSong = [self songForID:[songID integerValue]];
        if (aSong == NULL) {
            NSLog(@"Nope, the requested ID %@ is not in the song pool.",songID);
            return;
        }
        [aSong loadTrackData];
        [self requestEmbeddedMetadataForSong:[songID integerValue]];
    }
}

//- (void)requestSongPlayback:(NSInteger)songID {
- (void)requestSongPlayback:(NSInteger)songID withStartTimeInSeconds:(NSNumber *)time {
    
    TGSong *aSong = [self songForID:songID];
    if (aSong == NULL) {
        NSLog(@"Nope, the requested ID %lu is not in the song pool.",songID);
        return;
    }
    
    lastRequestedSong = aSong;
    //[aSong setStartTime:[NSNumber numberWithInteger:time]];
    [aSong setRequestedSongStartTime:CMTimeMakeWithSeconds([time doubleValue], 1)];

    // Since loadTrackData can return on a different thread before reaching the next instruction we need to call the loadSongMetadata before it.
    // This skips (but is blocking) the regular serial queue that is loading song metadata to load the metadata for the song the user is about to play.
// Now called in requestEmbeddedMetaData.
//    [aSong loadSongMetadata];
    
    NSLog(@"loadTrackData called from requestSongPlayback");
    // Asynch'ly start loading the track data for aSong. songReadyForPlayback will be called back when the song is good to go.
    [aSong loadTrackData];
}


- (void)setPlayheadPos:(NSNumber *)newPos {
    playheadPos = newPos;
}


- (NSNumber *)playheadPos {
    return playheadPos;
}


- (void)playbackSong:(TGSong *)nextSong {
    
    // Between checking and stopping another thread can modify the currentlyPlayingSong thus causing the song to not be stopped.
    if (currentlyPlayingSong != nextSong) {
        [currentlyPlayingSong playStop];
    }
    
    if (currentlyPlayingSong == nextSong) {
        NSLog(@"currently playing is the same as next song");
        return;
    }
    
    if ([nextSong playStart]) {
        currentlyPlayingSong = nextSong;
        
        NSNumber *theSongDuration = [NSNumber numberWithDouble:[currentlyPlayingSong getDuration]];
        [self setValue:theSongDuration forKey:@"currentSongDuration"];
        
        // Song fingerprints are generated and UUID fetched during idle time in the background.
        // However, if the song about to be played hasn't got a UUID or fingerprint, an async request will be initiated here.
        if ([nextSong songUUIDString] == NULL) {
            if ([nextSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
//                NSLog(@"generating fingerprint for song %@",nextSong);
                [nextSong setFingerPrintStatus:kFingerPrintStatusRequested];
                [songFingerPrinter requestFingerPrintForSong:nextSong];
            }
        }

        // Inform the delegate that we've started playing the song.
        if ([_delegate respondsToSelector:@selector(songPoolDidStartPlayingSong:)]) {
            [_delegate songPoolDidStartPlayingSong:[nextSong songID]];
        }
        
        // Set the requested playheadposition tracker to the song's start time in a KVC compliant fashion.
        [self setRequestedPlayheadPosition:[nextSong startTime]];
//        [self setValue:[nextSong startTime] forKey:@"requestedPlayheadPosition"];
        
    }

}

// Go through all songs and store those who have had data added to them.
// This includes UUID or a user selected sweet spot.
- (void)storeSongData {
    NSLog(@"The songs to save are these: %@",songsWithChangesToSave);
    // Make managed objects of each of these songs. Can we check if they already are store in there?
    //if (not already in there) {
    //[self fetchDataFromLocalStore];
    
    NSEntityDescription *songUserDataEntity = [[songUserDataManagedObjectModel entitiesByName] objectForKey:@"TGSongUserData"];
    // Before adding a new entry we check if the song already exists in the following stages:
    // 1) Check store for a URL match. If none is found...
    // 2)   Check store for a UUID match (if the song has one). If none is found...
    // 3)       Check store for a fingerprint match (if the song doesn't have one, generate it). If none is found...
    // 4)           If none is found in any of the preceding steps; make a new TGSongUserData, fill it and store it.
    // 5) If found in any of the preceding steps; update URL, SS and store.
    NSFetchRequest *songUserDataFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
    NSError *error = nil;
    NSManagedObjectContext *aManagedObjectContext = [self managedObjectContext];
    // Re-fetch the data, otherwise the fetchedArray is not up to date...
    fetchedArray = [aManagedObjectContext executeFetchRequest:songUserDataFetchRequest error:&error];


    if (fetchedArray == nil) {
        NSLog(@"ERROR in storeSongData. FetchedArray is nil.");
        return;
    }
    // Using the block approach as it is faster (according to Darthenius on Stack Overflow).
    //for (id key in songsWithChangesToSave) {
    //[songsWithChangesToSave enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

    // Copy the set to avoid mutation (by other threads) during enumeration.
    NSSet *songsWithChangesToSaveCopy = [songsWithChangesToSave copy];

    // Go through all songs to save and either modify an existing TGSongUserData or create a new one.
    for (TGSong *saveSong in songsWithChangesToSaveCopy) {
        
        TGSongUserData *songUserData = nil;
        
        for (TGSongUserData *sud in fetchedArray) {
            //NSLog(@"comparing %@ and %@",sud.songURL, saveSong.songURL);
            if (saveSong.songURL && sud.songURL && [sud.songURL isEqualToString:[saveSong.songURL absoluteString]]) {
                //NSLog(@"Found URL Match!");
                songUserData = sud;
            }
            else if (saveSong.fingerprint && sud.songFingerPrint && [sud.songFingerPrint isEqualToString:saveSong.fingerprint])
            {
                // We found a UUID match after failing a URL match, so we must update the URL and store.
                //NSLog(@"Found FingerPrint match");
                songUserData = sud;
            }
            else if (saveSong.songUUIDString && sud.songUUID && [sud.songUUID isEqualToString:saveSong.songUUIDString])
            {
                // We found a UUID match after failing a URL match, so we must update the URL and store.
                //NSLog(@"Found UUID match");
                songUserData = sud;
            }
        }

        if (songUserData == nil) {
            NSLog(@"Nothing found in the store. Making new entry.");
            // Nothing found. Generate a new entry.
            songUserData = [[TGSongUserData alloc] initWithEntity:songUserDataEntity insertIntoManagedObjectContext:aManagedObjectContext];
        }
        
        [songUserData setSongURL:[[saveSong songURL] absoluteString]];
        [songUserData setSongFingerPrint:[saveSong fingerprint]];
        [songUserData setSongUUID:[saveSong songUUIDString]];
        [songUserData setSongUserSweetSpot:CMTimeGetSeconds([saveSong songStartTime])];
        
        // Make an archive of the song's sweet spots array.
        NSData *theSweetSpots = [NSKeyedArchiver archivedDataWithRootObject:[saveSong songSweetSpots]];
        [songUserData setSongSweetSpots:theSweetSpots];
        
        // If the user has set their own sweet spot, upload it to the sweet spot server.
        if (([saveSong songUUIDString] != nil) && (CMTimeGetSeconds([saveSong songStartTime]) != -1)) {
            [self sweetSpotToServerForSong:saveSong];
        }
    }
    
    NSTimeInterval timerStart = [NSDate timeIntervalSinceReferenceDate];
    if (![aManagedObjectContext save:&error]) {
        NSLog(@"Error while saving\n%@",
              ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error.");
        // On error go through them and extract the URL from the failed attempt, find the object that matches it and add it to the list of failed saves.
        NSDictionary * errorDict = [error userInfo];
        if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
            // We keep the URLS of the failed saves in a set.
            NSMutableSet *errorURLs = [[NSMutableSet alloc] init];
            TGSongUserData *errorSongUserData = nil;
            
            if ([error code] == NSValidationMultipleErrorsError) {
                // Deal with each.
                NSArray *errorArray = [errorDict objectForKey:NSDetailedErrorsKey];
                for (NSError *anError in errorArray) {
                    errorSongUserData = [[anError userInfo] objectForKey:@"NSValidationErrorObject"];
                    [errorURLs addObject:[errorSongUserData songURL]];
                }
            }
            else {
                errorSongUserData = [[error userInfo] objectForKey:@"NSValidationErrorObject"];
                [errorURLs addObject:[errorSongUserData songURL]];
            }
            
            // Go through the errorURLs, find the matching song in songsWithChangesToSave and add it to the songsWithSaveError.
            for (NSString *errorURL in errorURLs) {
                // Find the song that matches the URL string and add it to the songs with save errors.
                for (TGSong *aSong in songsWithChangesToSaveCopy) {
                    if ([[aSong.songURL absoluteString] isEqualToString:errorURL]) {
                        [songsWithSaveError addObject:aSong];
                    }
                }
            }
        }
        NSLog(@"The songsWithSaveError are %@",songsWithSaveError);
    }
    
    // Remove the items in the songsWithChangesToSaveCopy from songsWithChangesToSave (as it may have had some items added in the interrim)
    [songsWithChangesToSave minusSet:songsWithChangesToSaveCopy];
    

    NSLog(@"The save took %f seconds.",[NSDate timeIntervalSinceReferenceDate] - timerStart);
}

- (void)fetchMetadataFromLocalStore {
    NSFetchRequest *songUserDataFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
    NSError *error = nil;
    NSManagedObjectContext *aManagedObjectContext = [self managedObjectContext];
    fetchedArray = [aManagedObjectContext executeFetchRequest:songUserDataFetchRequest error:&error];
    if (fetchedArray == nil) {
        NSLog(@"Error while fetching.\n%@",
              ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
    }
    NSLog(@"Successfully fetched data from local store.");
}

// See if a given song has metadata available in the array fetched from the core data store.
// If it does, copy it into the song's object.
// Note that the songUserSweetSpot is the currently selected sweet spot and the songSweetSpots is an array of all sweet spots.
// The search order is:
//      1) look for a url match. All songs have an url, though it may not have been saved to the core data store.
//      2) look for a uuid match. The uuid is obtained by sending a fingerprint to a server, so if there is a uuid there's no need to look for a fingerprint.
//      3) look for a fingerprint. A fingerprint is generated when possible and stored until a uuid can be obtained.
- (BOOL)loadMetadataIntoSong:(TGSong *)aSong {

    if (fetchedArray == nil)
        return NO;
    
    for (TGSongUserData *sud in fetchedArray) {
        if ([sud.songURL isEqualToString:[aSong.songURL absoluteString]]) {
            
            [aSong setStartTime:[NSNumber numberWithFloat:sud.songUserSweetSpot]];
            if (sud.songFingerPrint != nil) {
                
                [aSong setFingerprint:sud.songFingerPrint];
                [aSong setFingerPrintStatus:kFingerPrintStatusDone];
            }
            
            [aSong setSongUUIDString:sud.songUUID];
            
            // The songSweetSpots is an array of other sweet spots for the song, either fetched from the sweet spot server or previously set by the user.
            if (sud.songSweetSpots != nil) {
                [aSong setSongSweetSpots:[NSKeyedUnarchiver unarchiveObjectWithData:sud.songSweetSpots]];
            }
            
            return YES;
        }
        else if (aSong.songUUIDString && sud.songUUID && [sud.songUUID isEqualToString:aSong.songUUIDString]) {
            
            [aSong setStartTime:[NSNumber numberWithFloat:sud.songUserSweetSpot]];
            
            // Update the metadata of the core data version of this song.
            
            // Set the core data song url to what we found it to actually be.
            [sud setSongURL:[[aSong songURL] absoluteString]];
            
            // If we have a UUID there's no need to keep the fingerprint.
            [sud setSongFingerPrint:nil];

            // Instead of saving it immediately, add it to the songs to save.
            [songsWithChangesToSave addObject:aSong];
            if (sud.songSweetSpots != nil) {
                [aSong setSongSweetSpots:[NSKeyedUnarchiver unarchiveObjectWithData:sud.songSweetSpots]];
            }

            return YES;
        }
        else if (aSong.fingerprint && sud.songFingerPrint && [sud.songFingerPrint isEqualToString:aSong.fingerprint]) {
            //NSLog(@"Found FingerPrint match. Loading song user sweet spot and saving URL back out.");
            
            [aSong setStartTime:[NSNumber numberWithFloat:sud.songUserSweetSpot]];
            
            [sud setSongURL:[[aSong songURL] absoluteString]];
            if (aSong.songUUIDString != nil) {
                [sud setSongUUID:aSong.songUUIDString];
            }
            
            // Instead of saving it immediately, add it to the songs to save.
            [songsWithChangesToSave addObject:aSong];

            if (sud.songSweetSpots != nil) {
                [aSong setSongSweetSpots:[NSKeyedUnarchiver unarchiveObjectWithData:sud.songSweetSpots]];
            }

            return YES;
        }
    }

    return NO;
}

//- (void)fetchSongData {
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"songURL" ascending:YES];
//    [request setSortDescriptors:@[sortDescriptor]];
//    
//    NSError *error = nil;
//    NSArray *fetchedArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
//    if (fetchedArray == nil) {
//        NSLog(@"Error while fetching.\n%@",
//              ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
//    }
//
//    // Traverse the fetched array and look for each element's url in the songPoolDictionary.
//    // Actually it is probably going to happen as each song is created and added to the songPoolDictionary...
//    if ([[fetchedArray valueForKey:@"songUUID"] containsObject:@"ddb1d137-3491-451f-8ecd-c459ee5827a2"]) {
//        NSLog(@"Found dupe!");
//    }
////    for ( TGSongUserData * asud in fetchedArray) {
////        NSLog(@"The song URL is %@",asud.songURL);
////        NSLog(@"The song UUID is %@",asud.songUUID);
////        NSLog(@"And the sweet spot is %f",asud.songUserSweetSpot);
////    }
//}


- (NSString *)getSongGenreStringForSongID:(NSInteger)songID {
//    TGSong *tmpSong = [songPoolDictionary objectForKey:[NSNumber numberWithInteger:songID]];
    TGSong *tmpSong = [self songForID:songID];
    if (tmpSong) {
        return [[tmpSong songData] objectForKey:@"Genre"];
    } else
        return NULL;
}

-(NSDictionary *)getSongDisplayStrings:(NSInteger)songID {
//    TGSong *song = [songPoolDictionary objectForKey:[NSNumber numberWithInteger:songID]];
    TGSong *song = [self songForID:songID];
    return [song songData];
}


- (dispatch_queue_t)serialQueue {
    return playbackQueue;
}

@end
