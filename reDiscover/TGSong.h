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

// Forward declarations.
@class AVURLAsset;
@class AVPlayerItem;
@class AVPlayer;
@class NSURL;

@protocol TGSongDelegate;

// Enum declarations
enum {
    kSongStatusLoading         = 0,
    kSongStatusReady           = 1,
    kSongStatusUnloading       = 2,
    kSongStatusFailed          = 3
};

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

// the acoustic fingerprint of the song.
@property NSString *fingerprint;
@property NSUInteger fingerPrintStatus;
@property NSString *songUUIDString;

@property NSUInteger songID;
@property NSURL *songURL;
@property NSUInteger songStatus;
@property NSUInteger loadStatus;
@property CMTime songDuration;
@property CMTime songStartTime;
@property int songTimeScale;
@property NSDictionary *songData;

@property CMTime requestedSongStartTime;
@property NSUInteger selectedSweetSpot;
@property NSArray *songSweetSpots;

// A counter to provide a variable interval between sweet-spot checks.
@property NSUInteger SSCheckCountdown;

//- (NSUInteger)getSongID;
- (NSNumber *)startTime;
- (void)setStartTime:(NSNumber *)startTime;
- (id)initWithURL:(NSURL *)anURL;
- (void)loadTrackData;
- (BOOL)playStart;
- (void)playStop;
- (double)getDuration;
- (Float64)getCurrentPlayTime;
- (void)setCurrentPlayTime:(NSNumber *)playTimeInSeconds;
//- (void)setCurrentPlayTime:(Float64)playTimeInSeconds;
- (void)requestCoverImageWithHandler:(void (^)(NSImage *))imageHandler;
- (void)requestSongAlbumImage:(void (^)(NSImage *))imageHandler;
- (void)loadSongMetadata;

    
@property id <TGSongDelegate>delegate;
@end


@protocol TGSongDelegate <NSObject>
//@optional
- (void)songReadyForPlayback:(TGSong *)song;
- (void)songDidFinishPlayback:(TGSong *)song;
- (void)songDidLoadEmbeddedMetadata:(TGSong *)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
- (dispatch_queue_t)serialQueue;

@end