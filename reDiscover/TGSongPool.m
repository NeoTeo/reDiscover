//
//  TGSongPool.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "TGSongPool.h"
#import "TGSong.h"
#import "TGSongGridViewController.h"
#import "TGMainViewController.h"

#import "TGFingerPrinter.h"

#import "TGSongUserData.h"
#import "TEOSongData.h"

#import "rediscover-swift.h"



//@interface SongID : NSObject <SongIDProtocol>
//+ (SongID *)initWithString:(NSString *)theString;
//@end
@implementation SongID
+ (instancetype)initWithString:(NSString *)theString {
    SongID* theID = [[SongID alloc] init];
    theID.idValue = theString.hash;
    return theID;
}

- (BOOL)isEqualToSongID:(SongID *)anID {
    if (anID.idValue == self.idValue) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[SongID class]]) {
        return NO;
    }
    
    return [self isEqualToSongID:(SongID*)object];
}

- (NSUInteger)hash {
    return self.idValue;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    SongID* copy = [[self class] allocWithZone:zone];
    if (copy) {
        copy.idValue = self.idValue;
    }
    return copy;
}

@end


// The private interface declaration overrides the public one to declare conformity to the Delegate protocols.
//@interface TGSongPool () <TGSongDelegate,TGFingerPrinterDelegate,SongPoolAccessProtocol,TGPlaylistViewControllerDelegate>
//@end
@interface TGSongPool () <TGSongDelegate,TGFingerPrinterDelegate,SongPoolAccessProtocol>
@end

// constant definitions
static int const kSSCheckCounterSize = 10;
//#define kSSCheckCounterSize 10


@implementation TGSongPool

- (id)initWithURL:(NSURL*) theURL {
    if( [self validateURL:theURL]) {
        return [self init];
    } else {
        return nil;
    }
}

- (BOOL)validateURL:(NSURL *)anURL {
    
    // for now just say yes
    return YES;
}

- (id)init {
    self = [super init];
    if (self != NULL) {
        
        requestedPlayheadPosition = [NSNumber numberWithDouble:0];
        songPoolStartCapacity = 25;
        songPoolDictionary = [[NSMutableDictionary alloc] initWithCapacity:songPoolStartCapacity];
        currentlyPlayingSong = NULL;
        
        // Make url queues and make them serial.
        urlLoadingOpQueue = [[NSOperationQueue alloc] init];
        [urlLoadingOpQueue setMaxConcurrentOperationCount:1];
        urlCachingOpQueue = [[NSOperationQueue alloc] init];
        [urlCachingOpQueue setMaxConcurrentOperationCount:1];
        
        playbackQueue = dispatch_queue_create("playback queue", NULL);
        serialDataLoad = dispatch_queue_create("serial data load queue", NULL);
        timelineUpdateQueue = dispatch_queue_create("timeline GUI updater queue", NULL);
        
        
        // Set up session cache of image covers.
        _artArray = [[NSMutableArray alloc] initWithCapacity:100];
        [_artArray addObject:[NSImage imageNamed:@"noCover"]];
        
        // Create and hook up the song fingerprinter.
        songFingerPrinter = [[TGFingerPrinter alloc] init];
        [songFingerPrinter setDelegate:self];

        
        // Core Data initialization.
        {
            // Create the entity description.
            NSEntityDescription *songUserDataEntityDescription = [self createSongUserDataEntityDescription];
            
            // Create the managed object model.
            songUserDataManagedObjectModel = [self createSongUserDataManagedObjectModelWithEntityDescription:songUserDataEntityDescription];
            
            // Create the persistent store coordinator.
            NSPersistentStoreCoordinator * songPoolPersistentStoreCoordinator = [self createSongPoolPersistentStoreCoordinatorWithManagedObjectModel:songUserDataManagedObjectModel];
            
            // Create a managed object context.
            if (songPoolManagedContext == nil) {
                songPoolManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                [songPoolManagedContext setPersistentStoreCoordinator:songPoolPersistentStoreCoordinator];
            }
        }
        
//        songsWithChangesToSave = [[NSMutableSet alloc] init];
//        songsWithSaveError = [[NSMutableSet alloc] init];
     
        self.sharedFileManager = [[NSFileManager alloc] init];
        
        // Get any user metadata from the local Core Data store.
        [self fetchMetadataFromLocalStore];

        // Register to be notified of idle time starting and ending.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeBegins) name:@"TGIdleTimeBegins" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeEnds) name:@"TGIdleTimeEnds" object:nil];
        
        _coverArtWebFetcher = [[CoverArtArchiveWebFetcher alloc] init];
        _coverArtWebFetcher.delegate = self;
        
        // TEOSongData test
        [self setupManagedObjectContext];
        // TEOSongData end

        theSongPlayer = [[SongPlayer alloc] init];
        theSongPlayer.delegate = self;
        
        // Starting off with an empty songID cache.
        songIDCache = [[NSMutableSet alloc] init];
        cacheClearingQueue = dispatch_queue_create("cache clearing q", NULL);
    }
    
    return self;
}


// TEOSongData test set up the Core Data context and store.
- (void)setupManagedObjectContext {
    
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"TEOSong" withExtension:@"momd"];
    NSManagedObjectModel* mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSManagedObjectContext* private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setPersistentStoreCoordinator:psc];
    
    self.TEOmanagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.TEOmanagedObjectContext setParentContext:private];
    [self setPrivateContext:private];
    
    // Since this could potentially take time we dispatch this block async'ly
// Commented out because the caller would call loadFromURL before this block was done.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError* error;
        NSURL* documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
        documentsDirectory = [documentsDirectory URLByAppendingPathComponent:@"reDiscoverdb.sqlite"];
        
        [self.TEOmanagedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                              configuration:nil
                                                                                        URL:documentsDirectory
                                                                                    options:nil error:&error];
        if (error) {
            NSLog(@"Error: %@",error);
        }
        NSLog(@"setupManagedObjectContext done");
        [self initTEOSongDataDictionary];
//    });
}


