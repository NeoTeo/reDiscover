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
#import "TGSongProtocol.h"

//MARK: Forward declarations.
@class AVURLAsset;
@class AVPlayerItem;
@class AVPlayer;
@class NSURL;
@class TEOSongData;
@class AVAudioFile;
@class SongMetaData;

@protocol TGSong;
@protocol SongIDProtocol;
@protocol SongPoolAccessProtocol;

// Enum declarations

// States of the fingerPrintStatus property:
enum {
    kFingerPrintStatusEmpty         = 0x00,
    kFingerPrintStatusRequested     = 0x01,
    kFingerPrintStatusDone          = 0x02,
    kFingerPrintStatusFailed        = 0xff
};
/*
@interface TGSong : NSObject <TGSong,NSCopying>

// song data that is shadowed and saved by TEOSongData in the SongPool
//FIXME: Make all these (readonly) when ready and make them ivars by moving
// them into the interface definition above.
// Should this not be in SongMetaData really?
@property (nonatomic, copy) SongMetaData *metadata;

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

@property id<SongIDProtocol> songID;

// State of fingerprinting.
@property NSUInteger fingerPrintStatus;

@property CMTime songDuration;

#define TSD

// Typedef a block that takes an NSNumber* and returns void to MyCustomBlock
typedef void(^MyCustomBlock)(void);
// make a property for this class that holds a custom block.
// This is used by the loadTrackDataWithCallBackOnCompletion to set a callback to be
// called when the KVO observed SongPlayerItem status changes to ready. 
@property (nonatomic, copy) MyCustomBlock customBlock;

/// An id key into the songpool's art dictionary. A value of nil signals no art.
@property (nonatomic, copy) NSString* artID;

/// A counter to provide a variable interval between sweet-spot checks.
@property NSUInteger SSCheckCountdown;

- (id)copy;
- (id)copyWithZone:(NSZone *)zone;

//- (void)storeSelectedSweetSpot;
//- (NSNumber*)currentSweetSpot;
//- (void)makeSweetSpotAtTime:(NSNumber*)startTime;
//- (void)setSweetSpot:(NSNumber*)theSS;
//- (id)init;

@property id<SongPoolAccessProtocol>songPoolAPI;
@property id <TGSongDelegate>delegate;
@end
*/

@protocol TGSongDelegate <NSObject>
//@optional
- (id<SongIDProtocol>)lastRequestedSongID;
- (void)songDidFinishPlayback:(id<TGSong>)song;
- (void)songDidUpdatePlayheadPosition:(NSNumber *)playheadPosition;
- (dispatch_queue_t)serialQueue;
- (dispatch_queue_t)songLoadUnloadQueue;

@end