//
//  TGSong.h
//  Proto3
//
//  This is the model class for a song.
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

// CMTime is a struct so it can't be forward declared and must be imported.
#import <CoreMedia/CMTime.h>

//MARK: Forward declarations.
@class AVURLAsset;
@class AVPlayerItem;
@class AVPlayer;
@class NSURL;
@class TEOSongData;
@class AVAudioFile;

@protocol TGSongDelegate;
@protocol SongIDProtocol;
@protocol SongPoolAccessProtocol;

// Enum declarations

// States of the songStatus property:
enum {
    kSongStatusLoading         = 0,
    kSongStatusReady           = 1,
    kSongStatusUnloading       = 2,
    kSongStatusFailed          = 3,
    kSongStatusUninited        = 4
};

// States of the loadStatus property:
enum {
    kLoadStatusAllCompleted         = 0x0,
    kLoadStatusTrackCompleted       = 0x1,
    kLoadStatusTrackFailed          = 0x2,
    kLoadStatusDurationCompleted    = 0x3,
    kLoadStatusDurationFailed       = 0x4,
    kLoadStatusUnloaded             = 0xD,
    kLoadStatusCancelled            = 0xE,
    kLoadStatusFailed               = 0xF
};

// States of the fingerPrintStatus property:
enum {
    kFingerPrintStatusEmpty         = 0x00,
    kFingerPrintStatusRequested     = 0x01,
    kFingerPrintStatusDone          = 0x02,
    kFingerPrintStatusFailed        = 0xff
};

@interface TGSong : NSObject
{
    AVURLAsset *songAsset;
    AVPlayerItem *songPlayerItem;
    AVPlayer *songPlayer;
    
    id playerObserver;
}

// song data that is shadowed and saved by TEOSongData in the SongPool
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

// cached stuff
@property AVAudioFile* cachedFile;
@property int64_t cachedFileLength;

//@property NSManagedObjectContext* TEODataMOC;
//@property TEOSongData* TEOData;

@property id<SongIDProtocol> songID;
// State of various activities.
@property NSUInteger fingerPrintStatus;
@property NSUInteger songStatus;
@property NSUInteger loadStatus;

@property CMTime songDuration;
@property int songTimeScale;

#define TSD

//@property dispatch_queue_t serialTestQueue;

// Typedef a block that takes an NSNumber* and returns void to MyCustomBlock
typedef void(^MyCustomBlock)(void);
// make a property for this class that holds a custom block.
// This is used by the loadTrackDataWithCallBackOnCompletion to set a callback to be
// called when the KVO observed SongPlayerItem status changes to ready. 
@property (nonatomic, copy) MyCustomBlock customBlock;

//// A place to store the song's requested start time between being called and
//// actually being ready to play back. Since KVO doesn't provide custom data to go
//// through its calls I'm having to store it "on the side". Not happy about this.
//@property NSNumber* startTime;

/// An id key into the songpool's art dictionary. A value of nil signals no art.
@property NSString* artID;

///// An id key into the songpool's art dictionary. Values of -1 will be no art and 0 will be the default "no cover" art.
//@property NSInteger artID;

/// A counter to provide a variable interval between sweet-spot checks.
@property NSUInteger SSCheckCountdown;

//- (void)setCache:(AVAudioFile*) theFile;
//- (void)unload;

- (void)storeSelectedSweetSpot;
- (NSNumber*)currentSweetSpot;
- (void)makeSweetSpotAtTime:(NSNumber*)startTime;
- (void)setSweetSpot:(NSNumber*)theSS;
- (id)init;

//- (void)prepareForPlaybackWithCompletionBlock:(void (^)(void))completionBlock;
//- (void)load;
//- (void)performWhenReadyForPlayback:(void (^)(void))completionBlock;
//- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback withStartTime:(NSNumber*)startTime;
//- (void)loadTrackDataAtStartTime:(NSNumber*)startTime withCompletionBlock:(void (^)(void))completionBlock;
//- (void)performBlockWhenReadyForPlayback:(void (^)(void))completionBlock;

//- (void)playAtTime:(NSNumber*)startTime;
//- (void)playStop;
//- (double)getDuration;
//- (Float64)getCurrentPlayTime;
//- (void)setCurrentPlayTime:(NSNumber *)playTimeInSeconds;
- (void)searchMetadataForCoverImageWithHandler:(void (^)(NSImage *))imageHandler;
- (BOOL)loadSongMetadata;
/// returns true if the song is ready for playback.
- (BOOL)isReadyForPlayback;

@property id<SongPoolAccessProtocol>songPoolAPI;
@property id <TGSongDelegate>delegate;
@end


@protocol TGSongDelegate <NSObject>
//@optional
- (id<SongIDProtocol>)lastRequestedSongID;
//- (void)songReadyForPlayback:(TGSong *)song atTime:(NSNumber*)startTime;
- (void)songDidFinishPlayback:(TGSong *)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
- (dispatch_queue_t)serialQueue;
- (dispatch_queue_t)songLoadUnloadQueue;

@end