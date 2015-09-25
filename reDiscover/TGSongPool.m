//
//  TGSongPool.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

//#import "TGSongPool.h"
#import "TGSongGridViewController.h"
#import "TGMainViewController.h"

#import "TGFingerPrinter.h"

#import "TGSongUserData.h"
#import "TEOSongData.h"

#import "UploadedSSData.h"
//#import "NSImage+TGHashId.h"

#import "rediscover-swift.h"
#import "TGSongPool.h"
// The private interface declaration overrides the public one to declare conformity to the Delegate protocols.
//@interface TGSongPool () <TGFingerPrinterDelegate, SongPoolAccessProtocol>
@interface TGSongPool () <SongPoolAccessProtocol>
@end

// constant definitions
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
        currentlyPlayingSongId = NULL;
        
        /// Make url queues and make them serial so they can be cancelled.
        urlLoadingOpQueue = [[NSOperationQueue alloc] init];
        [urlLoadingOpQueue setMaxConcurrentOperationCount:1];
        urlCachingOpQueue = [[NSOperationQueue alloc] init];
        [urlCachingOpQueue setMaxConcurrentOperationCount:1];
        
        // Actual serial queues.
        playbackQueue = dispatch_queue_create("playback queue", NULL);
        serialDataLoad = dispatch_queue_create("serial data load queue", NULL);
        timelineUpdateQueue = dispatch_queue_create("timeline GUI updater queue", NULL);
        
        
        //[self initBasicCovers];
        
        // Create and hook up the song fingerprinter.
//        songFingerPrinter = [[TGFingerPrinter alloc] init];
//        [songFingerPrinter setDelegate:self];
        
//        songUUIDMaker = [[UUIDMaker alloc] init];
//        artCache = [[SongArtCache alloc] init];
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
/* REFAC
        // Register to be notified of idle time starting and ending.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeBegins) name:@"TGIdleTimeBegins" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleTimeEnds) name:@"TGIdleTimeEnds" object:nil];
*/
        //FIXME: Change the delegate to actually passing the artForSong method the required params.
        [SongPool setDelegate:self];

        songAudioPlayer = [[TGSongAudioPlayer alloc] init];
        [songAudioPlayer setVolume:0.2];
        
        /// Make sure the SongPool is set up with various instances
        [SongPool setVarious:[[TGFingerPrinter alloc] init] audioPlayer:songAudioPlayer];
        
        
        //albumCollection = [[AlbumCollection alloc] init];
        
        /// The CoverArtArchiveWebFetcher handles all comms with the remote cover art archive.
//MARK: REFAC
//        _coverArtWebFetcher = [[CoverArtArchiveWebFetcher alloc] init];
//        _coverArtWebFetcher.delegate = self;
        
        // Set up TEOSongData
        [self setupManagedObjectContext];
        
        // The sweetSpotServerIO object handles all comms with the remote sweet spot server.
        _sweetSpotServerIO = [[SweetSpotServerIO alloc] init];
        //_sweetSpotServerIO.delegate = self;
                
        // Starting off with an empty songID cache.
        songIDCache = [[NSMutableSet alloc] init];
        songLoadUnloadQueue = dispatch_queue_create("song load unload q", NULL);
        
        songPoolQueue = dispatch_queue_create("songPool dictionary access q", DISPATCH_QUEUE_SERIAL);
        
        // Register to be notified of song uuid being fetched
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFetchedUUId:) name:@"TGUUIdWasFetched" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songCoverWasFetched:) name:@"webSongCoverFetcherDidFetch" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songIsReadyForPlayback:) name:@"songStatusNowReady" object:nil];
        
        //CACH2 start the cachequeue off with an empty cache
        selectedSongsCache = [[NSMutableSet alloc] init];
        
        cacheQueueLock = [[NSLock alloc] init];
        callbackQueueLock = [[NSLock alloc] init];
        selectedSongsCacheLock = [[NSLock alloc] init];
        
//        cacheQueue = [[NSMutableArray alloc] init];
//        [cacheQueue enqueue:[NSMutableSet setWithCapacity:0]];
        callbackQueue = [[NSMutableArray alloc] init];
        
        //NUCACHE
        songAudioCacher = [[TGSongAudioCacher alloc] init];
        songAudioCacher.songPoolAPI = self;
        