- (void)initTEOSongDataDictionary {
    
    // First we fetch the data from the store.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TEOSongData"];
    
    // fetch the data asynch'ly.
//    [self.TEOmanagedObjectContext performBlock:^{
    // fetch the data synch'ly
    [self.TEOmanagedObjectContext performBlockAndWait:^{
        NSArray *fetchedArray = nil;
        NSError *error = nil;
        fetchedArray = [self.TEOmanagedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error != nil) {
            NSLog(@"Error while fetching TEOSongData.\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
            return;
        }
        
        // Then traverse the fetched Array and make a dictionary with the url field as the key.
        NSMutableDictionary* tmpDictionary = [[NSMutableDictionary alloc] init];
        
        for (TEOSongData* songData in fetchedArray) {
            [tmpDictionary setObject:songData forKey:songData.urlString];
//            NSLog(@"The song %@ songData selected sweet spot %@",songData.urlString, songData.selectedSweetSpot);
//            NSLog(@"And the sweet spots: %@",songData.sweetSpots);
        }
        
        self.TEOSongDataDictionary = tmpDictionary;
        NSLog(@"initTEOSongDataDictionary done");
    }];
}
// END TEOSongData test


//- (void)idleTimeBegins {
//    NSLog(@"song pool idle start");
//    
//    [idleTimeFingerprinterTimer invalidate];
//    
//    // Start a timer that calls idleTimeRequestFingerprint.
//    idleTimeFingerprinterTimer = [NSTimer scheduledTimerWithTimeInterval:5
//                                                 target:self
//                                               selector:@selector(idleTimeRequestFingerprint:)
//                                                                userInfo:@{@"previousSongID" : [NSNumber numberWithInteger:0]}
//                                                repeats:YES];
//
//}
- (void)idleTimeBegins {
    NSLog(@"song pool idle start");
    
    [idleTimeFingerprinterTimer invalidate];
    
    NSEnumerator* theSongEnumerator = [songPoolDictionary objectEnumerator];
    // Start a timer that calls idleTimeRequestFingerprint.
    idleTimeFingerprinterTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(idleTimeRequestFingerprint:)
                                                                userInfo:@{@"songEnumerator" : theSongEnumerator}
                                                repeats:YES];

}


