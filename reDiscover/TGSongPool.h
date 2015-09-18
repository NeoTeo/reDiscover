//
//  TGSongPool.h
//  Proto3
//
//  The song pool is the model for the collection of songs and handles the loading and caching of songs.
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGPlaylistViewController.h"

#import "NSMutableArray+QueueAdditions.h"

// class forward declarations
@class TGSong;
@class TGFingerPrinter;
@class CoverArtArchiveWebFetcher;
@class TGStack;
@class AVAudioFile;
@class SweetSpotServerIO;
@class TGSongAudioCacher;
@class TGSongAudioPlayer;
@class AlbumCollection;

// protocol forward declaration
@protocol SongGridAccessProtocol;
@protocol TGMainViewControllerDelegate;
@protocol TGSong;
@protocol SongSelectionContext;
@protocol SongPoolAccessProtocol;

// The public interface declaration doesn't implement the TGSongDelegate. The private interface declaration in the .m will.
/**
 The compiler warns that it is not able to find the protocol definition but according
 to [this](http://ipfs.io/ipfs/QmR6JzdNSTtPPzcj91AbAd9q1gxBRL7ACPxtUQgUkW7PCV) 
 Stack Overflow answer there's no way around it.
 */
@interface TGSongPool : NSObject <SongPoolAccessProtocol>
{
    int loadedURLs;
    BOOL errorLoadingSongURLs;
    BOOL allURLsLoaded;
    BOOL allURLsRequested;
    
    /// Concurrent queue used for asynch resource loading.
    NSOperationQueue *opQueue;

    /**
     urlLoadingOpQueue is a concurrent queue set to do at most one concurrent operation at a time
     effectively making it serial. The reason we use an operation queue is that only
     they allow cancellation after being added to the queue.
     */
    NSOperationQueue* urlLoadingOpQueue;
    
    /**
     urlCachingOpQueue is a concurrent queue set to do at most one concurrent operation at a time
     effectively making it serial. The reason we use an operation queue is that only
     they allow cancellation after being added to the queue.
     */
    NSOperationQueue* urlCachingOpQueue;
    
    /** The set that keeps track of the currently cached songs by id */
    NSMutableSet *songIDCache;
    
    /** CACH2 cache of songs that were selected by the user (as opposed to by a caching algo) */
    NSMutableSet* selectedSongsCache;
    /** CACH2 locks to ensure concurrent access to the queues doesn't break */
    NSLock* cacheQueueLock;
    NSLock* callbackQueueLock;
    NSLock* selectedSongsCacheLock;
    
    /** CACH2 a queue of caches */
//    NSMutableArray* cacheQueue;
    /** CACH2 a queue of callback blocks */
    NSMutableArray* callbackQueue;
    
    /** CACH2 not currently necessary.
     A stack of song Ids that have been explicitly selected by the user and are currently fetching.
     This is separate from the songIDCache in that this is not interruptible and is dealt with in a 
     FILO order to ensure responsiveness.
     */
    //NSMutableArray* fetchingSongIds;
    
    /** This serial queue ensures all the cache clearing blocks are performed in the background
    and that they don't clear the same song simultanously. */
    // REFAC
    AlbumCollection *albumCollection;
    dispatch_queue_t songPoolQueue;
    dispatch_queue_t songLoadUnloadQueue;
    dispatch_queue_t playbackQueue;
    dispatch_queue_t serialDataLoad;
    dispatch_queue_t timelineUpdateQueue;
    
    NSUInteger songPoolStartCapacity;
    NSMutableDictionary *songPoolDictionary;
    
    id<SongIDProtocol> currentlyPlayingSongId;
    id<SongIDProtocol> lastRequestedSongId;
    
    int32_t srCounter;
    
    TGFingerPrinter *songFingerPrinter;
    
    NSManagedObjectModel *songUserDataManagedObjectModel;
    NSManagedObjectContext *songPoolManagedContext;
        
    NSTimer *idleTimeFingerprinterTimer;

    /// The playheadPos is bound to the playlist progress indicator value property so that when the song
    /// progresses so does the indicator.
    /// It is also bound, via an object controller, to the popup timeline NSSlider's (timelineBar)
    /// cell's (TGTimelineSliderCell) currentPlayheadPositionInPercent property.
    NSNumber *playheadPos;
    
