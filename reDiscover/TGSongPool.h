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

// class forward declaration


@class TGSong;

@class TGFingerPrinter;

//@class SongPlayer;
@class CoverArtArchiveWebFetcher;
@class TGStack;
@class AVAudioFile;
@class SweetSpotServerIO;
@class TGSongAudioCacher;
@class TGSongAudioPlayer;
//@class SongArtCache;
//@class UUIDMaker;

// protocol forward declaration
@protocol SongGridAccessProtocol;
@protocol TGMainViewControllerDelegate;
@protocol TGSong;
/**
*   A SongID must conform to the SongIDProtocol.
*   To conform to the SongIDProtocol a class must also adopt the NSCopying.
 */
@protocol SongIDProtocol <NSObject, NSCopying>
@property NSUInteger idValue;
- (BOOL)isEqual:(id)object;
- (id)copyWithZone:(struct _NSZone *)zone;
@property (readonly) NSUInteger hash;
@end

/**
 The SongID is the type that identifies a song in the current instance of the application.
 SongIDs do not persist across instances.
 */
@interface SongID : NSObject <SongIDProtocol>
@property NSUInteger idValue;
+ (instancetype)initWithString:(NSString *)theString;
- (id)copyWithZone:(struct _NSZone *)zone;
@end



// Methods that SongPool implements for others to call.
@protocol SongPoolAccessProtocol
//MARK: REFAC - added to give TGMainViewController access.
-(id<TGSong>)songForID:(id<SongIDProtocol>)songID;

- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID;
- (NSString*)UUIDStringForSongID:(id<SongIDProtocol>)songID;
- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID;
- (NSString*)albumForSongID:(id<SongIDProtocol>)songID;
//- (AVAudioFile*)cachedAudioFileForSongID:(id<SongIDProtocol>)songID;
//- (NSNumber*)cachedLengthForSongID:(id<SongIDProtocol>)songID;

- (void)requestSongPlayback:(id<SongIDProtocol>)songID;
- (void)requestSongPlayback:(id<SongIDProtocol>)songID
     withStartTimeInSeconds:(NSNumber *)time
             makeSweetSpot:(BOOL)makeSS;

- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID;
- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID;
//- (void)setSongDuration:(NSNumber*)duration forSongId:(id<SongIDProtocol>)songId;

- (id<SongIDProtocol>)lastRequestedSongID;
- (id<SongIDProtocol>)currentlyPlayingSongID;

- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition;
//- (void)setRequestedPlayheadPosition:(NSNumber*)newPosition forSongID:(id<SongIDProtocol>)songID;

// Sweet Spot accessors.
- (NSArray*)sweetSpotsForSongID:(id<SongIDProtocol>)songID;
- (void)replaceSweetSpots:(NSArray*)sweetSpots forSongID:(id<SongIDProtocol>)songID;
- (void)setActiveSweetSpotIndex:(int)ssIndex forSongID:(id<SongIDProtocol>)songID;

- (void)cacheWithContext:(NSDictionary*)cacheContext;
//- (void)newCacheFromCache:(NSMutableSet*)oldCache withContext:(NSDictionary*)cacheContext andHandler:(void (^)(NSMutableSet*))newCacheHandler;

- (NSManagedObjectContext*)TEOSongDataMOC;

// Get the song Id of the the song at the grid position (request goes through to the song grid controller)
- (id<SongIDProtocol>)songIdFromGridPos:(NSPoint)gridPosition;

// Debug methods
- (void)debugLogSongWithId:(id<SongIDProtocol>)songId;
- (void)debugLogCaches;
@end



// TGSongPool Delegate methods that conforming classes must implement and that SongPool will call.
@protocol TGSongPoolDelegate <NSObject>
//@optional
- (void)songPoolDidLoadSongURLWithID:(id<SongIDProtocol>)songID;
- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs;
- (void)songPoolDidStartFetchingSong:(id<SongIDProtocol>)songID;
- (void)songPoolDidStartPlayingSong:(id<SongIDProtocol>)songID;
- (void)songPoolDidFinishPlayingSong:(id<SongIDProtocol>)songID;
- (void)songPoolDidLoadDataForSongID:(id<SongIDProtocol>)songID;
//- (void)setDebugCachedFlagsForSongIDArray:(NSArray*)songIDs toValue:(BOOL)value;
@end

// The public interface declaration doesn't implement the TGSongDelegate. The private interface declaration in the .m will.
//@interface TGSongPool : NSObject <TGPlaylistViewControllerDelegate, SongPoolAccessProtocol>
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
    NSMutableArray* cacheQueue;
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
    dispatch_queue_t songLoadUnloadQueue;
    
    dispatch_queue_t playbackQueue;
    dispatch_queue_t serialDataLoad;
    dispatch_queue_t timelineUpdateQueue;
    
    NSUInteger songPoolStartCapacity;
    NSMutableDictionary *songPoolDictionary;
    id<TGSong> currentlyPlayingSong;
    id<TGSong> lastRequestedSong;

    int32_t srCounter;
    
    TGFingerPrinter *songFingerPrinter;
//    UUIDMaker *songUUIDMaker;
//    SongArtCache* artCache;
    
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
- (id<SongIDProtocol>)initWithURL:(NSURL*) theURL;
- (BOOL)validateURL:(NSURL *)anURL;
- (BOOL)loadFromURL:(NSURL *)anURL ;

//- (void)requestImageForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage *))imageHandler;

//MARK: Song data accessor methods. -
// Async methods
//- (void)requestEmbeddedMetadataForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSDictionary*))dataHandler;

- (void)storeSweetSpotForSongID:(id<SongIDProtocol>)songID;

// UUID accessors.
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID;

// URL accessors.
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;

// Releases accessors TEO switch to use NSArray/NSSet in the managedobject same as the sweetspots
- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID;
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;

- (NSString*)albumForSongID:(id<SongIDProtocol>)songID;
- (NSString*)artIdForSongId:(id<SongIDProtocol>)songId;

// TEO should this not be private?
//- (NSString *)findUUIDOfSongWithURL:(NSURL *)songURL;
- (BOOL)fingerprintExistsForSongID:(id<SongIDProtocol>)songID;

//MARK: Core Data methods -
// Core Data methods
- (void)storeSongData;
- (NSArray *)fetchMetadataFromLocalStore;
- (BOOL)loadMetadataIntoSong:(id<TGSong>)aSong;

// Other protocols' delegate methods that TGSongPool implements
// TGSongDelegate protocol methods called by TGSong
- (void)songDidFinishPlayback:(id<TGSong>)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
//- (void)songReadyForPlayback:(TGSong *)song atTime:(NSNumber*)startTime;
//- (NSSet*)currentCache;

//MARK: Test methods
- (void)testUploadSSForSongID:(id<SongIDProtocol>)theID;

@end