- (void)idleTimeRequestFingerprint:(NSTimer *)theTimer {
    
    NSEnumerator* theSongEnumerator = [[theTimer userInfo] objectForKey:@"songEnumerator"];
    
    TGSong* aSong = [theSongEnumerator nextObject];
    
    // Stop the fingerprinter timer.
    [idleTimeFingerprinterTimer invalidate];
    
    if (aSong == nil) {
        // We've done all the songs. Return without starting a new timer.
        NSLog(@"No more songs to fingerprint");
        return;
    }

    // Unless a fingerprint is actually requested we set the interval until the next timer to as little as possible.
    NSInteger interval = 0;
    
    if (aSong.TEOData.uuid == NULL) {
        if ([aSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
            NSLog(@"idleTimeRequestFingerprint generating fingerprint for song %@",aSong);
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
                                                                userInfo:@{@"songEnumerator" : theSongEnumerator }
                                                                 repeats:YES];
}


- (void)idleTimeEnds {
//    NSLog(@"song pool idle end");
    
    // Stop the fingerprinter.
    [idleTimeFingerprinterTimer invalidate];
}



//- (NSManagedObjectContext *)managedObjectContext {
//    
//    if (songPoolManagedContext == nil) {
//        songPoolManagedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [songPoolManagedContext setPersistentStoreCoordinator:songPoolDataCoordinator];
//    }
//    
//    return songPoolManagedContext;
//}



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
    
    NSLog(@"loadFromURL running on the main thread? %@",[NSThread mainThread]?@"Yep":@"Nope");
    
//    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
//    NSTimeInterval timerStart = [NSDate timeIntervalSinceReferenceDate];

    // At this point, to avoid blocking with a beach ball on big resources/slow access, we drop this part into a concurrent queue.
    NSOperationQueue *topQueue = [[NSOperationQueue alloc] init];
    NSBlockOperation *topOp = [NSBlockOperation blockOperationWithBlock:^{
        
        // The enumerator does a deep traversal of the given url.
        NSDirectoryEnumerator *enumerator = [self.sharedFileManager
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
        
        for (NSURL *url in enumerator) {
            
            // Increment counter to track number of requested load operations.
            requestedOps++;
            
            // Each block checks a url.
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
                
                if (! [isDirectory boolValue]) {
                    // No error and it’s not a directory; do something with the file
                    
                    // Check the file extension and deal only with audio files.
                    CFStringRef fileExtension = (__bridge CFStringRef) [url pathExtension];
                    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
                    
                    if (UTTypeConformsTo(fileUTI, kUTTypeAudio))
                    {
                        // Create a song object with the given url. This does not start loading it from disk.
                        TGSong *newSong = [[TGSong alloc] init];
                        
                        // Set the song pool to be a song's delegate.
                        [newSong setDelegate:self];
                        
                        // The song id is assigned.
                        [newSong setSongID:[SongID initWithString:[url absoluteString]]];
                        
                        dispatch_async(serialDataLoad, ^{
                            // Only add the loaded url if it isn't already in the dictionary.
                            TEOSongData* teoData = [self.TEOSongDataDictionary objectForKey:[url absoluteString]];
                            if (!teoData) {
                                // this needs to happen on the managed object context's own thread
    [self.TEOmanagedObjectContext performBlock:^{
                                newSong.TEOData = [TEOSongData insertItemWithURLString:[url absoluteString] inManagedObjectContext:self.TEOmanagedObjectContext];
    }];
                            } else {
                                // At this point we have found the song in the local store so we hook it up to the song instance for this run.
                                newSong.TEOData = teoData;
//                                NSLog(@"new song found %@",newSong.TEOData.title);
                                
                                // Upload any sweetspots that have not already been uploaded.
                                if (newSong.TEOData.sweetSpots.count) {
                                    [self sweetSpotsToServerForSong:newSong];
                                }
                                
                            }
                            
                            // Add the song to the songpool.
                            [songPoolDictionary setObject:newSong forKey:[SongID initWithString:[url absoluteString]]];
                            
                        });
                        
                        // Inform the delegate that another song object has been loaded. This causes a cell in the song matrix to be added.
                        if ((_delegate != Nil) && [_delegate respondsToSelector:@selector(songPoolDidLoadSongURLWithID:)]) {
                            [_delegate songPoolDidLoadSongURLWithID:[SongID initWithString:[url absoluteString]]];
                        }
                    }
                }
            }];
            
            [theOp setCompletionBlock:^{
                
                // Atomically increment the counter to track completed operations.
                OSAtomicIncrement32(&completedOps);
                
                // If we're done requesting new urls and
                // the number of completed operations is the same as the requested operations then
                // signal that we're done loading and signal our delegate that we're all done.
                if (allURLsRequested) {
                    if ( completedOps == requestedOps) {
                        // At this point we know how many songs to display.
                        
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


/**
    Attempt to find the cover image for the song using a variety of strategies and, if found, will pass the image to the given imageHandler block.
 */
- (void)requestImageForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage *))imageHandler {
    
//    NSLog(@"request image!");
    
    // First we should check if the song has an image stashed in the songpool local/temporary store.
    TGSong * theSong = [self songForID:songID];
    NSInteger artID = theSong.artID;
    if (artID >= 0) {
        NSLog(@"song id %@ already had image id %ld",songID,(long)artID);
        NSImage *songArt = [_artArray objectAtIndex:artID];
        if (imageHandler != nil) {
            imageHandler(songArt);
        }
        
        return;
    }
    NSAssert(theSong != nil,@"WTF, song is nil");
    // If nothing was found, try asking the song directly.
    // This is done by chaining asynchronous requests for data from either our Core Data store, from the file system and
    // finally from the network.
    // Request a cover image from the song passing in a block we want executed on resolution.
    [theSong requestCoverImageWithHandler:^(NSImage *tmpImage) {
        
        if (tmpImage != nil) {
            // Store the image in the local store so we won't have to re-fetch it from the file.
            [_artArray addObject:tmpImage];
//            NSLog(@"Adding imaage to art array.");
            
            /*
             TEO For now we don't have a good way of detecting whether an image is already in the
            // artArray so this is just filling it up with dupes. Commenting it out until a strategy is thought of.
            // Add the art index to the song.
            theSong.artID = [_artArray count]-1;
            */
            // Call the image handler with the image we recived from the song.
            if (imageHandler != nil) {
                imageHandler(tmpImage);
            }

            
            // We've succeeded, so drop out.
            return;
            
        } else {
            // Search strategies:
            // 1. See if other songs from the same album have album art in their metadata.
            // This will produce the wrong result for the (rare) albums where each song has a separate image.
            // Additionally this only produces album art once other songs' album art has been resolved which only
            // happens when the song is actively selected and played.
            [self requestSongsFromAlbumWithName:theSong.TEOData.album withHandler:^(NSArray* songs) {
                
                for (TEOSongData* songDat in songs) {
                    // Excluding the original song whose art we're looking for see if the others have it.
                    // Find the song from the url string.
                    // This will break until we switch song ids to be the song's url, then we can look it up directly.
//                    TGSong* aSong = [songPoolDictionary objectForKey:songDat.urlString];
                    //MARK: ARS
                    TGSong* aSong = [songPoolDictionary objectForKey:[SongID initWithString:songDat.urlString]];
                    if (aSong && ![aSong isEqualTo:theSong]) {
                        // Here we can check the song's artID to see if it already has album art.
                        if ((aSong.artID != -1) && [_artArray objectAtIndex:aSong.artID] ) {
//                            NSLog(@"Got cover art from another song in the same album!");
                            /*
                             TEO For now we don't have a good way of detecting whether an image is already in the
                             // artArray so this is just filling it up with dupes. Commenting it out until a strategy is thought of.
                            // Add the art index to the song.
                            theSong.artID = aSong.artID;
                             */
                            if (imageHandler != nil) {
                                imageHandler([_artArray objectAtIndex:aSong.artID]);
                            }
                            
                            
                            // We've succeeded, so drop out.
                            return;
                        }
                    }
                }
                
                // 2. Search the directory where the songID song is located for images.
                
                // Get the song's URL
                NSURL*      theURL = [NSURL URLWithString:theSong.TEOData.urlString];
                NSImage*    tmpImage = [self searchForCoverImageAtURL:theURL];
                
                if (tmpImage != nil) {
                    
//                    NSLog(@"found an image in the same folder as the song.");
                    // Store the image in the local store so we won't have to re-fetch it from the file.
                    [_artArray addObject:tmpImage];
                    
                    //FIXME: Sort out cover art caching.
                    /*
                     TEO For now we don't have a good way of detecting whether an image is already in the
                     // artArray so this is just filling it up with dupes. Commenting it out until a strategy is thought of.
                    // Add the art index to the song.
                    theSong.artID = [_artArray count]-1;
                    */
                    if (imageHandler != nil) {
                        imageHandler(tmpImage);
                    }
                    
                    
                    // We've succeeded, so drop out.
                    return;
                }
                
                // 3. Look up track then album then artist name online.
                
                
                [self requestCoverArtFromWebForSong:songID withHandler:^(NSImage* theImage) {
                    if (theImage != nil) {
                        
//                        NSLog(@"got image from the internets!");
                        // Store the image in the local store so we won't have to re-fetch it from the file.
                        [_artArray addObject:theImage];
                        
                        /* 
                            TEO this is the only place it still makes sense to keep the art even if it is a dupe (for now).
                            The artArray should be stored between runs so as to avoid net access all the time
                         */
                        // Add the art index to the song.
                        theSong.artID = [_artArray count]-1;
                        
                        if (imageHandler != nil) {
                            imageHandler(theImage);
                        }
                        
                        
                        // We've succeeded, so drop out.
                        return;
                    } else {
                        NSLog(@"got bupkiss from the webs");
                        // Finally, if no image was found by any of the methods, we call the given image handler with nil;
                        if (imageHandler != nil) {
                            imageHandler(nil);
                        }
                    }
                }];
                
            }];
        }
        
    }];
}

/**
 Request the cover art from the web for the given song.
 If the song has does not yet have a UUID then request one first and then send cover art request,
 otherwise just send request immediately. 
 The given hander is passed down to the cover art fetcher and is called by it on termination.
 */
-(void)requestCoverArtFromWebForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage*))imageHandler {
    
    TGSong * theSong = [self songForID:songID];
    // If there's no uuid, request one and pass it the art fetcher as a handler.
    if (theSong.TEOData.uuid != NULL) {
        [_coverArtWebFetcher requestAlbumArtFromWebForSong:songID imageHandler:imageHandler];
    } else {
        [theSong setFingerPrintStatus:kFingerPrintStatusRequested];
//        [songFingerPrinter requestFingerPrintForSong:theSong withHandler:^(NSString* fingerPrint){
                        NSLog(@"requestCoverArtForSong calling requestFingerPrintForSong");
        [songFingerPrinter requestFingerPrintForSong:songID withHandler:^(NSString* fingerPrint){
            if (fingerPrint == nil) {
                NSLog(@"requestCoverArtForSong ERROR: NO FINGERPRINT");
                return;
            }
            [_coverArtWebFetcher requestAlbumArtFromWebForSong:songID imageHandler:imageHandler];
            
        }];
    }
}

// Search for image files in the directory containing the given URL that match a particular pattern.
// The patterns looked for are any of the following strings anywhere in the image file name:
// The name of the album or
// the words "cover", "front" or "folder".
// Currently it simply picks the first image file that matches.
-(NSImage*)searchForCoverImageAtURL:(NSURL*)theURL {
    NSString* filePathString = [[theURL filePathURL] absoluteString];
    
    // Extract the containing directory by removing the trailing file name.
    NSString* theDirectory = [filePathString stringByDeletingLastPathComponent];
    
    NSError*        error;
    NSNumber*       isFile = nil;
    NSArray* keys = [NSArray arrayWithObject:NSURLIsRegularFileKey];
    
    // The enumerator does a traversal of the given url.
    NSDirectoryEnumerator *enumerator = [self.sharedFileManager
                                         enumeratorAtURL:[NSURL URLWithString:theDirectory]
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error getting the file. %@",error);
                                             // Return yes to continue traversing.
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        if (![url getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:&error]) {
            // handle error
            NSLog(@"An URL error %@ occurred.",error);
            return nil;
        }
        if ([isFile boolValue]) {
            // Check the file extension and deal only with audio files.
            CFStringRef fileExtension = (__bridge CFStringRef) [url pathExtension];
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
            
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)){
                NSString* regexString = [NSString stringWithFormat:@"(scan|album|art|cover|front|folder|%@)",[theDirectory lastPathComponent]];
//                NSLog(@"the regex string is %@",regexString);
                // At this point we extract the file name and, using a regex look for words like cover or front.
                NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
                
                NSString* imageURLString =[[url filePathURL] absoluteString];
                imageURLString = [imageURLString lastPathComponent];
                NSUInteger matches = [regex numberOfMatchesInString:imageURLString options:0 range:NSMakeRange(0, [imageURLString length])];
                if (matches > 0) {
//                    NSLog(@"The track name %@ has %ld matches",imageURLString,matches);
                    NSImage *theImage = [[NSImage alloc] initWithContentsOfURL:url];
                    if (theImage != nil) {
                        return theImage;
                    }
                }
                
                NSLog(@"                                   The image %@ did not match",imageURLString);
                
            }
        }
    }
    return nil;
}


/**
 Async'ly load the song metadata and call the given dataHandler with it.
 If the song already has the metadata it calls the dataHandler with the existing data.
 If the song does not exist it logs the fact and simply returns without calling the dataHandler.
 */
- (void)requestEmbeddedMetadataForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSDictionary*))dataHandler{
    dispatch_async(serialDataLoad, ^{
        TGSong *theSong = [self songForID:songID];
        if (theSong == nil) {
            NSLog(@"requestEmbeddedMetadataForSongID - no such song!");
            return ;
        }
        
        // Because loadSongMetadata writes to the managed object, we perform it on the context's thread.
        // TEO see if there's a way of avoiding this.
        [self.TEOmanagedObjectContext performBlock:^{
            // If the metadata has not yet been set, do it.
            if (theSong.TEOData.title == nil) {
                [theSong loadSongMetadata];
            }
            
            // Since the containing block is performed on the main thread and we want to spend as little on the main as possible doing this
            // we set the rest (dataHandler) off on a separate thread.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // call the datahandler with whatever metadata the song loaded.
                dataHandler([self songDataForSongID:songID]);
            });
        }];
    });
}


- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID {
    float secs = CMTimeGetSeconds([[self songForID:songID] songDuration]);
    return [NSNumber numberWithDouble:secs];
}


- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID {
    TGSong *aSong = [self songForID:songID];
    
    if (aSong) {
        return [NSURL URLWithString:[self songForID:songID].TEOData.urlString];
    }
    
    return nil;
}

- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID {
    TGSong *song = [self songForID:songID];
//    NSLog(@"songDataForSongID %ld, %@",(long)songID,song.TEOData);
    return @{@"Artist": song.TEOData.artist,
             @"Title": song.TEOData.title,
             @"Album": song.TEOData.album,
             @"Genre": song.TEOData.genre};
}

/*
- (void)offsetSweetSpotForSongID:(id<SongIDProtocol>)songID bySeconds:(Float64)offsetInSeconds {
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
*/
/*
- (void)setSweetSpotForSong:(TGSong *)theSong atTime:(NSNumber *)positionInSeconds {
    // Here we need to add a sweet spot and point to it.
//    [theSong setSweetSpot:positionInSeconds];
    
    [theSong setStartTime:positionInSeconds makeSweetSpot:YES];
#ifdef AE
    // TEO < AE
    [theSongPlayer setPlaybackToTime:[positionInSeconds doubleValue]];
    return;
    // TEO AE>
#endif
            [theSong setCurrentPlayTime:positionInSeconds];
            //FIXME: No longer needed...I think. Make sure, then remove.
            [songsWithChangesToSave addObject:theSong];
}
*/

- (BOOL)validSongID:(id<SongIDProtocol>)songID {
    // TEO: also check for top bound.
    if (songID == nil) return NO;

    return YES;
}

- (NSArray *)sweetSpotsForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) {
        return nil;
    }
    
    return [[self songForID:songID].TEOData.sweetSpots sortedArrayUsingDescriptors:nil];
}

- (NSSet*)currentCache {
    return songIDCache;
}

- (NSNumber*)cachedLengthForSongID:(id<SongIDProtocol>)songID {
    return [NSNumber numberWithLongLong:[self songForID:songID].cachedFileLength];
}

- (AVAudioFile*)cachedAudioFileForSongID:(id<SongIDProtocol>)songID {
    return [self songForID:songID].cachedFile;
}

- (NSString*)albumForSongID:(id<SongIDProtocol>)songID {
    return [self songForID:songID].TEOData.album;
}

- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID {
    return [self songForID:songID].TEOData.songReleases;
}

- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID {
    [self songForID:songID].TEOData.songReleases = releases;
}

- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    return [self songForID:songID].TEOData.uuid;
}

-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return;
    // TEO may have to use a serial access queue if this is called concurrently.
    [self songForID:songID].TEOData.uuid = theUUID ;
}


- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    
    return [NSURL URLWithString:[self songForID:songID].TEOData.urlString];
//    return [[self songForID:songID] songURL];
}

- (BOOL)sweetSpotHasBeenUploaded:(NSNumber*)theSS forSong:(TGSong*)theSong {
    return YES;
}

