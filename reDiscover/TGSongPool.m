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

#import "UploadedSSData.h"

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
@interface TGSongPool () <TGSongDelegate,TGFingerPrinterDelegate,SongPoolAccessProtocol>
@end

// constant definitions
static int const kSSCheckCounterSize    = 10;
static int const kDefaultAlbumSongCount = 8;
static int const kSongPoolStartCapacity = 250;

@implementation TGSongPool

- (id)initWithURL:(NSURL*) theURL {
    if( [self validateURL:theURL]) {
        return [self init];
    } else {
        return nil;
    }
}

/**
 Check that the given URL is a valid directory.
*/
- (BOOL)validateURL:(NSURL *)anURL {
    
    // for now just say yes
    return YES;
}

- (id)init {
    self = [super init];
    if (self != NULL) {
        
        requestedPlayheadPosition = [NSNumber numberWithDouble:0];
        
        songPoolDictionary = [[NSMutableDictionary alloc] initWithCapacity:kSongPoolStartCapacity];
        currentlyPlayingSong = NULL;
        
        /// Make url queues and make them serial so they can be cancelled.
        urlLoadingOpQueue = [[NSOperationQueue alloc] init];
        [urlLoadingOpQueue setMaxConcurrentOperationCount:1];
        urlCachingOpQueue = [[NSOperationQueue alloc] init];
        [urlCachingOpQueue setMaxConcurrentOperationCount:1];
        
        // Actual serial queues.
        playbackQueue = dispatch_queue_create("playback queue", NULL);
        serialDataLoad = dispatch_queue_create("serial data load queue", NULL);
        timelineUpdateQueue = dispatch_queue_create("timeline GUI updater queue", NULL);
        
        
        // Set up session cache of image covers.
        _artArray = [[NSMutableArray alloc] initWithCapacity:100];
        [_artArray addObject:[NSImage imageNamed:@"noCover"]];
        
        // Create and hook up the song fingerprinter.
        songFingerPrinter = [[TGFingerPrinter alloc] init];
        [songFingerPrinter setDelegate:self];

        /* cdfix
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
        */
        self.sharedFileManager = [[NSFileManager alloc] init];
        
        // Get any user metadata from the local Core Data store.
        //cdfix [self fetchMetadataFromLocalStore];

        // Register to be notified of idle time starting and ending.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeBegins) name:@"TGIdleTimeBegins" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeEnds) name:@"TGIdleTimeEnds" object:nil];
        
        /// The CoverArtArchiveWebFetcher handles all comms with the remote cover art archive.
        _coverArtWebFetcher = [[CoverArtArchiveWebFetcher alloc] init];
        _coverArtWebFetcher.delegate = self;
        
        // Set up TEOSongData
        [self setupManagedObjectContext];
        
        // The sweetSpotServerIO object handles all comms with the remote sweet spot server.
        _sweetSpotServerIO = [[SweetSpotServerIO alloc] init];
        _sweetSpotServerIO.delegate = self;
        
        /// The class that plays back the audio. Not currently used.
//        theSongPlayer = [[SongPlayer alloc] init];
//        theSongPlayer.delegate = self;
        
        // Starting off with an empty songID cache.
        songIDCache = [[NSMutableSet alloc] init];
        cacheClearingQueue = dispatch_queue_create("cache clearing q", NULL);
    }
    
    return self;
}

/**
 TEOSongData set up the Core Data context and store.
*/
- (void)setupManagedObjectContext {
    
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"TEOSong" withExtension:@"momd"];
    NSManagedObjectModel* mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    /** 
    A MOC whose parent context is nil is considered a root context and is connected directly to the persistent store coordinator.
    If a MOC has a parent context the MOC's fetch and save ops are mediated by the parent context.
    This means the parent context can, on its own private thread, service the requests from various children on different threads.
    Changes to a context are only committed one store up. If you save a child context, changes are pushed to its parent.
    Only when the root context is saved are the changes committed to the store (by the persistent store coordinator associated with the root context).
    A parent context does *not* pull from its children before it saves, so the children must save before the parent.
    */
    NSManagedObjectContext* private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setPersistentStoreCoordinator:psc];

    self.TEOmanagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

    //MARK: This may now be unnecessary since the TEOMOC is running on its own private queue.
    [self.TEOmanagedObjectContext setParentContext:private];
    [self setPrivateContext:private];
    
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
    
}