//        songAudioPlayer = [[TGSongAudioPlayer alloc] init];
//        [songAudioPlayer setVolume:0.2];
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
        TGLog(TGLOG_ALL,@"Error: %@",error);
    }
    TGLog(TGLOG_ALL,@"setupManagedObjectContext done");
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
            TGLog(TGLOG_ALL,@"Error while fetching TEOSongData.\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
            return;
        }
        
        // Then traverse the fetched Array and make a dictionary with the url field as the key.
        NSMutableDictionary* tmpDictionary = [[NSMutableDictionary alloc] init];
        
        for (TEOSongData* songData in fetchedArray) {
            [tmpDictionary setObject:songData forKey:songData.urlString];
        }
        
        self.TEOSongDataDictionary = tmpDictionary;
        TGLog(TGLOG_ALL,@"initTEOSongDataDictionary done");
    }];
}
// END TEOSongData test

//- (void)idleTimeEnds {
////    TGLog(TGLOG_ALL,@"song pool idle end");
//    
//    // Stop the fingerprinter.
//    [idleTimeFingerprinterTimer invalidate];
//}


// Traverse the passed in URL, find all music files and load their URLs into a dictionary.
// returns true if the given url is valid and, if so, will initiate the loading of songs.
- (BOOL)loadFromURL:(NSURL *)anURL {
    //NSDictionary *allSongs =
    dispatch_async(serialDataLoad, ^{
        [SongPool fillSongPoolWithSongURLsAtURL:anURL];

    });
    return YES;
    
//    // init status.
//    allURLsRequested = NO;
//    allURLsLoaded = NO;
//    errorLoadingSongURLs = NO;
//    __block int requestedOps = 0;
//    __block int completedOps = 0;
//    opQueue = [[NSOperationQueue alloc] init];
//    
//    TGLog(TGLOG_ALL,@"loadFromURL running on the main thread? %@",[NSThread isMainThread]?@"Yep":@"Nope");
//    
////    NSFileManager *fileManager = [[NSFileManager alloc] init];
//    
//    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
//    
////    NSTimeInterval timerStart = [NSDate timeIntervalSinceReferenceDate];
//
//    // At this point, to avoid blocking with a beach ball on big resources/slow access, we drop this part into a concurrent queue.
//    NSOperationQueue *topQueue = [[NSOperationQueue alloc] init];
//    NSBlockOperation *topOp = [NSBlockOperation blockOperationWithBlock:^{
//        
//        // The enumerator does a deep traversal of the given url.
//        NSDirectoryEnumerator *enumerator = [self.sharedFileManager
//                                             enumeratorAtURL:anURL
//                                             includingPropertiesForKeys:keys
//                                             options:0
//                                             errorHandler:^(NSURL *url, NSError *error) {
//                                                 // Handle the error.
//                                                 // Return YES if the enumeration should continue after the error.
//                                                 TGLog(TGLOG_ALL,@"Error getting the directory. %@",error);
//                                                 // Return yes to continue traversing.
//                                                 return YES;
//                                             }];
//        
//        for (NSURL *url in enumerator) {
//            
//            // Increment counter to track number of requested load operations.
//            requestedOps++;
//            
//            // Each block checks a url.
//            NSBlockOperation *theOp = [NSBlockOperation blockOperationWithBlock:^{
//                NSError *error;
//                NSNumber *isDirectory = nil;
//
//                if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
//                    // handle error
//                    TGLog(TGLOG_ALL,@"An error %@ occurred in the enumeration.",error);
//                    errorLoadingSongURLs = YES;
//                    
//                    // TEO: handle error by making another delegate method that signals failure.
//                    return;
//                }
//                
//                if (! [isDirectory boolValue]) {
//                    // No error and it’s not a directory; do something with the file
//                    
//                    // Check the file extension and deal only with audio files.
//                    CFStringRef fileExtension = (__bridge CFStringRef) [url pathExtension];
//                    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
//                    
//                    if (UTTypeConformsTo(fileUTI, kUTTypeAudio))
//                    {
//                        // Create a song object with the given url. This does not start loading it from disk.
//                        //TGSong *newSong = [[TGSong alloc] init];
//                        
//                        // Set the song pool to be a song's delegate.
//                        //[newSong setDelegate:self];
//                        // Set the song's song pool API in a move away from using delegates for everything... wip
//                        //[newSong setSongPoolAPI:self];
//                        
//                        //CDFIX
//                        // Set the song cover image id to the default (empty).
//                        //newSong.artID = nil;//_defaultCoverArtHashId;
//                        
//                        // The song id is assigned.
//                        //[newSong setSongID:[SongID initWithString:[url absoluteString]]];
//
//                        NSAssert(serialDataLoad != nil, @"WTF serialDataLoad is nil!");
//                        dispatch_async(serialDataLoad, ^{
//                            
//                            // cdfix This should no longer hook up the song to a managed object but instead
//                            // it should copy the data across and let the array go. We do not want to have to access
//                            // the properties through a managed context as that requires us to go through its thread
//                            // which can deadlock/delay on concurrent access.
//                            
//                            
//                            TEOSongData* teoData = [self.TEOSongDataDictionary objectForKey:[url absoluteString]];
//                            //FIXME: Why does this not crash when teoData is nil?
//                            SongCommonMetaData* metadata = [[SongCommonMetaData alloc] initWithTitle:teoData.title
//                                                                                   album:teoData.album
//                                                                                  artist:teoData.artist
//                                                                                    year:[teoData.year unsignedIntegerValue]
//                                                                                   genre:teoData.genre];
//                            
//                            id<SongIDProtocol> songId = [[SongID alloc] initWithString:[url absoluteString]];
//                            
//                            id<TGSong>newSong = [[Song alloc]initWithSongId:songId
//                                                    metadata: metadata
//                                                   urlString: [url absoluteString]
//                                                  sweetSpots: teoData.sweetSpots
//                                                 fingerPrint: teoData.fingerprint
//                                                  selectedSS: [teoData.selectedSweetSpot floatValue]
//                                                    releases: teoData.songReleases
//                                                       artId: @""
//                                                        UUId: nil
//                                                        RelId: nil];
//                            // cdfix
//                            //[self copyData:teoData toSong:newSong forURL:[url absoluteString]];
// 
//                       /*
//                            // Only add the loaded url if it isn't already in the dictionary.
//                            if (!teoData) {
//                                // this needs to happen on the managed object context's own thread
//                                [self.TEOmanagedObjectContext performBlock:^{
//                                    newSong.TEOData = [TEOSongData insertItemWithURLString:[url absoluteString] inManagedObjectContext:self.TEOmanagedObjectContext];
//                                }];
//                                
//                                [[NSNotificationCenter defaultCenter] postNotificationName:@"TGNewSongLoaded" object:newSong];
//                            } else {
//                                // At this point we have found the song in the local store so we hook it up to the song instance for this run.
//                                newSong.TEOData = teoData;
//                            }
//                         */
//                            // Add the song to the songpool.
//                            [songPoolDictionary setObject:newSong forKey:newSong.songID];
//                            
//                            
//                            // Upload any sweetspots that have not already been uploaded.
//                            if (newSong.sweetSpots.count) {
//                                [_sweetSpotServerIO uploadSweetSpotsForSongID:newSong.songID];
//                            }
//                  
//                        });
//                        
//                        // Inform the delegate that another song object has been loaded. This causes a cell in the song matrix to be added.
//                        if ((_delegate != Nil) && [_delegate respondsToSelector:@selector(songPoolDidLoadSongURLWithID:)]) {
//                            [_delegate songPoolDidLoadSongURLWithID:[[SongID alloc] initWithString:[url absoluteString]]];
//                        }
//                    }
//                }
//            }];
//            
//            [theOp setCompletionBlock:^{
//                
//                // Atomically increment the counter to track completed operations.
//                OSAtomicIncrement32(&completedOps);
//                
//                // If we're done requesting new urls and
//                // the number of completed operations is the same as the requested operations then
//                // signal that we're done loading and signal our delegate that we're all done.
//                if (allURLsRequested) {
//                    if ( completedOps == requestedOps) {
//                        // At this point we know how many songs to display.
//                        
//                        // Inform the delegate that we've loaded the all the URLs.
//                        if ([_delegate respondsToSelector:@selector(songPoolDidLoadAllURLs:)]) {
//                                [_delegate songPoolDidLoadAllURLs:loadedURLs];
//                        }
//                        allURLsLoaded = YES;
//                        
//                        
//                        // At this point we start assigning unmapped songs to a position in the grid.
//                    }
//                }
//            }];
//            
//            [opQueue addOperation:theOp];
//        }
//    }];
//
//    [topOp setCompletionBlock:^{
//        allURLsRequested = YES;
//    }];
//
//    [topQueue addOperation:topOp];
//    
//    return YES;
}