/** 
 Traverse the song's sweet spots and upload them to the sweet spot server.
*/
 - (void)sweetSpotsToServerForSong:(TGSong *)aSong {
     
     NSString * songUUID = aSong.TEOData.uuid;
     
     // Early out if there is no uuid.
     if (songUUID == nil) {
         NSLog(@"Error sending sweet spot to server. Song has no UUID");
         return;
     }

     for (NSNumber* sweetSpot in aSong.TEOData.sweetSpots) {
         
         // First check that the sweet spot for this song has not been uploaded before by
         // consulting the local list of uploaded sweet spots.
         if ([self sweetSpotHasBeenUploaded:sweetSpot forSong:aSong]) {
             continue;
         }
         
         NSURL *requestIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://localhost:6969/submit?songUUID=%s&songSweetSpot=%lf",[songUUID UTF8String],[sweetSpot doubleValue]]];
         
         NSLog(@"sanity check %@",requestIDURL);
         NSData *requestData = [[NSData alloc] initWithContentsOfURL:requestIDURL];
         
         if (requestData != nil) {
             NSDictionary *requestJSON = [NSJSONSerialization JSONObjectWithData:requestData options:NSJSONReadingMutableContainers error:nil];
             
             // First we check that the return status is ok.
             NSString *status = [requestJSON objectForKey:@"status"];
             
             if ([status isEqualToString:@"ok"]) {
                 NSLog(@"Upload to sweet spot server returned ok");
                 //FIXME:
                 // This is where we write to a stored list of uploaded ss's.
             } else
                 NSLog(@"ERROR: The server returned status : %@",status);
         } else
             NSLog(@"No data returned from sweetspot server.");
        
     }
}



/*
- (void)sweetSpotToServerForSong:(TGSong *)aSong {
    
    double sweetSpot = [[aSong startTime] doubleValue] ;
    NSString * songUUID = aSong.TEOData.uuid;
    
    // Early out if there is no uuid.
    if (songUUID == nil) {
        NSLog(@"Error sending sweet spot to server. Song has no UUID");
        return;
    }
    
    
    NSURL *requestIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://localhost:6969/submit?songUUID=%s&songSweetSpot=%lf",[songUUID UTF8String],sweetSpot]];
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
*/

