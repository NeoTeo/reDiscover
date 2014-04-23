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
@class TEOSongData;

@protocol TGSongDelegate;

// Enum declarations

// States of the songStatus property:
enum {
    kSongStatusLoading         = 0,
    kSongStatusReady           = 1,
    kSongStatusUnloading       = 2,
    kSongStatusFailed          = 3
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

// Test of managed object
//@property NSManagedObject* TEOSongData;
@property TEOSongData* TEOData;

// the acoustic fingerprint of the song.
//@property NSString *fingerprint;

// Stores the UUID obtained from an acoustid server given a fingerprint.
//@property NSString *songUUIDString;

// The local and per-session temporary song id.
@property NSUInteger songID;

// The location of a song.
//@property NSURL *songURL;


// State of various activities.
@property NSUInteger fingerPrintStatus;
@property NSUInteger songStatus;
@property NSUInteger loadStatus;

@property CMTime songDuration;
@property CMTime songStartTime;
@property int songTimeScale;

#define TSD
#ifndef TSD
// Additional song metadata.
@property NSDictionary *songData;
#endif

// An id key into the songpool's art dictionary. Values of -1 will be no art and 0 will be the default "no cover" art.
//@property NSInteger artID;

@property CMTime requestedSongStartTime;

// The currently selected sweet spot.
@property NSUInteger selectedSweetSpot;

// All available sweet spots for the song.
@property NSArray *songSweetSpots;

// A counter to provide a variable interval between sweet-spot checks.
@property NSUInteger SSCheckCountdown;



- (NSNumber *)startTime;
- (void)setStartTime:(NSNumber *)startTime;
//- (id)initWithURL:(NSURL *)anURL;
- (id)init;
- (void)loadTrackData;
- (BOOL)playStart;
- (void)playStop;
- (double)getDuration;
- (Float64)getCurrentPlayTime;
- (void)setCurrentPlayTime:(NSNumber *)playTimeInSeconds;
- (void)requestCoverImageWithHandler:(void (^)(NSImage *))imageHandler;
- (void)requestSongAlbumImage:(void (^)(NSImage *))imageHandler;
#ifndef TSD
- (void)loadSongMetadata;
#else
- (BOOL)loadSongMetadata;
#endif
    
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