- (NSString*)artIdForSongId:(id<SongIDProtocol>)songId {
    return [[self songForID:songId] artID];
}


//MARK: CDFIX - observer methods
- (void)songCoverWasFetched:(NSNotification*)notification {
    TGSong* song = (TGSong*)notification.object;
    TGLog(TGLOG_ALL,@"songCoverWasFetched with %@",song);
}


- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID {
    CMTime songDuration = [songAudioPlayer songDuration];
    float secs = CMTimeGetSeconds(songDuration);
//    float secs = CMTimeGetSeconds([[self songForID:songID] songDuration]);
    return [NSNumber numberWithDouble:secs];
}

- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID {
    id<TGSong> aSong = [self songForID:songID];
    
    if (aSong) {
        return [NSURL URLWithString:[self songForID:songID].urlString];
    }
    
    return nil;
}


- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID {
    id<TGSong> song = [self songForID:songID];
    
    return @{@"Id": songID,
             @"Artist": song.metadata.artist,
             @"Title": song.metadata.title,
             @"Album": song.metadata.album,
             @"Genre": song.metadata.genre};
}


- (BOOL)validSongID:(id<SongIDProtocol>)songID {
    // TEO: also check for top bound.
    if (songID == nil) return NO;

    return YES;
}


- (void)setActiveSweetSpotIndex:(int)ssIndex forSongID:(id<SongIDProtocol>)songID {

    id<TGSong> theSong = [self songForID:songID];

//    if (theSong == nil || theSong.TEOData == nil || theSong.sweetSpots == nil) {
    if (theSong == nil || theSong.sweetSpots == nil) {
        TGLog(TGLOG_ALL,@"setActiveSweetSpotIndex ERROR: unexpected nil");
        return;
    }
    
    if (ssIndex >= 0 && ssIndex < theSong.sweetSpots.count ) {
        //MARK: REFAC
        //[theSong makeSweetSpotAtTime:theSong.sweetSpots[ssIndex]];
    }
}