- (void)sweetSpotFromServerForSong:(TGSong *)aSong {

    NSString * songUUID = aSong.TEOData.uuid;

    NSURL *theIDURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:6969/lookup?songUUID=%s",[songUUID UTF8String]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:theIDURL];
    
    [NSURLConnection sendAsynchronousRequest:request queue:opQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data != nil) {
            NSDictionary *requestJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // First we check that the return status is ok.
            NSString *status = [requestJSON objectForKey:@"status"];
            
            if ([status isEqualToString:@"ok"]) {
                id result = [requestJSON objectForKey:@"result"];
                if ([result isKindOfClass:[NSDictionary class]]) {

                    NSDictionary *resultDict = result;
                    // The first element is the songUUID which hopefully matches the one we sent to the server.
                    
                    // We then expect an array of sweetspots.
                    NSArray *sweetSpotsFromServer = [resultDict objectForKey:@"sweetspots"];
                    if ([sweetSpotsFromServer count] > 0) {

                        NSMutableSet* tmpSet = [aSong.TEOData.sweetSpots mutableCopy];
                        for (NSNumber* ss in sweetSpotsFromServer) {
                            [tmpSet addObject:ss];
                        }
                        aSong.TEOData.sweetSpots = tmpSet;

                        // TEO: temp set the start time to be the first sweet spot
                        NSNumber *sweetSpot = [sweetSpotsFromServer objectAtIndex:0];
                        [aSong setStartTime:sweetSpot makeSweetSpot:YES];
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
    if (([startTime doubleValue] == 0) && (song.TEOData.uuid  != nil) && (song.SSCheckCountdown-- == 0)) {
        
        // Reset the counter.
        song.SSCheckCountdown = (NSUInteger)kSSCheckCounterSize;
        
        // TEO finish off the timestamping of server requests instead of using the countdown.
        NSDate *now = [NSDate date];
        [now timeIntervalSinceDate:now];
        [self sweetSpotFromServerForSong:song];
    }
    
    return startTime;
}


-(NSNumber *)requestedPlayheadPosition {
    return requestedPlayheadPosition;
}


/** 
 This method sets the playhead position (what is that?) of the currently playing song to the requested position and sets a sweet spot for the song which gets stored on next save.
 The requestedPlayheadPosition should only result in a sweet spot when the user releases the slider.
*/
- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition {
    requestedPlayheadPosition = newPosition;
//    NSLog(@"setRequestedPlayheadPosition: %@",newPosition);
    
    TGSong* theSong = [self songForID:[self lastRequestedSongID]];
    //[[self songForID:[self lastRequestedSongID]] setStartTime:newPosition makeSweetSpot:NO];
    [theSong setCurrentPlayTime:newPosition];
    [theSong setSweetSpot:newPosition];
//    [self setSweetSpotForSong:[self songForID:[self lastRequestedSongID]] atTime:newPosition];
}


// TEO: Convenience method. May not need it for long.
- (float)fetchSweetSpotForSongID:(id<SongIDProtocol>)songID {
    TGSong *song = [self songForID:songID];
    return [[self fetchSongSweetSpot:song] floatValue];
}


/*
// updateCache:
// The song pool doesn't know about the layout of the song grid so it cannot decide which songs to cache.
// Therefore it is passed an array of ids that need caching.
// De-cache those songs in the cache that are no longer needed and initiate the caching of the new songs.
// TEO: consider adding an age/counter to the cached songs such that they don't get unloaded immediately (temporal caching).
- (void)updateCache:(NSArray *)songIDArray {
    for (id songID in songIDArray) {
        TGSong * aSong = [self songForID:songID];
        if (aSong != nil) {
            
            NSLog(@"loadTrackData called from updateCache");
            [aSong loadTrackDataWithCallBackOnCompetion:NO];
        } else
            NSLog(@"requested song %@ not there",(NSString*)songID);
    }
}
 */

- (id<SongIDProtocol>)lastRequestedSongID {
    return [lastRequestedSong songID];
}

- (id<SongIDProtocol>)currentlyPlayingSongID {
    return [currentlyPlayingSong songID];
}

-(TGSong *)songForID:(id<SongIDProtocol>)songID {
    return [songPoolDictionary objectForKey:songID];
}

- (dispatch_queue_t)serialQueue {
    return playbackQueue;
}

#pragma mark -
//MARK: Core Data methods

- (NSEntityDescription *)createSongUserDataEntityDescription {
    NSEntityDescription *songUserDataEntityDescription = [[NSEntityDescription alloc] init];
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
    
    return songUserDataEntityDescription;
}


- (NSManagedObjectModel *)createSongUserDataManagedObjectModelWithEntityDescription:(NSEntityDescription *)songUserDataEntityDescription {
    // Create the managed model.
    NSManagedObjectModel *songUserDataMOM = [[NSManagedObjectModel alloc] init];
    // Add the songUserData entity to the managed model.
    [songUserDataMOM setEntities:@[songUserDataEntityDescription]];
    
    // Define and add a localization directory for the entities.
    NSDictionary *localizationDictionary = @{
                                             @"Property/songURL/Entity/TGSongUserData": @"song URL",
                                             @"Property/songFingerPrint/Entity/TGSongUserData": @"song finger print",
                                             @"Property/songUUID/Entity/TGSongUserData": @"song UUID",
                                             @"Property/songUserSweetSpot/Entity/TGSongUserData": @"song Sweet Spot",
                                             @"Property/songSweetSpots/Entity/TGSongUserData": @"song Sweet Spots",
                                             @"ErrorString/Song URL missing.": @"The song URL is missing."};
    
    [songUserDataMOM setLocalizationDictionary:localizationDictionary];
    
    return songUserDataMOM;
}


- (NSPersistentStoreCoordinator *)createSongPoolPersistentStoreCoordinatorWithManagedObjectModel:(NSManagedObjectModel *)theMOM {
    // We only need one NSPersistentStoreCoordinator per program.
    NSPersistentStoreCoordinator *songPoolPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:theMOM];
    NSString *STORE_TYPE = NSSQLiteStoreType;
    NSString *STORE_FILENAME = @"TGSongUserData.sqlite";
    
    NSError *error;
    
    NSURL *url = [[self applicationSongUserDataDirectory] URLByAppendingPathComponent:STORE_FILENAME];
    
//TEO consider calling this on a separate thread as it may block.
    NSPersistentStore *newStore = [songPoolPSC addPersistentStoreWithType:STORE_TYPE
                                                                        configuration:nil
                                                                                  URL:url
                                                                              options:nil
                                                                                error:&error];
    
    if (newStore == nil) {
        NSLog(@"Store Configuration Failed.\n%@",([error localizedDescription] != nil) ?
              [error localizedDescription] : @"Unknown Error");
    }
    
    return songPoolPSC;
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

- (void)saveContext:(BOOL)wait {
    NSManagedObjectContext *moc = self.TEOmanagedObjectContext;
    NSManagedObjectContext *private = [self privateContext];
    
    if (!moc) return;
    if ([moc hasChanges]) {
        [moc performBlockAndWait:^{
            NSError *error = nil;
            NSAssert([moc save:&error], @"Error saving MOC: %@\n%@",
                    [error localizedDescription], [error userInfo]);
        }];
    }
    
    void (^savePrivate) (void) = ^{
        NSError *error = nil;
        NSAssert([private save:&error], @"Error saving private moc: %@\n%@",
                [error localizedDescription], [error userInfo]);
    };
    
    if ([private hasChanges]) {
        if (wait) {
            [private performBlockAndWait:savePrivate];
        } else {
            [private performBlock:savePrivate];
        }
    }
}

- (void)storeSweetSpotForSongID:(id<SongIDProtocol>)songID {
    TGSong *tmpSong = [self songForID:songID];
    [tmpSong storeSelectedSweetSpot];
}

// Go through all songs and store those who have had data added to them.
// This includes UUID or a user selected sweet spot.
- (void)storeSongData {
    // TEOSongData test
    [self saveContext:NO];
//    NSError *TEOError;
//    if (![self.TEOmanagedObjectContext save:&TEOError]) {
//        NSLog(@"Error while saving TEO data \n%@",
//              ([TEOError localizedDescription] != nil) ? [TEOError localizedDescription] : @"Unknown error.");
//    }
    // end TEOSongData test
    return;
}


// Fetch the whole song user data from the store to the persistent store coordinator.
// Presumably (but to be checked) this is faster than (in loadMetadataIntoSong) calling individual fetchrequests with predicates.
- (NSArray *)fetchMetadataFromLocalStore {
    
    NSFetchRequest *songUserDataFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
    NSError *error = nil;
    static NSArray *fetchedArray = nil;
    
    if (fetchedArray == nil) {
        fetchedArray = [songPoolManagedContext executeFetchRequest:songUserDataFetchRequest error:&error];
        if (error != nil) {
            NSLog(@"Error while fetching songUserData.\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
            return nil;
        }
    }
    return fetchedArray;
}

- (BOOL)loadMetadataIntoSong:(TGSong *)aSong {
    return YES;
}


// Fetch all songs from the given album asynchronously and call the given songArrayHandler block with the result.
-(void)requestSongsFromAlbumWithName:(NSString*)albumName withHandler:(void (^)(NSArray*))songArrayHandler {
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TEOSongData"];
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"album = %@",albumName];
    [fetch setPredicate:thePredicate];
    
    // Perform the fetch on the context's own thread to avoid threading problems.
    [self.TEOmanagedObjectContext performBlock:^{
        
        NSError *error = nil;
        NSArray* results = [self.TEOmanagedObjectContext executeFetchRequest:fetch error:&error];
        
        // Since the containing block is performed on the main thread and we want to spend as little on the main as possible doing this
        // we set the rest (songArrayHandler) off on a separate thread.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            songArrayHandler(results);
        });
    }];
}

// Not currently used.
- (NSString *)findUUIDOfSongWithURL:(NSURL *)songURL {
    NSString *theUUIDString = @"arses";
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"songURL = %@",[songURL absoluteString]];
    [fetch setPredicate:thePredicate];
    
    NSError *error = nil;
    NSArray *results = [songPoolManagedContext executeFetchRequest:fetch error:&error];
    if (results) {
        NSLog(@"Entititties: %@",results);
    } else {
        NSLog(@"Error: %@",error);
    }
    
    return theUUIDString;
}

#pragma mark -
// end of Core Data methods

#pragma mark Caching methods

/**
 Caching entrypoint. 
 This method is called with a cache context that defines the position and speed of the selection and
 is used to determine the optimal caching strategy.
 */
- (void)cacheWithContext:(NSDictionary*)cacheContext {
    // First we need to decide on a caching strategy.
    // For now we will simply do a no-brains area caching of two songs in every direction from the current cursor position.
    
    // We've got a new request so cancel all previous queued up requests.
    [urlCachingOpQueue cancelAllOperations];
    
    NSBlockOperation* cacheOp = [[NSBlockOperation alloc] init];
    
    // Weakify the block reference to avoid retain cycles.
    __weak NSBlockOperation* weakCacheOp = cacheOp;

    [weakCacheOp addExecutionBlock:^{
        
    // Make sure we have an inited cache.
    NSMutableSet* wantedCache = [[NSMutableSet alloc] initWithCapacity:25];
    
    NSInteger radius = 2;
        
    // Extract data from context
//    NSPoint speedVector     = [[cacheContext objectForKey:@"spd"] pointValue];
    NSPoint selectionPos    = [[cacheContext objectForKey:@"pos"] pointValue];
    NSPoint gridDims        = [[cacheContext objectForKey:@"gridDims"] pointValue];
    
    for (NSInteger matrixRows=selectionPos.y-radius; matrixRows<=selectionPos.y+radius; matrixRows++) {
        for (NSInteger matrixCols=selectionPos.x-radius; matrixCols<=selectionPos.x+radius; matrixCols++) {
            if ((matrixRows >= 0) && (matrixRows <gridDims.y)) {
                if((matrixCols >=0) && (matrixCols < gridDims.x)) {
                    
                    // skip if this is the selected cell (which is already cached or requested).
//                    if ((matrixRows == selectionPos.y) && (matrixCols == selectionPos.x))
//                        continue;
                    // Check for operation cancellation
                    if( weakCacheOp.isCancelled ) {return;}
                    
                    id<SongIDProtocol> songID = [_songGridAccessAPI songIDFromGridColumn:matrixCols andRow:matrixRows];
                    if (songID != nil) {
                        [wantedCache addObject:songID];
                    }
                }
            }
        }
    }
        
    // The stale cache is the existing cache - wanted cache
    NSMutableSet* staleCache = [songIDCache mutableCopy];
    [staleCache minusSet:wantedCache];
    
    // Check for operation cancellation
    if( weakCacheOp.isCancelled ) {return;}
        
    // Beyond this point we can no longer cancel because we now start affecting the external state.
    [self clearSongCache:[staleCache allObjects]];
        
    // DEBUG
    [_delegate setDebugCachedFlagsForSongIDArray:[staleCache allObjects] toValue:NO];
    
    // Remove the what's already cached from the wanted cache and load it.
    [wantedCache minusSet:songIDCache];
    [self loadSongCache:[wantedCache allObjects]];
        
    // DEBUG
    [_delegate setDebugCachedFlagsForSongIDArray:[wantedCache allObjects] toValue:YES];
    
    // Remove from the existing cache what is not in the wanted cache.
    [songIDCache minusSet:staleCache];
    [songIDCache unionSet:wantedCache];
    
    }];
    
    cacheOp.completionBlock = ^{
        NSLog(@"The caching block %@.",weakCacheOp.isCancelled ? @"cancelled" : @"completed");
    };

    [urlCachingOpQueue addOperation:cacheOp];
}

- (void)clearSongCache:(NSArray*)staleSongArray {
    dispatch_async(cacheClearingQueue, ^{
        for (id<SongIDProtocol> songID in staleSongArray) {
            TGSong *aSong = [self songForID:songID];
//            NSLog(@"Clearing %@ with ID %@",aSong.TEOData.title,songID);
            [aSong clearCache];
        }
    });
}

/**
 Blind caching method that simply initiates loading of all the songs in the array it is given.
 */
- (void)loadSongCache:(NSArray*)desiredSongArray {
    // First we make sure to clear any pending requests.
    // What's on the queue is not removed until its turn.
//    [urlCachingOpQueue cancelAllOperations];
    
    // Then we add the tracks to cache queue.
//    [urlCachingOpQueue addOperationWithBlock:^{
        // TEO - calling this async'ly crashes in core data.
        // The loadTrackData won't reload a loaded track but we can probably still save some loops.
        for (id<SongIDProtocol> songID in desiredSongArray) {
            
            TGSong *aSong = [self songForID:songID];
            if (aSong == NULL) {
                NSLog(@"Nope, the requested ID %@ is not in the song pool.",songID);
                return;
            }
//            NSLog(@"Caching %@ with id %@",aSong.TEOData.title,songID);
//#ifdef AE
//            NSError* error;
//            [aSong setCache:[[AVAudioFile alloc] initForReading:[NSURL URLWithString:aSong.TEOData.urlString] error:&error]];
//#endif
            // tell the song to load its data asyncronously without requesting a callback on completion.
            [aSong loadTrackDataWithCallBackOnCompletion:NO];
            
            // We should try and get the metadata so it's ready,
            // but not so that songPoolDidLoadDataForSongID gets called for each song.
            [self requestEmbeddedMetadataForSongID:songID withHandler:^(NSDictionary* theData){
                //            NSLog(@"preloadSongArray got data! %@",theData);
            }];
            
            // We should also initiate the caching of the album art.
            [self requestImageForSongID:songID withHandler:nil];
        }
    
        // Tell the song player to refresh the frameCount of the currently playing song now that
        // the songs have finished caching and we know the lengths.
//        [theSongPlayer refreshPlayingFrameCount];
//    }];
}

/*
- (void)preloadSongArray:(NSArray *)songArray {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    // First we make sure to clear any pending requests
    [urlCachingOpQueue cancelAllOperations];
    
    // Then we add the tracks to cache queue.
    [urlCachingOpQueue addOperationWithBlock:^{
        // TEO - calling this async'ly crashes in core data.
        // Be smarter about this. Keep track of what's cached (in a set) and only recache what's missing.
        // The loadTrackData won't reload a loaded track but we can probably still save some loops.
        for (id<SongIDProtocol> songID in songArray) {
            TGSong *aSong = [self songForID:songID];
            if (aSong == NULL) {
                NSLog(@"Nope, the requested ID %@ is not in the song pool.",songID);
                return;
            }
            NSLog(@"Caching %@",songID);
            // tell the song to load its data asyncronously without requesting a callback on completion.
            [aSong loadTrackDataWithCallBackOnCompletion:NO];
            
            // We should try and get the metadata so it's ready,
            // but not so that songPoolDidLoadDataForSongID gets called for each song.
            [self requestEmbeddedMetadataForSongID:songID withHandler:^(NSDictionary* theData){
                //            NSLog(@"preloadSongArray got data! %@",theData);
            }];
        }
        
    }];
}
*/

#pragma mark -
/**
 Initiate a request to play back the given song at its selected sweet spot.
 :params: songID The id of the song to play.
*/
- (void)requestSongPlayback:(id<SongIDProtocol>)songID {
    TGSong *aSong = [self songForID:songID];
    if (aSong == nil) {
        return;
    }
    
    [self requestSongPlayback:songID withStartTimeInSeconds:aSong.startTime makeSweetSpot:NO];
}
/**
    Initiate a request to play back the given song at the given start time in seconds.
 :params: songID The id of the song to play.
 :params: time The offset in seconds to start playing the song at.
 */
- (void)requestSongPlayback:(id<SongIDProtocol>)songID withStartTimeInSeconds:(NSNumber *)time makeSweetSpot:(BOOL)makeSS {
    
    TGSong *aSong = [self songForID:songID];
    if (aSong == NULL) {
        NSLog(@"Nope, the requested ID %@ is not in the song pool.",songID);
        return;
    }
    
    lastRequestedSong = aSong;
    
    //MARK: TMP
    // So the issue here is that there are two ways of requesting a song playback;
    // * Set a sweet spot so that subsequent playbacks also start at the given time.
    // * A one-off playback at the given time (eg, scrubbing or when the playlist starts a song)
    // So, perhaps we need two separate methods or signal the intention via a parameter.
    [aSong setStartTime:time makeSweetSpot:makeSS];
    
//    [aSong setRequestedSongStartTime:CMTimeMakeWithSeconds([time doubleValue], 1)];
    
//    NSLog(@"the urlLoadingQueue size: %lu",(unsigned long)[urlLoadingOpQueue operationCount]);
    // First cancel any pending requests in the operation queue and then add this.
    // This won't delete them from the queue but it will tell each in turn it has been cancelled.
    [urlLoadingOpQueue cancelAllOperations];
    
    // Then add this new request.
    [urlLoadingOpQueue addOperationWithBlock:^{
        //    NSLog(@"loadTrackData called from requestSongPlayback");
        // Asynch'ly start loading the track data for aSong. songReadyForPlayback will be called back when the song is good to go.
        [aSong loadTrackDataWithCallBackOnCompletion:YES];
    }];
}

/// Setter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (void)setPlayheadPos:(NSNumber *)newPos {
    playheadPos = newPos;
}

