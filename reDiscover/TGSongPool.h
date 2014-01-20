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

// protocol forward declaration
@protocol TGSongPoolDelegate;

// The public interface declaration doesn't implement the TGSongDelegate. The private interface declaration in the .m will.
@interface TGSongPool : NSObject <TGPlaylistViewControllerDelegate>
{
    int loadedURLs;
    BOOL errorLoadingSongURLs;
    BOOL allURLsLoaded;
    BOOL allURLsRequested;
    // concurrent queue used for asynch resource loading.
    NSOperationQueue *opQueue;
    dispatch_queue_t playbackQueue;
    dispatch_queue_t serialDataLoad;
    dispatch_queue_t timelineUpdateQueue;
    
    NSUInteger songPoolStartCapacity;
    NSMutableDictionary *songPoolDictionary;
    TGSong *currentlyPlayingSong;
    TGSong *lastRequestedSong;
    int32_t srCounter;
    
    TGFingerPrinter *songFingerPrinter;
    
    NSPersistentStoreCoordinator *songPoolDataCoordinator;
    NSEntityDescription *songUserDataEntityDescription;
    NSManagedObjectModel *songUserDataManagedObjectModel;
    NSManagedObjectContext *songPoolManagedContext;
    NSArray *fetchedArray;
    
    // songs added to this dictionary need saving (that is, to be added to the managed object context as TGSongUserData managed objects)
    //NSMutableDictionary *songsWithChangesToSave;
    NSMutableSet *songsWithChangesToSave;
    NSMutableSet *songsWithSaveError;
    
    NSTimer *idleTimeFingerprinterTimer;
    
    NSNumber *playheadPos;
    NSNumber *requestedPlayheadPosition;
}

// Holds the playhead position of the currently playing song.
@property NSNumber *currentSongDuration;

@property id<TGSongPoolDelegate> delegate;

// Methods
- (BOOL)validateURL:(NSURL *)anURL;
- (BOOL)loadFromURL:(NSURL *)anURL ;
- (void)updateCache:(NSArray *)songIDArray;
// Async methods
- (void)requestEmbeddedMetadataForSong:(NSInteger) songID;
- (void)requestSongPlayback:(NSInteger)songID withStartTimeInSeconds:(NSNumber *)time;
- (void)setRequestedPlayheadPosition:(NSNumber *)newPosition;

- (float)fetchSweetSpotForSongID:(NSInteger)songID;

-(NSDictionary *)getSongDisplayStrings:(NSInteger)songID;
-(NSInteger)lastRequestedSongID;
-(TGSong *)songForID:(NSInteger)songID;
- (TGSong *)currentlyPlayingSong;



- (void)preloadSongArray:(NSArray *)songArray;
- (void)storeSongData;
- (void)fetchMetadataFromLocalStore;
- (BOOL)loadMetadataIntoSong:(TGSong *)aSong;
- (void)offsetSweetSpotForSongID:(NSInteger) songID bySeconds:(Float64)offsetInSeconds;
- (void)sweetSpotFromServerForSong:(TGSong *)aSong;

- (void)songDidFinishPlayback:(TGSong *)song;
- (void)songDidLoadEmbeddedMetadata:(TGSong *)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;

- (NSInteger)songDurationForSongID:(NSInteger)songID;
- (NSDictionary *)songDataForSongID:(NSInteger)songID;
- (NSURL *)songURLForSongID:(NSInteger)songID;
- (NSString *)getSongGenreStringForSongID:(NSInteger)songID;

@end

// Delegate method declarations.
@protocol TGSongPoolDelegate <NSObject>
//@optional
- (void)songPoolDidLoadSongURLWithID:(NSUInteger)songID;
- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs;
- (void)songPoolDidStartPlayingSong:(NSUInteger)songID;
- (void)songPoolDidFinishPlayingSong:(NSUInteger)songID;
- (void)songPoolDidLoadDataForSongID:(NSUInteger)songID;
@end
