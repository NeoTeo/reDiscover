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

@class CoverArtArchiveWebFetcher;
@class TGStack;

// protocol forward declaration
@protocol TGSongPoolDelegate;
@protocol SongPoolAccessProtocol;

// The public interface declaration doesn't implement the TGSongDelegate. The private interface declaration in the .m will.
@interface TGSongPool : NSObject <TGPlaylistViewControllerDelegate>
{
    int loadedURLs;
    BOOL errorLoadingSongURLs;
    BOOL allURLsLoaded;
    BOOL allURLsRequested;
    // concurrent queue used for asynch resource loading.
    NSOperationQueue *opQueue;
    
    NSOperationQueue* urlLoadingOpQueue;
    NSOperationQueue* urlCachingOpQueue;
    
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
//    NSArray *fetchedArray;
    
    // songs added to this dictionary need saving (that is, to be added to the managed object context as TGSongUserData managed objects)
    //NSMutableDictionary *songsWithChangesToSave;
    NSMutableSet *songsWithChangesToSave;
    NSMutableSet *songsWithSaveError;
    
    NSTimer *idleTimeFingerprinterTimer;
    
    NSNumber *playheadPos;
    NSNumber *requestedPlayheadPosition;
}

@property TGStack* requestedSongStack;
@property CoverArtArchiveWebFetcher* coverArtWebFetcher;

@property id<TGSongPoolDelegate> delegate;

// Holds the art associated with the songs. Songs will hold indices into the art array.
@property NSMutableArray *artArray;

// Holds the playhead position of the currently playing song.
@property NSNumber *currentSongDuration;

// TEOSongData test
@property NSManagedObjectContext*   privateContext;
@property NSManagedObjectContext*   TEOmanagedObjectContext;
@property NSDictionary*             TEOSongDataDictionary;
// TEOSongData end

@property NSFileManager*    sharedFileManager;


// Methods
- (id)initWithURL:(NSURL*) theURL;
- (BOOL)validateURL:(NSURL *)anURL;
- (BOOL)loadFromURL:(NSURL *)anURL ;


- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition;

- (id)currentlyPlayingSongID;


- (void)requestImageForSongID:(id)songID withHandler:(void (^)(NSImage *))imageHandler;

- (void)preloadSongArray:(NSArray *)songArray;
#pragma mark -
#pragma mark song data accessor methods.
// Async methods
- (void)requestEmbeddedMetadataForSongID:(id)songID withHandler:(void (^)(NSDictionary*))dataHandler;
- (void)requestSongPlayback:(id)songID withStartTimeInSeconds:(NSNumber *)time;

- (NSURL *)songURLForSongID:(id)songID;
- (NSNumber *)songDurationForSongID:(id)songID;
- (NSDictionary *)songDataForSongID:(id)songID;
- (void)offsetSweetSpotForSongID:(id)songID bySeconds:(Float64)offsetInSeconds;
- (void)storeSweetSpotForSongID:(id)songID;

// song data accessors.
- (void)sweetSpotFromServerForSong:(TGSong *)aSong;

// UUID accessors.
-(void)setUUIDString:(NSString*)theUUID forSongID:(id)songID;
- (NSString *)UUIDStringForSongID:(id)songID;

// Sweet Spot accessors.
- (NSArray *)sweetSpotsForSongID:(id)songID;

// URL accessors.
- (NSURL *)URLForSongID:(id)songID;

// Releases accessors TEO switch to use NSArray/NSSet in the managedobject same as the sweetspots
- (NSData*)releasesForSongID:(id)songID;
- (void)setReleases:(NSData*)releases forSongID:(id)songID;

- (NSString*)albumForSongID:(id)songID;

// TEO should this not be private?
- (NSString *)findUUIDOfSongWithURL:(NSURL *)songURL;

#pragma mark -
#pragma mark core data methods
// Core Data methods
- (void)storeSongData;
- (NSArray *)fetchMetadataFromLocalStore;
- (BOOL)loadMetadataIntoSong:(TGSong *)aSong;


// DELEGATE METHODS

// TGFingerPrinterDelegate method
- (void)fingerprintReady:(NSString *)fingerPrint ForSong:(TGSong *)song;

// TGSongDelegate calls these methods
- (void)songDidFinishPlayback:(TGSong *)song;
-(id)lastRequestedSongID;

//- (void)songDidLoadEmbeddedMetadata:(TGSong *)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
- (void)songReadyForPlayback:(TGSong *)song;


@end

// Delegate method declarations.
@protocol TGSongPoolDelegate <NSObject>
//@optional
- (void)songPoolDidLoadSongURLWithID:(id)songID;
- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs;
- (void)songPoolDidStartPlayingSong:(id)songID;
- (void)songPoolDidFinishPlayingSong:(id)songID;
- (void)songPoolDidLoadDataForSongID:(id)songID;
//- (void)songPoolDidLoadSongURLWithID:(NSUInteger)songID;
//- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs;
//- (void)songPoolDidStartPlayingSong:(NSUInteger)songID;
//- (void)songPoolDidFinishPlayingSong:(NSUInteger)songID;
//- (void)songPoolDidLoadDataForSongID:(NSUInteger)songID;
@end