/// Getter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (NSNumber *)playheadPos {
    return playheadPos;
}


- (void)playbackSong:(TGSong *)nextSong {
    
    // Between checking and stopping another thread can modify the currentlyPlayingSong thus causing the song to not be stopped.
    if (currentlyPlayingSong != nextSong) {
        [currentlyPlayingSong playStop];
    }
    
    if (currentlyPlayingSong == nextSong) {
        NSLog(@"currently playing is the same as next song. Early out.");
        return;
    }
    NSNumber* theStartTime = [nextSong playStart];
    if (theStartTime) {
        currentlyPlayingSong = nextSong;
        
        NSNumber *theSongDuration = [NSNumber numberWithDouble:[currentlyPlayingSong getDuration]];
        [self setValue:theSongDuration forKey:@"currentSongDuration"];
        
        // Song fingerprints are generated and UUID fetched during idle time in the background.
        // However, if the song about to be played hasn't got a UUID or fingerprint, an async request will be initiated here.
//        if ([nextSong songUUIDString] == NULL) {
        if (nextSong.TEOData.uuid == NULL) {
            if ([nextSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
                [nextSong setFingerPrintStatus:kFingerPrintStatusRequested];
                NSLog(@"playbacksong calling requestFingerPrintForSong");
                [songFingerPrinter requestFingerPrintForSong:nextSong];
            }
        }

        // Inform the delegate that we've started playing the song.
        if ([_delegate respondsToSelector:@selector(songPoolDidStartPlayingSong:)]) {
            [_delegate songPoolDidStartPlayingSong:[nextSong songID]];
        }
        
        // Set the requested playheadposition tracker to the song's start time in a KVC compliant fashion.
        [self setRequestedPlayheadPosition:theStartTime];
        
    }
}


#pragma mark -
#pragma mark Delegate Methods

// TGfingerPrinterDelegate methods.
#pragma mark TGFingerPrinterDelegate methods
// Called by the finger printer when it has finished fingerprinting a song.
- (void)fingerprintReady:(NSString *)fingerPrint ForSong:(TGSong *)song {
    //NSLog(@"fingerprintReady received for song %@",[song songURL]);
    
    // At this point we should check if the fingerprint resulted in a songUUID.
    // If it did not we keep the finger print so we don't have to re-generate it, otherwise we can delete the it.
//    if ([song songUUIDString] == nil) {
    if (song.TEOData.uuid == nil) {
        NSLog(@"No UUID found, keeping fingerprint.");
//        [song setFingerprint:fingerPrint];
        song.TEOData.fingerprint = fingerPrint;
    }
    else {
        // The song has a UUID, so there's no need to keep the fingerprint.
//        [song setFingerprint:nil];
        // TEO - Is there any reason for not keeping the fingerprint (aside from memory)?
        song.TEOData.fingerprint = nil;
    }
    
    [song setFingerPrintStatus:kFingerPrintStatusDone];
    
//    // Check the song user data DB to see if we have song data for the UUID/fingerprint.
//    // If found, load the data into the song.
//    if (![self loadMetadataIntoSong:song]) {
//        // If not found in the user data file, add the song to a songsWithChangesToSave dictionary so any changes to it are stored.
//        [songsWithChangesToSave addObject:song];
//    }    
}



// TSGSongDelegate methods.
#pragma mark TGSongDelegate methods

- (void)songDidFinishPlayback:(TGSong *)song {
    // Pass this on to the delegate (which should be the controller).
    NSLog(@"song %lu did finish playback. The last requested song is %@",(unsigned long)[song songID],[lastRequestedSong songID]);
    if ([[self delegate] respondsToSelector:@selector(songPoolDidFinishPlayingSong:)]) {
        [[self delegate] songPoolDidFinishPlayingSong:[song songID]];
    }
}


//// TEO currently not called by anyone. Should probably be called by TGSong loadSongMetaData but since it isn't 
//- (void)songDidLoadEmbeddedMetadata:(TGSong *)song {
//    
//    if ([[self delegate] respondsToSelector:@selector(songPoolDidLoadDataForSongID:)]) {
//        [[self delegate] songPoolDidLoadDataForSongID:[song songID]];
//    }
//    
//}

// Delegate method that allows a song to set the songpool's playhead position tracker variable.
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition {
    [self setValue:playheadPosition forKey:@"playheadPos"];
}

// songReadyForPlayback is called (async'ly) by the song once it is fully loaded.
- (void)songReadyForPlayback:(TGSong *)song {

    //MARK: TMP
//     If there's a one-off start time set, use that (and reset it).
    //if ([song startTime] == nil) {
    if ([[song startTime] doubleValue] == 0) {
        [song setStartTime:[self fetchSongSweetSpot:song] makeSweetSpot:YES];
    }
    
    // Make sure the last request for playback is put on a serial queue so it always is the last song left playing.
    if (song == lastRequestedSong) {
        dispatch_async(playbackQueue, ^{
//            NSLog(@"putting song %lu on the playbackQueue",(unsigned long)[song songID]);
            [self playbackSong:song];
        });
    }
}


@end