//FIXME:
/* REFAC - not duplicated yet
- (void)replaceSweetSpots:(NSArray*)sweetSpots forSongID:(id<SongIDProtocol>)songID {
    id<TGSong> theSong = [self songForID:songID];
    if (theSong == nil) { return; }
    
    //theSong.sweetSpots = sweetSpots;
    id<TGSong> newSong = [[Song alloc] initWithSongId:songID
                                     metadata:theSong.metadata
                                    urlString:theSong.urlString
                                   sweetSpots:sweetSpots
                                  fingerPrint:theSong.fingerPrint
                                   selectedSS:theSong.selectedSweetSpot
                                     releases:theSong.songReleases
                                        artId:theSong.artID
                                         UUId:theSong.UUId
                                        RelId:theSong.RelId];
    // Add the song to the songpool.
    [songPoolDictionary setObject:newSong forKey:newSong.songID];
    
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
*/

//- (NSArray*)sweetSpotsForSongID:(id<SongIDProtocol>)songID {
//    id<TGSong> theSong = [self songForID:songID];
//    if (theSong == nil) { return nil; }
//    
//    return theSong.sweetSpots;
//}


//- (NSSet*)currentCache {
//    return songIDCache;
//}

//- (NSNumber*)cachedLengthForSongID:(id<SongIDProtocol>)songID {
//    return [NSNumber numberWithLongLong:[self songForID:songID].cachedFileLength];
//}

//- (AVAudioFile*)cachedAudioFileForSongID:(id<SongIDProtocol>)songID {
//    return [self songForID:songID].cachedFile;
//}

- (NSString*)albumForSongID:(id<SongIDProtocol>)songID {
        return [self songForID:songID].metadata.album;
}

- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID {
    return [self songForID:songID].songReleases;
}

/*
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID {
    id<TGSong> theSong = [self songForID:songID];
    if (theSong == nil) { return; }
    
    //theSong.sweetSpots = sweetSpots;
    id<TGSong> newSong = [[Song alloc] initWithSongId:songID
                                     metadata:theSong.metadata
                                    urlString:theSong.urlString
                                   sweetSpots:theSong.sweetSpots
                                  fingerPrint:theSong.fingerPrint
                                   selectedSS:theSong.selectedSweetSpot
                                     releases:releases
                                        artId:theSong.artID
                                         UUId:theSong.UUId
                                        RelId:theSong.RelId];
    
    // replace old song with the new song in the songpool.
    [songPoolDictionary setObject:newSong forKey:newSong.songID];

//    [self songForID:songID].songReleases = releases;
}
*/

- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    return [SongUUID getUUIDForSong:[self songForID:songID]];
//    return [self songForID:songID].uuid;
}

/*
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return;
    
    id<TGSong> newSong = [SongUUID songWithNewUUId:[self songForID:songID] newUUId:theUUID newReleaseId:nil];
    // replace old song with the new song in the songpool.
    [songPoolDictionary setObject:newSong forKey:newSong.songID];
    
    //[self songForID:songID].uuid = theUUID ;
//    TGSong* theSong = [self songForID:songID];
//    theSong.fingerprint = nil;
    
    // With an UUId (re)try to fetch the sweet spots from the server.
    [self fetchSongSweetSpot:newSong];

}
*/
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return nil;
    
    return [NSURL URLWithString:[self songForID:songID].urlString];
}

//MARK: test method