    /// The requestedPlayheadPosition is bound,via an object controller, to the popup timeline's NSSlider (timelineBar).
    NSNumber *requestedPlayheadPosition;
    
    
    TGSongAudioCacher* songAudioCacher;
    TGSongAudioPlayer* songAudioPlayer;
    
}
@property (strong)id playerTimerObserver;

@property TGStack* requestedSongStack;
@property CoverArtArchiveWebFetcher* coverArtWebFetcher;

@property id<TGMainViewControllerDelegate> delegate;
@property id<SongGridAccessProtocol> songGridAccessAPI;

//// Holds the art associated with the songs. Songs will hold indices into the art array.
//@property NSMutableArray *artArray;
//// Holds the art associated with the songs. Songs will hold indices into the art dictionary.
@property NSMutableDictionary* coverArtById;

// Holds the playhead position of the currently playing song.
@property NSNumber *currentSongDuration;

/// Holds sets of song Ids keyed by album name. So looking up Cobra would return a set of song ids that belong to that album.
@property NSMutableDictionary* allAlbums;


@property NSManagedObjectContext*   privateContext;
@property NSManagedObjectContext*   TEOmanagedObjectContext;
@property NSDictionary*             TEOSongDataDictionary;

@property SweetSpotServerIO* sweetSpotServerIO;

@property NSFileManager*    sharedFileManager;

@property NSString* noCoverArtHashId;
@property NSString* defaultCoverArtHashId;
@property NSString* fetchingCoverArtHashId;

// Methods
/// REFAC start
-(id<TGSong>)songForID:(id<SongIDProtocol>)songID;
- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID;
//- (void)requestSongPlayback:(id<SongIDProtocol>)songID;
- (void)requestSongPlayback:(id<SongIDProtocol>)songID withStartTimeInSeconds:(NSNumber *)time;
- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID;
- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID;


- (void)cacheWithContext:(id<SongSelectionContext>)cacheContext;
- (id<SongIDProtocol>)songIdFromGridPos:(NSPoint)gridPosition;
- (void)debugLogSongWithId:(id<SongIDProtocol>)songId;
- (void)debugLogCaches;
/// REFAC end

- (id<SongIDProtocol>)initWithURL:(NSURL*) theURL;
- (BOOL)validateURL:(NSURL *)anURL;
- (BOOL)loadFromURL:(NSURL *)anURL ;

-(NSNumber *)requestedPlayheadPosition;

//- (void)requestImageForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage *))imageHandler;

//MARK: Song data accessor methods. -
// Async methods
//- (void)requestEmbeddedMetadataForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSDictionary*))dataHandler;
-(id<SongIDProtocol>)currentlyPlayingSongId;
-(id<SongIDProtocol>) lastRequestedSongId;

//- (void)storeSweetSpotForSongID:(id<SongIDProtocol>)songID;

// UUID accessors.
//-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID;

// URL accessors.
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;

// Releases accessors TEO switch to use NSArray/NSSet in the managedobject same as the sweetspots
- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID;
//- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;

- (NSString*)albumForSongID:(id<SongIDProtocol>)songID;
- (NSString*)artIdForSongId:(id<SongIDProtocol>)songId;

// TEO should this not be private?
//- (NSString *)findUUIDOfSongWithURL:(NSURL *)songURL;
- (BOOL)fingerprintExistsForSongID:(id<SongIDProtocol>)songID;

//MARK: Core Data methods -
// Core Data methods
- (void)storeSongData;
//- (NSArray *)fetchMetadataFromLocalStore;
//- (BOOL)loadMetadataIntoSong:(id<TGSong>)aSong;

// Other protocols' delegate methods that TGSongPool implements
// TGSongDelegate protocol methods called by TGSong
- (void)songDidFinishPlayback:(id<TGSong>)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
//- (void)songReadyForPlayback:(TGSong *)song atTime:(NSNumber*)startTime;
//- (NSSet*)currentCache;

//MARK: Test methods
- (void)testUploadSSForSongID:(id<SongIDProtocol>)theID;

@end