- (NSManagedObjectContext*)TEOSongDataMOC {
    return self.TEOmanagedObjectContext;
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
    
    if (aSong.uuid == NULL) {
        [self fetchUUIdForSongId:aSong.songID];
        interval = 3;
    } else {
        
        // Fetch any sweet spots for this song if it doesn't have a start time or it has been a long time since the last sweet spot server update.
        //FIXME:
//        if ([[aSong startTime] doubleValue] == -1) {
//            [self fetchSongSweetSpot:aSong];
//        }

    }
    
    // Start a new timer with the next song.
    idleTimeFingerprinterTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                  target:self
                                                                selector:@selector(idleTimeRequestFingerprint:)
                                                                userInfo:@{@"songEnumerator" : theSongEnumerator }
                                                                 repeats:YES];
}

- (void)fetchUUIdForSongId:(id<SongIDProtocol>)songID {
    TGSong* aSong = [self songForID:songID];
    if ([aSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
        NSLog(@"SongPool fetchUUIdForSongId about to request a fingerprint for song %@",aSong);
        [aSong setFingerPrintStatus:kFingerPrintStatusRequested];
        
        [songFingerPrinter requestFingerPrintForSong:aSong.songID withHandler:^(NSString* fingerPrint){
            if (fingerPrint == nil) {
                NSLog(@"requestFingerprintForSong ERROR: NO FINGERPRINT");
                [aSong setFingerPrintStatus:kFingerPrintStatusFailed];
                return;
            }
            [self fingerprintReady:fingerPrint forSongID:aSong.songID];
        }];
    } else {
        NSLog(@"We have a fingerprint but no UUId!");
        [songFingerPrinter requestUUIDForSongID:aSong.songID
                                   withDuration:CMTimeGetSeconds(aSong.songDuration)
                                 andFingerPrint:(char *)[aSong.fingerprint UTF8String]];
        
    }
    
}

- (void)idleTimeEnds {
//    NSLog(@"song pool idle end");
    
    // Stop the fingerprinter.
    [idleTimeFingerprinterTimer invalidate];
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
    
    NSLog(@"loadFromURL running on the main thread? %@",[NSThread isMainThread]?@"Yep":@"Nope");
    
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
                        // Set the song's song pool API in a move away from using delegates for everything... wip
                        [newSong setSongPoolAPI:self];
                        
                        // The song id is assigned.
                        [newSong setSongID:[SongID initWithString:[url absoluteString]]];
                        NSAssert(serialDataLoad != nil, @"WTF serialDataLoad is nil!");
                        dispatch_async(serialDataLoad, ^{
                            
                            // cdfix This should no longer hook up the song to a managed object but instead
                            // it should copy the data across and let the array go. We do not want to have to access
                            // the properties through a managed context as that requires us to go through its thread
                            // which can deadlock/delay on concurrent access.
                            
                            
                            TEOSongData* teoData = [self.TEOSongDataDictionary objectForKey:[url absoluteString]];
                            // cdfix
                            [self copyData:teoData toSong:newSong forURL:[url absoluteString]];
 
                       /*
                            // Only add the loaded url if it isn't already in the dictionary.
                            if (!teoData) {
                                // this needs to happen on the managed object context's own thread
                                [self.TEOmanagedObjectContext performBlock:^{
                                    newSong.TEOData = [TEOSongData insertItemWithURLString:[url absoluteString] inManagedObjectContext:self.TEOmanagedObjectContext];
                                }];
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"TGNewSongLoaded" object:newSong];
                            } else {
                                // At this point we have found the song in the local store so we hook it up to the song instance for this run.
                                newSong.TEOData = teoData;
                            }
                         */
                            // Add the song to the songpool.
                            [songPoolDictionary setObject:newSong forKey:newSong.songID];
                            
                            
                            // Upload any sweetspots that have not already been uploaded.
                            if (newSong.sweetSpots.count) {
                                [_sweetSpotServerIO uploadSweetSpotsForSongID:newSong.songID];
                            }
                  
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
/*
 @property NSString*         album;
 @property NSString*         artist;
 @property NSArray*          sweetSpots;
 @property NSString*         urlString;
 @property NSString*         uuid;
 @property NSNumber*         year;
 @property NSString*         fingerprint;
 @property NSString*         title;
 @property NSString*         genre;
 @property NSNumber*         selectedSweetSpot;
 @property NSData*           songReleases;
 */

- (void) copyData:(TEOSongData*)songData toSong:(TGSong*)aSong forURL:(NSString*)songURL {
    
    // If there is no existing song Data we create one...(not sure if this should be deferred to when we actually save)
    if (songData == nil) {
        // this needs to happen on the managed object context's own thread
        [self.TEOmanagedObjectContext performBlock:^{
            [TEOSongData insertItemWithURLString:songURL inManagedObjectContext:self.TEOmanagedObjectContext];
            aSong.urlString = songURL;
            aSong.sweetSpots = [[NSArray alloc] init];
            aSong.year = [NSNumber numberWithInteger:0];
        }];
    } else {

        // At this point we have found the song in the local store so we copy the data across.
        aSong.album             = songData.album;
        aSong.artist            = songData.artist;
        aSong.sweetSpots        = songData.sweetSpots;
        aSong.urlString         = songData.urlString;
        aSong.uuid              = songData.uuid;
        aSong.year              = songData.year;
        aSong.fingerprint       = songData.fingerprint;
        aSong.title             = songData.title;
        aSong.genre             = songData.genre;
        aSong.selectedSweetSpot = songData.selectedSweetSpot;
        aSong.songReleases      = songData.songReleases;
        
    }
}

/**
    Attempt to find the cover image for the song using a variety of strategies and, if found, will pass the image to the given imageHandler block.
 */
- (void)requestImageForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage *))imageHandler {

    // First we should check if the song has an image stashed in the songpool local/temporary store.
    TGSong * theSong = [self songForID:songID];
    NSInteger artID = theSong.artID;
    
    if (artID >= 0) {
        //NSLog(@"song id %@ already had image id %ld",songID,(long)artID);
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
    [theSong searchMetadataForCoverImageWithHandler:^(NSImage *tmpImage) {
    
        if (tmpImage != nil) {
            // Store the image in the local store so we won't have to re-fetch it from the file.
            [_artArray addObject:tmpImage];
            /*
             TEO For now we don't have a good way of detecting whether an image is already in the
            // artArray so this is just filling it up with dupes. Commenting it out until a strategy is thought of.
            // Add the art index to the song.
            theSong.artID = [_artArray count]-1;
            */
            
            // wipwip Since the following call can happen without lagging it cannot be the imageHandler that is causing it.
            // Call the image handler with the image we recived from the song.
            if (imageHandler != nil) {
                imageHandler(tmpImage);
            }
            
            // We've succeeded, so drop out.
            return;
            
        } else {

            // Search strategies:
            //
            // 1. See if other songs from the same album have album art in their metadata.
            //
            // This will produce the wrong result for the (rare) albums where each song has a separate image.
            // Additionally this only produces album art once other songs' album art has been resolved which only
            // happens when the song is actively selected and played.
//            [self requestSongIdsFromAlbumWithName:theSong.album withHandler:^(NSArray* songs) {
            [self requestSongIdsFromAlbumWithName:theSong.album withHandler:^(NSArray* songIds) {
return;//wipwip endpoint The following still causes some lag.
                
                // Excluding the original song whose art we're looking for see if the others have it.
//                for (TEOSongData* songDat in songs) {
                for (id<SongIDProtocol> songId in songIds) {
                    // Find the song from the url string.
//                    TGSong* aSong = [songPoolDictionary objectForKey:[SongID initWithString:songDat.urlString]];
                    TGSong* aSong = [self songForID:songId];
                    
                    if (aSong && ![aSong isEqualTo:theSong]) {
                        
                        // Here we can check the song's artID to see if it already has album art.
                        if ((aSong.artID != -1) && [_artArray objectAtIndex:aSong.artID] ) {
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
              
                //
                // 2. Search the directory where the song is located for images.
                //
                // Get the song's URL
                NSURL*      theURL = [NSURL URLWithString:theSong.urlString];
                
                NSImage*    tmpImage = [self searchForCoverImageAtURL:theURL];
                
                if (tmpImage != nil) {
                    
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
                
                //
                // 3. Look up track then album then artist name online.
                //
                [self requestCoverArtFromWebForSong:songID withHandler:^(NSImage* theImage) {
                    if (theImage != nil) {
                        
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
    if (theSong.uuid != NULL) {
        [_coverArtWebFetcher requestAlbumArtFromWebForSong:songID imageHandler:imageHandler];
    } else {
        // At this point it could be the case that the song already has a fingerprint but no UUID
        // either because it is waiting for the server to return it or because the server could not
        // map the fingerprint to a uuid.
        if (([theSong fingerPrintStatus] == kFingerPrintStatusDone) || ([theSong fingerPrintStatus] == kFingerPrintStatusRequested)){
            NSLog(@"We have a fingerprint but no UUID (yet). The status is %lu",(unsigned long)[theSong fingerPrintStatus]);
            imageHandler(nil);
        } else {
            [self fetchUUIdForSongId:songID];
            /*
            [theSong setFingerPrintStatus:kFingerPrintStatusRequested];

            NSLog(@"requestCoverArtForSong calling requestFingerPrintForSong");
            [songFingerPrinter requestFingerPrintForSong:songID withHandler:^(NSString* fingerPrint){
                if (fingerPrint == nil) {
                    NSLog(@"requestCoverArtForSong ERROR: NO FINGERPRINT");
                    [theSong setFingerPrintStatus:kFingerPrintStatusFailed];
                    return;
                }
                
                [self fingerprintReady:fingerPrint forSongID:songID];
                
                // Only request the album art from web server if we have a uuid to send them.
                if ([self UUIDStringForSongID:songID] != nil) {
                    [_coverArtWebFetcher requestAlbumArtFromWebForSong:songID imageHandler:imageHandler];
                }
            }];
             */
            //wipwip moved out of the commented bit above.
            // Only request the album art from web server if we have a uuid to send them.
            if ([self UUIDStringForSongID:songID] != nil) {
                [_coverArtWebFetcher requestAlbumArtFromWebForSong:songID imageHandler:imageHandler];
            }

        }
    }
}

/**
 Search for image files in the directory containing the given URL that match a particular pattern.
 
 The patterns looked for are any of the following strings anywhere in the image file name:

 - The name of the album or

 - the words "cover", "front" or "folder".
 
 - Currently it simply picks the first image file that matches.

 @params theURL The URL to search.
 */
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
                
                // At this point we extract the file name and, using a regex look for words like cover or front.
                NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
                
                NSString* imageURLString =[[url filePathURL] absoluteString];
                imageURLString = [imageURLString lastPathComponent];
                NSUInteger matches = [regex numberOfMatchesInString:imageURLString options:0 range:NSMakeRange(0, [imageURLString length])];
                
                if (matches > 0) {
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
        
        // If the metadata has not yet been set, do it.
        if (theSong.title == nil) {
            [theSong loadSongMetadata];
            
            // If the song's album is not the default value,
            // add album the song belongs to the list of albums
            if ([theSong.album isEqualToString:@"Unknown"] == NO) {
                if (_allAlbums == nil) {
                    _allAlbums = [[NSMutableDictionary alloc] initWithCapacity:kSongPoolStartCapacity/8];
                }
                
                // First see if the album is already there.
                NSSet* albumSongs = [_allAlbums objectForKey:theSong.album];
                if (albumSongs == nil) {
                    NSMutableSet* songSet = [NSMutableSet setWithCapacity:kDefaultAlbumSongCount];
                    [songSet addObject:theSong.songID];
                    [_allAlbums setObject:songSet forKey:theSong.album];
                } else {
                    NSMutableSet* songSet = [_allAlbums objectForKey:theSong.album];
                    [songSet addObject:theSong.songID];
                }
                
            }
            
        }

        dataHandler([self songDataForSongID:songID]);
        
    });
}


- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID {
    float secs = CMTimeGetSeconds([[self songForID:songID] songDuration]);
    return [NSNumber numberWithDouble:secs];
}


- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID {
    TGSong *aSong = [self songForID:songID];
    
    if (aSong) {
        return [NSURL URLWithString:[self songForID:songID].urlString];
    }
    
    return nil;
}


- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID {
    TGSong *song = [self songForID:songID];
    return @{@"Artist": song.artist,
             @"Title": song.title,
             @"Album": song.album,
             @"Genre": song.genre};
}


- (BOOL)validSongID:(id<SongIDProtocol>)songID {
    // TEO: also check for top bound.
    if (songID == nil) return NO;

    return YES;
}


- (void)setActiveSweetSpotIndex:(int)ssIndex forSongID:(id<SongIDProtocol>)songID {

    TGSong* theSong = [self songForID:songID];

//    if (theSong == nil || theSong.TEOData == nil || theSong.sweetSpots == nil) {
    if (theSong == nil || theSong.sweetSpots == nil) {
        NSLog(@"setActiveSweetSpotIndex ERROR: unexpected nil");
        return;
    }
    
    if (ssIndex >= 0 && ssIndex < theSong.sweetSpots.count ) {
        [theSong makeSweetSpotAtTime:theSong.sweetSpots[ssIndex]];
    }
}


- (void)replaceSweetSpots:(NSArray*)sweetSpots forSongID:(id<SongIDProtocol>)songID {
    TGSong* theSong = [self songForID:songID];
    if (theSong == nil) { return; }
    
    theSong.sweetSpots = sweetSpots;
    
    // wipwip
    // This does not change the playback position though because it's called after the playback is requested.
    // Subsequent playback requests will start from the active sweet spot.
    // Instead of changing the playback position whilst the song is playing it would be better, when a song's
    // uuid comes in, to check if the song is currently selected and, if so, initiate a request for sweet spots.
    // That way it is only on the second selection of a song that it starts playing from a sweet spot instead of
    // on the third.
    [self setActiveSweetSpotIndex:0 forSongID:songID];
    
    //wipEv
    // We should signal that the song's sweet spots have changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SweetSpotsUpdated" object:theSong.songID];
}


- (NSArray*)sweetSpotsForSongID:(id<SongIDProtocol>)songID {
    TGSong* theSong = [self songForID:songID];
    if (theSong == nil) { return nil; }
    
    return theSong.sweetSpots;
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
        return [self songForID:songID].album;
}

- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID {
    return [self songForID:songID].songReleases;
}

- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID {
    [self songForID:songID].songReleases = releases;
}

- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    return [self songForID:songID].uuid;
}

-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return;
    
    [self songForID:songID].uuid = theUUID ;
    
    TGSong* theSong = [self songForID:songID];
    theSong.fingerprint = nil;
    
    // With an UUId (re)try to fetch the sweet spots from the server.
    [self fetchSongSweetSpot:theSong];

}

- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    
    return [NSURL URLWithString:[self songForID:songID].urlString];
}

//MARK: test method

- (BOOL)fingerprintExistsForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return NO;
    
    return [self songForID:songID].fingerprint != nil;
}
- (void)testUploadSSForSongID:(id<SongIDProtocol>)theID {
    [_sweetSpotServerIO uploadSweetSpotsForSongID:theID];
}


/** 
 This will return the "sweet spot" for the given song.
 If no local sweet spot is found a request for sweet spots is sent to the remote sweet spot server.
 @params song The song we want the sweet spot for.
 @returns The currently selected sweet spot for the given song.
*/
- (NSNumber *)fetchSongSweetSpot:(TGSong *)song {
//- (NSNumber *)fetchSongSweetSpot:(TGSong *)song withHandler:(void (^)(NSNumber*))sweetSpotHandler {
    // Get the song's start time in seconds.
//    NSNumber *startTime = [song startTime];
    NSNumber *startTime = [song currentSweetSpot];
    
    /// Request sweetspots from the sweetspot server if the song does not have a start time, has a uuid and has not
    /// exceeded its alotted queries.

    //FIXME:
    /// Don't use the ssCheckCountdown. Only check sweetspots on app start and only for songs that don't already have any.
    /// A manual refresh would be the way to force a check.
    /// Also, if there's no uuid, should we send off for fingerprinting and uuid lookup or should this occur higher up the stack
    /// and the check for uuid should opt out sooner...
    if ((startTime == nil) && (song.uuid != nil) && (song.SSCheckCountdown-- == 0)) {
        // Reset the counter.
        song.SSCheckCountdown = (NSUInteger)kSSCheckCounterSize;
        
        [_sweetSpotServerIO requestSweetSpotsForSongID:song.songID];
    }
    
    return startTime;
}


-(NSNumber *)requestedPlayheadPosition {
    return requestedPlayheadPosition;
}


/** 
 This method sets the requestedPlayheadPosition (which represents the position the user has manually set with a slider)
 of the currently playing song to newPosition and sets a sweet spot for the song which gets stored on next save.
 The requestedPlayheadPosition should only result in a sweet spot when the user releases the slider.
*/
//- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition forSongID:(id<SongIDProtocol>)songID {
- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition {
    requestedPlayheadPosition = newPosition;
//    NSLog(@"setRequestedPlayheadPosition: %@",newPosition);
    
    TGSong* theSong = [self songForID:[self lastRequestedSongID]];
//    TGSong* theSong = [self songForID:songID];
    
    // Set the current playback time and the currently selected sweet spot to the new position.
    [theSong setCurrentPlayTime:newPosition];
    [theSong setSweetSpot:newPosition];
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
/*
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
*/

/*
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
*/

/*
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
*/


/*
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
*/

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

// Currently only called manually by pressing the s key.
// Go through all songs and store those who have had data added to them.
// This includes UUID or a user selected sweet spot.
- (void)storeSongData {
    // TEOSongData test
    [self saveContext:NO];
    
    // uploadedSweetSpots save
    [_sweetSpotServerIO storeUploadedSweetSpotsDictionary];
    
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

-(void)requestSongIdsFromAlbumWithName:(NSString*)albumName withHandler:(void (^)(NSArray*))songArrayHandler {
    NSArray* theSongs = [_allAlbums objectForKey:albumName];
    songArrayHandler(theSongs);
}

// cdfix
//// Fetch all songs from the given album asynchronously and call the given songArrayHandler block with the result.
//-(void)requestSongsFromAlbumWithName:(NSString*)albumName withHandler:(void (^)(NSArray*))songArrayHandler {
//    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TEOSongData"];
//
//    NSPredicate *thePredicate = [NSPredicate predicateWithFormat:@"album = %@",albumName];
//    [fetch setPredicate:thePredicate];
//    //MARK: cdfix - this won't find anything because the album data et al. is not added to the managed object until come save time.
//    // Doing it this way is also nonperformant since this is being called as the user is scrolling through songs and needs to be
//    // as responsive as possible.
//    // What we should do instead is, in loadURL, build a dictionary of albums where the key is the album name, and the value is
//    // a set of songs (which each have artist(s) associated with them. From here we then simply look up the album and extract the songs in it.
//    // Perform the fetch on the context's own thread to avoid threading problems.
//    [self.TEOmanagedObjectContext performBlock:^{
//        NSError *error = nil;
////        NSLog(@"About to sleep thread: %@",[NSThread currentThread]);
////        [NSThread sleepForTimeInterval:50];
////        return; // wipwip
//        // wipwip This is causing the stutter. Find out how to use a NSFetchedResultsController instead.
//        NSArray* results = [self.TEOmanagedObjectContext executeFetchRequest:fetch error:&error];
////    return; // wipwip
//        songArrayHandler(results);
//
//    }];
//}

/*
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
*/

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
    
    return; // wip return so we don't do any caching.
    
    NSDate* preBuildDate = [NSDate date];
    NSDate* preDate = [NSDate date];
    
    // Extract data from context
//    NSPoint speedVector     = [[cacheContext objectForKey:@"spd"] pointValue];
    NSPoint selectionPos    = [[cacheContext objectForKey:@"pos"] pointValue];
    NSPoint gridDims        = [[cacheContext objectForKey:@"gridDims"] pointValue];

    // Early out for speed scrolling. No point in caching if we're flying by.
    // At some point use this for smarter caching.
//    if (speedVector.y > 2) {
//        NSLog(@">>>>>>>>>>>>>>>>>>>>>");
//        NSLog(@"Speed cutoff enabled.");//wipwip
//        NSLog(@"<<<<<<<<<<<<<<<<<<<<<");
//        return;
//    }
    
    // We've got a new request so cancel all previous queued up requests.
    [urlCachingOpQueue cancelAllOperations];
    
    NSBlockOperation* cacheOp = [[NSBlockOperation alloc] init];
    
    // Weakify the block reference to avoid retain cycles.
    __weak NSBlockOperation* weakCacheOp = cacheOp;

    [weakCacheOp addExecutionBlock:^{
        
    // Make sure we have an inited cache.
    NSMutableSet* wantedCache = [[NSMutableSet alloc] initWithCapacity:25];
    
    NSInteger radius = 2;
        
    for (NSInteger matrixRows=selectionPos.y-radius; matrixRows<=selectionPos.y+radius; matrixRows++) {
        for (NSInteger matrixCols=selectionPos.x-radius; matrixCols<=selectionPos.x+radius; matrixCols++) {
            if ((matrixRows >= 0) && (matrixRows <gridDims.y)) {
                if((matrixCols >=0) && (matrixCols < gridDims.x)) {
                    
                    // skip if this is the selected cell (which is already cached or requested).
                    //wipwip
                    if ((matrixRows == selectionPos.y) && (matrixCols == selectionPos.x))
                        continue;
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
        
    NSDate* postBuildDate = [NSDate date];
    NSLog(@"Building the cache took: %f",[postBuildDate timeIntervalSinceDate:preBuildDate]);
        
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
    
    NSDate* postDate = [NSDate date];
    NSLog(@"caching took: %f",[postDate timeIntervalSinceDate:preDate]);
}

- (void)clearSongCache:(NSArray*)staleSongArray {
    dispatch_async(cacheClearingQueue, ^{
        for (id<SongIDProtocol> songID in staleSongArray) {
            TGSong *aSong = [self songForID:songID];
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
    
    NSLog(@"Wait!");
    [NSThread sleepForTimeInterval:10.0f];
    NSLog(@"Carry on.");
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
            
            // tell the song to load its data asyncronously without requesting a callback on completion.
            [aSong loadTrackDataWithCallBackOnCompletion:NO withStartTime:nil];
            
            //MARK: These two requests really ought to be initiated by the above loadTrackData... call.
            // We should try and get the metadata so it's ready,
            // but not so that songPoolDidLoadDataForSongID gets called for each song.
/* wipwip These are already being called via the above call to loadTrackData...
            [self requestEmbeddedMetadataForSongID:songID withHandler:^(NSDictionary* theData){
                //            NSLog(@"preloadSongArray got data! %@",theData);
            }];

            // We should also initiate the caching of the album art.
            [self requestImageForSongID:songID withHandler:nil];
*/
        }
    
        // Tell the song player to refresh the frameCount of the currently playing song now that
        // the songs have finished caching and we know the lengths.
//        [theSongPlayer refreshPlayingFrameCount];
//    }];
}

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
    
    [self requestSongPlayback:songID withStartTimeInSeconds:aSong.currentSweetSpot makeSweetSpot:NO];
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

    if ( makeSS ) {
        [aSong makeSweetSpotAtTime:time];
    }

    if ([aSong isReadyForPlayback] == YES) {
        [self songReadyForPlayback:aSong atTime:time];
    } else {
        // First cancel any pending requests in the operation queue and then add this.
        // This won't delete them from the queue but it will tell each in turn it has been cancelled.
        [urlLoadingOpQueue cancelAllOperations];
        
        // Then add this new request.
        [urlLoadingOpQueue addOperationWithBlock:^{
            // Asynch'ly start loading the track data for aSong. songReadyForPlayback will be called back when the song is good to go.
            [aSong loadTrackDataWithCallBackOnCompletion:YES withStartTime:time];
        }];
    }
}

/// Setter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (void)setPlayheadPos:(NSNumber *)newPos {
    playheadPos = newPos;
}

/// Getter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (NSNumber *)playheadPos {
    return playheadPos;
}


- (void)playbackSong:(TGSong *)nextSong atTime:(NSNumber*)startTime {
    
    // Between checking and stopping, another thread can modify the currentlyPlayingSong thus causing the song to not be stopped.
    if (currentlyPlayingSong != nextSong) {
        [currentlyPlayingSong playStop];
    }
    
    if (currentlyPlayingSong == nextSong) {
        NSLog(@"currently playing is the same as next song. Early out.");
        return;
    }
    NSAssert(startTime != nil, @"Start time is nil!");
    [nextSong playAtTime:startTime];
    
    if (startTime != nil) {
        currentlyPlayingSong = nextSong;
        
        NSNumber *theSongDuration = [NSNumber numberWithDouble:[currentlyPlayingSong getDuration]];
        [self setValue:theSongDuration forKey:@"currentSongDuration"];

        // Song fingerprints are generated and UUID fetched during idle time in the background.
        // However, if the song about to be played hasn't got a UUID or fingerprint, an async request will be initiated here.
        if (nextSong.uuid == NULL) {
            [self fetchUUIdForSongId:nextSong.songID];
            /*
            if ([nextSong fingerPrintStatus] == kFingerPrintStatusEmpty) {
                [nextSong setFingerPrintStatus:kFingerPrintStatusRequested];
                
                NSLog(@"playbacksong calling requestFingerPrintForSong");
                [songFingerPrinter requestFingerPrintForSong:nextSong.songID withHandler:^(NSString* fingerPrint){
                    if (fingerPrint == nil) {
                        NSLog(@"requestFingerprintForSong ERROR: NO FINGERPRINT");
                        return;
                    }
                    [self fingerprintReady:fingerPrint forSongID:nextSong.songID];
                }];
            }
             */
        }

        //MARK: consider using an event to signal this instead.
        // Inform the delegate that we've started playing the song.
        if ([_delegate respondsToSelector:@selector(songPoolDidStartPlayingSong:)]) {
            [_delegate songPoolDidStartPlayingSong:[nextSong songID]];
        }

        // Set the requested playheadposition tracker to the song's start time in a KVC compliant fashion.
        [self setRequestedPlayheadPosition:startTime];
    }
}

/**
 Called by the fingerprinter when a fingerprint is ready.
 Would perhaps be better as an event ?
 */
- (void)fingerprintReady:(NSString *)fingerPrint forSongID:(id<SongIDProtocol>)songID {
    
    TGSong* song = [self songForID:songID];
    
    // At this point we should check if the fingerprint resulted in a songUUID.
    // If it did not we keep the finger print so we don't have to re-generate it, otherwise we can delete the it.
    if (song.uuid == nil) {
        NSLog(@"No UUID found, keeping fingerprint.");
        song.fingerprint = fingerPrint;
    }
    
    [song setFingerPrintStatus:kFingerPrintStatusDone];
}

#pragma mark -
#pragma mark Delegate Methods

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

/**
 Delegate method that allows a song to set the songpool's playhead position tracker variable.
 Because the playheadPosition is bound to the TGTimelineSliderCell's currentPlayheadPositionInPercent this moves the slider knob.
 */
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition {
    [self setValue:playheadPosition forKey:@"playheadPos"];
}

// songReadyForPlayback is called (async'ly) by the song once it is fully loaded.
- (void)songReadyForPlayback:(TGSong *)song atTime:(NSNumber*)startTime {

//     If there's no start time, check the sweet spot server for one. If one is found set the startTime to it.
    if (startTime == nil) {
        startTime = [self fetchSongSweetSpot:song];
        if (startTime == nil) {
            startTime = [NSNumber numberWithDouble:0.0];
        }
        
        
        //MARK: NEXT
//        // Fetch the song's sweet spots and pass a handler that will play back the song at the sweet spot if one is found.
//        [self fetchSongSweetSpot:song withHandler:^(NSNumber* theSweetSpot) {
//            // wip, this just repeats the stuff below.
//            if (song == lastRequestedSong) {
//                dispatch_async(playbackQueue, ^{
//                    [self playbackSong:song atTime:theSweetSpot];
//                });
//            }
//        }];
    }
    
    // Make sure the last request for playback is put on a serial queue so it always is the last song left playing.
    if (song == lastRequestedSong) {
        dispatch_async(playbackQueue, ^{
//            NSLog(@"putting song %lu on the playbackQueue",(unsigned long)[song songID]);
            [self playbackSong:song atTime:startTime];
        });
    }
}


@end