- (BOOL)fingerprintExistsForSongID:(id<SongIDProtocol>)songID {
    if (![self validSongID:songID]) return NO;
    
    return [self songForID:songID].fingerPrint != nil;
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
- (NSNumber *)fetchSongSweetSpot:(id<TGSong>)song {
//- (NSNumber *)fetchSongSweetSpot:(TGSong *)song withHandler:(void (^)(NSNumber*))sweetSpotHandler {
    // Get the song's start time in seconds.
//    NSNumber *startTime = [song startTime];
    //MARK: REFAC
//    NSNumber *startTime = [NSNumber numberWithFloat:[SweetSpotControl selectedSweetSpotForSong:song]];
        NSNumber *startTime = [SweetSpotController selectedSweetSpotForSong:song];
    /// Request sweetspots from the sweetspot server if the song does not have a start time, has a uuid and has not
    /// exceeded its alotted queries.

    //FIXME:
    /// Don't use the ssCheckCountdown. Only check sweetspots on app start and only for songs that don't already have any.
    /// A manual refresh would be the way to force a check.
    /// Also, if there's no uuid, should we send off for fingerprinting and uuid lookup or should this occur higher up the stack
    /// and the check for uuid should opt out sooner...
    
    /* REFAC */
    if (startTime == nil) {// && (song.uuid != nil) && (song.SSCheckCountdown-- == 0)) {
        // Reset the counter.
//        song.SSCheckCountdown = (NSUInteger)kSSCheckCounterSize;
        TGLog(TGLOG_REFAC, @"song: %@ has uuid %@",song.songID,song.UUId);
        //FIXME: REFAC This really ought to get called as soon as the song uuid is made.
        [_sweetSpotServerIO requestSweetSpotsForSongID:song.songID];
    }
    //*/
    
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
- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition {
    
    requestedPlayheadPosition = newPosition;
    // Set the current playback time and the currently selected sweet spot to the new position.
    [songAudioPlayer setCurrentPlayTime:[newPosition doubleValue]];
}


// FIXME:
// lastRequestedSongId and currentlyPlayingSongId should be asking the song player for that info and not
// keep it in the song pool.
- (id<SongIDProtocol>)lastRequestedSongId {
    return lastRequestedSongId;
}

- (id<SongIDProtocol>)currentlyPlayingSongId {
    return currentlyPlayingSongId;
}

-(id<TGSong>)songForID:(id<SongIDProtocol>)songID {
    return [SongPool songForSongId:songID];
//    return [songPoolDictionary objectForKey:songID];
}

- (dispatch_queue_t)serialQueue {
    return playbackQueue;
}

- (dispatch_queue_t)songLoadUnloadQueue {
    return songLoadUnloadQueue;
}

- (id<SongIDProtocol>)songIdFromGridPos:(NSPoint)gridPosition {
    //REFAC
    return [_delegate songIdFromGridPos:gridPosition];
    //return [_songGridAccessAPI songIDFromGridColumn:gridPosition.x andRow:gridPosition.y];
}

#pragma mark -
//MARK: Core Data methods
/*
- (NSEntityDescription *)createSongUserDataEntityDescription {
    NSEntityDescription *songUserDataEntityDescription = [[NSEntityDescription alloc] init];
    [songUserDataEntityDescription setName:@"TGSongUserData"];
    [songUserDataEntityDescription setManagedObjectClassName:@"TGSongUserData"];
    
//    TGLog(TGLOG_ALL,@"The songUserData is %@\n",songUserDataEntityDescription);
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
        TGLog(TGLOG_ALL,@"Store Configuration Failed.\n%@",([error localizedDescription] != nil) ?
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
            TGLog(TGLOG_ALL,@"Could not access the Library directory\n%@",[error localizedDescription]);
        }
        else {
            songUserDataDirectory = [libraryURL URLByAppendingPathComponent:@"ProjectX"];
            songUserDataDirectory = [songUserDataDirectory URLByAppendingPathComponent:@"songUserData"];
            
            NSDictionary *properties = [songUserDataDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
            
            if (properties == nil) {
                if (![fileManager createDirectoryAtURL:songUserDataDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
                    TGLog(TGLOG_ALL,@"Could not create directory %@\n%@",[songUserDataDirectory path], [error localizedDescription]);
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

/* REFAC - not duplicated yet
- (void)storeSweetSpotForSongID:(id<SongIDProtocol>)songID {
    //TGSong *tmpSong = [self songForID:songID];
    //MARK: REFAC
    id<TGSong> tmpSong = [self songForID:songID];
    //[tmpSong storeSelectedSweetSpot];
    tmpSong = [SweetSpotControl songWithAddedSweetSpot:tmpSong withSweetSpot:[SweetSpotControl selectedSweetSpotForSong:tmpSong]];
    [songPoolDictionary setObject:tmpSong forKey:tmpSong.songID];
}
*/

// Currently only called manually by pressing the s key.
// Go through all songs and store those who have had data added to them.
// This includes UUID or a user selected sweet spot.
- (void)storeSongData {
    // REFAC
    [SongPool save:songPoolDictionary];
    
    // TEOSongData test
    [self saveContext:NO];
    
    // uploadedSweetSpots save
    [_sweetSpotServerIO storeUploadedSweetSpotsDictionary];
    
    return;
}

/*
// Fetch the whole song user data from the store to the persistent store coordinator.
// Presumably (but to be checked) this is faster than (in loadMetadataIntoSong) calling individual fetchrequests with predicates.
- (NSArray *)fetchMetadataFromLocalStore {
    
    NSFetchRequest *songUserDataFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TGSongUserData"];
    NSError *error = nil;
    static NSArray *fetchedArray = nil;
    
    if (fetchedArray == nil) {
        fetchedArray = [songPoolManagedContext executeFetchRequest:songUserDataFetchRequest error:&error];
        if (error != nil) {
            TGLog(TGLOG_ALL,@"Error while fetching songUserData.\n%@",
                  ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown error..");
            return nil;
        }
    }
    return fetchedArray;
}
*/

//- (BOOL)loadMetadataIntoSong:(TGSong *)aSong {
//    return YES;
//}

//-(void)requestSongIdsFromAlbumWithName:(NSString*)albumName withHandler:(void (^)(NSArray*))songArrayHandler {
//    NSArray* theSongs = [_allAlbums objectForKey:albumName];
//    songArrayHandler(theSongs);
//}

#pragma mark -
// end of Core Data methods


#pragma mark Caching methods

/** Caching entrypoint.
    This method is called with a cache context that defines the position and speed of the selection and
    is used to determine the optimal caching strategy.
     
    The method is called on a collectionAccessQ so we need to be sure that this
    cannot get called multiple times concurrently as that would mess up the SongPool
    requestUpdatedDataForSongId.
*/
static bool debugConcurrentCheck = false;

- (void)cacheWithContext:(id<SongSelectionContext>)cacheContext {

    NSAssert(debugConcurrentCheck == false, @"Called before done!");
    debugConcurrentCheck = YES;
    
    [songAudioCacher cacheWithContext:cacheContext];

    id<SongIDProtocol> selectedSongId = cacheContext.selectedSongId;
    lastRequestedSongId = selectedSongId;
    
    // Tell the main view controller that we've started fetching data for the selected song so it can update the UI.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"songDidStartUpdating" object:selectedSongId];
    // Initiate the fingerprint/UUId generation and fetching of cover art.
    // Split this into synchronous functions called on a single separate thread:
    // 1) Get fingerprint for the song unless already there.
    // TGFingerprinter fingerprintForSong
    // 2) Get UUId from fingerprint unless already there.
    // UUIDForSong
    // 3) Get Cover Art from UUId unless already there.
    //
    // 4) Notify all done.

    /** Move this to an operation queue so we can cancel these as new requests arrive.
     */
    [SongPool requestUpdatedDataForSongId:selectedSongId];
    debugConcurrentCheck = NO;
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
//        /** Consider wrapping each of these calls in nsoperations with each being dependent on
//         the success of the previous operation. Specifically, most of these rely on
//         the song having been fingerprinted which cannot happen until the song has
//         been loaded/cached.
//        */
//
//        [SongPool updateMetadataForSongId:selectedSongId];
//        /** The fingerprinter and subsequent functions are dependent on the audio
//        being fully loaded. We should add that dependency. */
//        [SongPool updateFingerPrintForSongId: selectedSongId withFingerPrinter: songFingerPrinter];
//        [SongPool updateRemoteDataForSongId:selectedSongId withDuration:[songAudioPlayer songDuration]];
//        albumCollection = [AlbumCollection updateWithAlbumContainingSongId:selectedSongId usingOldCollection:albumCollection];
//        [SongPool checkForArtForSongId:selectedSongId inAlbumCollection:albumCollection];
//    });
    
}

/**
 Initiate a request to play back the given song at its selected sweet spot.
 If no selected sweet spot exists, check to see if the song has any stored sweet 
 spots and pick the first one. If none exist just play the song from the start.
 :params: songID The id of the song to play.
*/
/**- (void)requestSongPlayback:(id<SongIDProtocol>)songID {
    id<TGSong> aSong = [self songForID:songID];
    if (aSong == nil) {
        TGLog(TGLOG_REFAC, @"requestSongPlayback - no song found.");
        return;
    }
    
    NSNumber *startTime = [SweetSpotController selectedSweetSpotForSong:aSong];
    [self requestSongPlayback:songID withStartTimeInSeconds:startTime];
}
*/

/**
    Initiate a request to play back the given song at the given start time in seconds.
 This is called on the main thread for serial access to the lastRequestedSong property.
 
 :params: songID The id of the song to play.
 :params: time The offset in seconds to start playing the song at.
 */
- (void)requestSongPlayback:(id<SongIDProtocol>)songID withStartTimeInSeconds:(NSNumber *)time {
    
    id<TGSong> aSong = [self songForID:songID];
    if (aSong == NULL) {
        TGLog(TGLOG_ALL,@"Nope, the requested ID %@ is not in the song pool.",songID);
        return;
    }
    
    lastRequestedSongId = songID;

    //NUCACHE
    [songAudioCacher performWhenPlayerIsAvailableForSongId:songID callBack:^(AVPlayer* thePlayer){
        
        if (songID == lastRequestedSongId) {
            
            //[songAudioPlayer setSongPlayer:thePlayer];
            
            // Start observing the new player.
            [self setSongPlaybackObserver:thePlayer];
            
            id<TGSong> song = [self songForID:songID];

            // If there's no start time, check the sweet spot server for one. If one is found set the startTime to it.
            NSNumber* startTime = time;
            if (startTime == nil) {
                // At this point we really ought to make sure we have a song uuid generated from the fingerprint.
                startTime = [self fetchSongSweetSpot:song];
                if (startTime == nil) {
                    startTime = [NSNumber numberWithDouble:0.0];
                }
            }
        
            [songAudioPlayer playAtTime:[startTime floatValue]];
            currentlyPlayingSongId = songID;
            
            TGLog(TGLOG_TMP, @"currentSongDuration %f",CMTimeGetSeconds([songAudioPlayer songDuration]));
            
            [self setValue:[NSNumber numberWithFloat:CMTimeGetSeconds([songAudioPlayer songDuration])] forKey:@"currentSongDuration"];

            [self setRequestedPlayheadPosition:startTime];
        }
    }];
    //NUCACHE end
}

/// Setter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (void)setPlayheadPos:(NSNumber *)newPos {
    playheadPos = newPos;
}

/// Getter for the playheadPos which is bound to the timeline and the playlist progress bars.
- (NSNumber *)playheadPos {
    return playheadPos;
}


#pragma mark -
#pragma mark Delegate Methods

// TSGSongDelegate methods.
#pragma mark TGSongDelegate methods

- (void)songDidFinishPlayback:(id<TGSong>)song {
    // Pass this on to the delegate (which should be the controller).
    TGLog(TGLOG_ALL,@"song %lu did finish playback. The last requested song is %@",(unsigned long)[song songID],lastRequestedSongId);
//    if ([[self delegate] respondsToSelector:@selector(songPoolDidFinishPlayingSong:)]) {
//        [[self delegate] songPoolDidFinishPlayingSong:[song songID]];
//    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"songDidFinishPlayback" object:[song songID]];
}

- (void)setSongPlaybackObserver:(AVPlayer*)songPlayer {
/* REFACTOR
    // Remove existing observer if there is one.
    AVPlayer* prevPlayer = [songAudioPlayer getPrevSongPlayer];
    if (prevPlayer != nil && _playerTimerObserver != nil) {
        [prevPlayer removeTimeObserver:_playerTimerObserver];
        _playerTimerObserver = nil;
    }
    
    // Add a periodic observer so we can update the timeline GUI.
    CMTime eachSecond = CMTimeMake(10, 100);
    dispatch_queue_t timelineSerialQueue = playbackQueue;

    // Make a weakly retained self and songPlayer for use inside the block to avoid retain cycle.
    __unsafe_unretained typeof(self) weakSelf = self;
    __unsafe_unretained AVPlayer* weakSongPlayer = songPlayer;
    
    // Every 1/10 of a second update the delegate's playhead position variable.
    _playerTimerObserver = [songPlayer addPeriodicTimeObserverForInterval:eachSecond queue:timelineSerialQueue usingBlock:^void(CMTime time) {

        CMTime currentPlaybackTime = [weakSongPlayer currentTime];
        [weakSelf songDidUpdatePlayheadPosition:[NSNumber numberWithDouble:CMTimeGetSeconds(currentPlaybackTime)]];
    }];
 */
//returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...};
    
    // Make a weakly retained self and songPlayer for use inside the block to avoid retain cycle.
    __unsafe_unretained typeof(self) weakSelf = self;
    __unsafe_unretained AVPlayer* weakSongPlayer = songPlayer;

    void (^timerObserverBlock)(CMTime) = ^void(CMTime time) {
        
        CMTime currentPlaybackTime = [weakSongPlayer currentTime];
        [weakSelf songDidUpdatePlayheadPosition:[NSNumber numberWithDouble:CMTimeGetSeconds(currentPlaybackTime)]];
    };
    [songAudioPlayer setSongPlayer:songPlayer block:timerObserverBlock];

}

/**
 Delegate method that allows a song to set the songpool's playhead position tracker variable.
 Because the playheadPosition is bound to the TGTimelineSliderCell's currentPlayheadPositionInPercent this moves the slider knob.
 */
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition {
    [self setValue:playheadPosition forKey:@"playheadPos"];
}

//MARK: Debug methods

- (void)debugLogSongWithId:(id<SongIDProtocol>)songId {
    id<TGSong> theSong = [self songForID:songId];
    TGLog(TGLOG_DBG,@"Debug log for song with id: %@",songId);
    TGLog(TGLOG_DBG,@"vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
    TGLog(TGLOG_DBG,@"List sweetspots for song with Id: %@",songId);
    
//    TGLog(TGLOG_DBG,@"The song status is: %@",[self statusValToString:theSong.songStatus]);
    TGLog(TGLOG_DBG,@"The artId: %@",theSong.artID);
    TGLog(TGLOG_DBG,@"The UUID is %@",[self UUIDStringForSongID:songId]);
    TGLog(TGLOG_DBG,@"The song has a fingerprint: %@",[self fingerprintExistsForSongID:songId]?@"Yes":@"No");
    TGLog(TGLOG_DBG,@"The sweetspots are %@",[SweetSpotController sweetSpotsForSongId:songId]);
    
    TGLog(TGLOG_DBG,@"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    
    //NUCACHE
    [songAudioCacher performWhenPlayerIsAvailableForSongId:songId callBack:^(AVPlayer* thePlayer){
        if (thePlayer != nil) {
            TGLog(TGLOG_DBG, @"songCacher returned %@",thePlayer)
            
        } else {
            TGLog(TGLOG_DBG, @"songCacher returned bummer")
        }
    }];

    //NUCACHE end

}

- (void)debugLogCaches {

    TGLog(TGLOG_DBG,@"The current cache is:");
    TGLog(TGLOG_DBG,@"+---------------------+");
    TGLog(TGLOG_DBG,@"%@",songIDCache);
    TGLog(TGLOG_DBG,@"+---------------------+");
    TGLog(TGLOG_DBG,@"The selectedSongscache is:");
    TGLog(TGLOG_DBG,@"+~~~~~~~~~~~~~~~~~~~~~~+");
    TGLog(TGLOG_DBG,@"%@",selectedSongsCache);
    TGLog(TGLOG_DBG,@"+~~~~~~~~~~~~~~~~~~~~~~+");
    
    TGLog(TGLOG_DBG,@"The callbackQueue count is: %lu",callbackQueue.count);
    
    //FIXME: This may cause an exception because if enumerates the songPoolDictionary whilst it is being changed...
    for (id<SongIDProtocol>aSongId in songPoolDictionary) {
        
//        TGSong* aSong = [self songForID:aSongId];
        
        if ([songIDCache containsObject:aSongId] == NO) {
            TGLog(TGLOG_DBG,@"Song %@ is ready for playback but is not in the cache!",aSongId);
            
            if (![selectedSongsCache containsObject:aSongId]) {
                TGLog(TGLOG_DBG,@"The songId %@ was loaded but not cached AND not in the selectedSongsCache list!",aSongId);
            }
        }
        
//        if (([aSong isReadyForPlayback] == NO) && ([songIDCache containsObject:aSongId] == YES)){
//            TGLog(TGLOG_DBG, @"The songId %@ was incorrectly marked as cached!",aSongId);
//        }
    }
    
    TGLog(TGLOG_DBG,@"+^v^v^v^v^v^v^v^v^v^v^v^v+");
    [songAudioCacher dumpCacheToLog];
    id<TGSong> nowSong = [SongPool songForSongId:currentlyPlayingSongId];
    TGLog(TGLOG_DBG, @"sweetspots for selection id%@ is %@",nowSong.songID,[SweetSpotController sweetSpotsForSong:nowSong]);
}

- (NSString*)statusValToString:(NSUInteger)statusVal {
    switch (statusVal) {
        case 0:
            return @"Loading";
            break;
        case 1:
            return @"Ready";
            break;
        case 2:
            return @"Unloading";
            break;
        case 3:
            return @"Failed";
            break;
        case 4:
            return @"Uninited";
            break;

        default:
            return @"Unknown status";
            break;
    }
}

@end
