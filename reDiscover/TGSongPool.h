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


// class forward declaration
@class TGSong;
@class TGFingerPrinter;

@class SongPlayer;
@class CoverArtArchiveWebFetcher;
@class TGStack;
@class AVAudioFile;
@class SweetSpotServerIO;

// protocol forward declaration
@protocol SongGridAccessProtocol;
@protocol TGMainViewControllerDelegate;

/**
*   A SongID must conform to the SongIDProtocol.
*   To conform to the SongIDProtocol a class must also adopt the NSCopying.
 */
@protocol SongIDProtocol <NSObject, NSCopying>
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
- (NSURL *)songURLForSongID:(id<SongIDProtocol>)songID;
- (NSString*)UUIDStringForSongID:(id<SongIDProtocol>)songID;
- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID;
- (NSString*)albumForSongID:(id<SongIDProtocol>)songID;
- (AVAudioFile*)cachedAudioFileForSongID:(id<SongIDProtocol>)songID;
- (NSNumber*)cachedLengthForSongID:(id<SongIDProtocol>)songID;

- (void)requestSongPlayback:(id<SongIDProtocol>)songID;
- (void)requestSongPlayback:(id<SongIDProtocol>)songID
     withStartTimeInSeconds:(NSNumber *)time
             makeSweetSpot:(BOOL)makeSS;

- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID;
- (NSNumber *)songDurationForSongID:(id<SongIDProtocol>)songID;
- (id<SongIDProtocol>)lastRequestedSongID;
- (id<SongIDProtocol>)currentlyPlayingSongID;

- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition;
// Sweet Spot accessors.
- (NSArray *)sweetSpotsForSongID:(id<SongIDProtocol>)songID;

- (void)cacheWithContext:(NSDictionary*)cacheContext;

@end

// TGSongPool Delegate methods that conforming classes must implement and that SongPool will call.
@protocol TGSongPoolDelegate <NSObject>
//@optional
- (void)songPoolDidLoadSongURLWithID:(id<SongIDProtocol>)songID;
- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs;
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
    // concurrent queue used for asynch resource loading.
    NSOperationQueue *opQueue;
    
    NSOperationQueue* urlLoadingOpQueue;
    NSOperationQueue* urlCachingOpQueue;
    NSMutableSet *songIDCache;
    
    // This serial queue ensures all the cache clearing blocks are performed in the background.
    dispatch_queue_t cacheClearingQueue;
    
    dispatch_queue_t playbackQueue;
    dispatch_queue_t serialDataLoad;
    dispatch_queue_t timelineUpdateQueue;
    
    NSUInteger songPoolStartCapacity;
    NSMutableDictionary *songPoolDictionary;
    TGSong *currentlyPlayingSong;
    TGSong *lastRequestedSong;
    int32_t srCounter;
    
    TGFingerPrinter *songFingerPrinter;
    
    NSManagedObjectModel *songUserDataManagedObjectModel;
    NSManagedObjectContext *songPoolManagedContext;
    
    // songs added to this dictionary need saving (that is, to be added to the managed object context as TGSongUserData managed objects)
//    NSMutableSet *songsWithChangesToSave;
//    NSMutableSet *songsWithSaveError;
    
    NSTimer *idleTimeFingerprinterTimer;

    /// The playheadPos is bound to the playlist progress indicator value property so that when the song
    /// progresses so does the indicator.
    /// It is also bound, via an object controller, to the popup timeline NSSlider's (timelineBar)
    /// cell's (TGTimelineSliderCell) currentPlayheadPositionInPercent property.
    NSNumber *playheadPos;
    
    /// The requestedPlayheadPosition is bound,via an object controller, to the popup timeline's NSSlider (timelineBar).
    NSNumber *requestedPlayheadPosition;
    
    SongPlayer* theSongPlayer;
}

@property TGStack* requestedSongStack;
@property CoverArtArchiveWebFetcher* coverArtWebFetcher;

@property id<TGMainViewControllerDelegate> delegate;
@property id<SongGridAccessProtocol> songGridAccessAPI;

// Holds the art associated with the songs. Songs will hold indices into the art array.
@property NSMutableArray *artArray;

// Holds the playhead position of the currently playing song.
@property NSNumber *currentSongDuration;

// TEOSongData test
@property NSManagedObjectContext*   privateContext;
@property NSManagedObjectContext*   TEOmanagedObjectContext;
@property NSDictionary*             TEOSongDataDictionary;
// TEOSongData end

/**
 The uploaded sweet spots is a dictionary of UploadedSSData objects for songs that
 have been uploaded to the sweet spot server. The dictionary is backed by core data.
 */
@property NSMutableDictionary* uploadedSweetSpots;
@property NSManagedObjectContext* uploadedSweetSpotsMOC;

@property SweetSpotServerIO* sweetSpotServerIO;

@property NSFileManager*    sharedFileManager;


// Methods
- (id<SongIDProtocol>)initWithURL:(NSURL*) theURL;
- (BOOL)validateURL:(NSURL *)anURL;
- (BOOL)loadFromURL:(NSURL *)anURL ;

- (void)requestImageForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSImage *))imageHandler;

// Caching methods
//- (void)preloadSongArray:(NSArray *)songArray;
//- (void)cacheWithContext:(NSDictionary*)cacheContext;

#pragma mark -
#pragma mark song data accessor methods.
// Async methods
- (void)requestEmbeddedMetadataForSongID:(id<SongIDProtocol>)songID withHandler:(void (^)(NSDictionary*))dataHandler;

//- (void)offsetSweetSpotForSongID:(id<SongIDProtocol>)songID bySeconds:(Float64)offsetInSeconds;
- (void)storeSweetSpotForSongID:(id<SongIDProtocol>)songID;

// song data accessors.
- (void)sweetSpotFromServerForSong:(TGSong *)aSong;

// UUID accessors.
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (NSString *)UUIDStringForSongID:(id<SongIDProtocol>)songID;

//// Sweet Spot accessors.
//- (NSArray *)sweetSpotsForSongID:(id)songID;

// URL accessors.
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;

// Releases accessors TEO switch to use NSArray/NSSet in the managedobject same as the sweetspots
- (NSData*)releasesForSongID:(id<SongIDProtocol>)songID;
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;

- (NSString*)albumForSongID:(id<SongIDProtocol>)songID;

// TEO should this not be private?
- (NSString *)findUUIDOfSongWithURL:(NSURL *)songURL;

#pragma mark -
#pragma mark core data methods
// Core Data methods
- (void)storeSongData;
- (NSArray *)fetchMetadataFromLocalStore;
- (BOOL)loadMetadataIntoSong:(TGSong *)aSong;


// Other protocols' delegate methods that TGSongPool implements

// TGFingerPrinterDelegate protocol methods called by TGFingerPrinter
- (void)fingerprintReady:(NSString *)fingerPrint ForSong:(TGSong *)song;

// TGSongDelegate protocol methods called by TGSong
- (void)songDidFinishPlayback:(TGSong *)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
- (void)songReadyForPlayback:(TGSong *)song;
- (NSSet*)currentCache;

//MARK: Test methods
- (void)testUploadSSForSongID:(id<SongIDProtocol>)theID;

@end


