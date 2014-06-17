//
//  TGSong.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSong.h"
#import "TEOSongData.h"

#import <AVFoundation/AVFoundation.h>


@implementation TGSong

#ifndef TSD
- (id)initWithURL:(NSURL *)anURL {
    
    self = [super init];
    if (self) {
        
        _songURL = anURL;
        _songTimeScale = 100; // Centiseconds.
        
        [self setSongStartTime:CMTimeMake(-1, 1)];
//        _fingerprint = nil; removed for TEOSongData
        _fingerPrintStatus = kFingerPrintStatusEmpty;
        _songSweetSpots = nil;
        _requestedSongStartTime = CMTimeMake(-1, 1);
        _SSCheckCountdown = 0;
        _artID = -1;
    }
    return self;
}
#endif

- (id)init {
    self = [super init];
    if (self) {
        
        _songTimeScale = 100; // Centiseconds.
        
        [self setSongStartTime:CMTimeMake(-1, 1)];
        _fingerPrintStatus = kFingerPrintStatusEmpty;
        _songSweetSpots = nil;
        _requestedSongStartTime = CMTimeMake(-1, 1);
        _SSCheckCountdown = 0;
        _artID = -1;
    }
    return self;
}

- (void)requestCoverImageWithHandler:(void (^)(NSImage *))imageHandler {
    
    if (songAsset == nil) {
//        songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:nil];
        songAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.TEOData.urlString] options:nil];
    }
        
    [songAsset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"] completionHandler:^{
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSArray *artworks = [AVMetadataItem metadataItemsFromArray:songAsset.commonMetadata  withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
            
            for (AVMetadataItem *metadataItem in artworks) {
                
                if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                    
                    NSDictionary *d = [metadataItem.value copyWithZone:nil];
                    // Use the passed in callback to return image.
                    imageHandler([[NSImage alloc] initWithData:[d objectForKey:@"data"]]);
                    return;
                    
                } else if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
                    
                    // Use the passed in callback to return image.
                    imageHandler([[NSImage alloc] initWithData:[metadataItem.value copyWithZone:nil]]);
                    return;
                    
                } else
                    NSLog(@"%@ is neither mp3 nor iTunes.",metadataItem.keySpace);
            }
            
            // No luck. Call the image handler with nil.
            imageHandler(nil);
            
        });
    }];
}


- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback {
    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    [self setSongStatus:kSongStatusLoading];
    songAsset = [AVAsset assetWithURL:theURL];
    
    // Get the song duration.
    //    This may block which is just how we want it.
    [self setSongDuration:[songAsset duration]];
    if ([songAsset isPlayable]) {
        [self setSongStatus:kSongStatusReady];
        
        if (!wantsCallback) return;
        
        [[self delegate] songReadyForPlayback:self];
    }
}
/*
// Just-in-time track data loading.
- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback {
    
    // If the song is already loaded we just need to tell the delegate.
    if ([self songStatus] == kSongStatusReady) {
        if (wantsCallback == YES) {
            if ([[self delegate] respondsToSelector:@selector(songReadyForPlayback:)]) {
                [[self delegate] songReadyForPlayback:self];
            }
        }
        return;
    }
    // Start off marking this song as currently loading.
    [self setSongStatus:kSongStatusLoading];
    
    // TEO change this to comparing SongID types when we switch over to using the SongID type
    // Check if we're still the last requested song.
    NSString* idString = [[self delegate] lastRequestedSongID];
    if (![idString isEqualToString:[self songID]] ) {
        NSLog(@"early out of load track");
        return;
    }
//  Loading the asset with precise duration and timing significantly slows down playback response times.
    // If used, should only be enabled on songs that are not returning accurate timing values. (Eg. the Abba stuff)
//    NSDictionary *songLoadingOptions = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
//    songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:songLoadingOptions];
    
// TEO can get stuck in here (Often!) semaphore_wait_trap. This is probably due to hitting GCD's 64 thread limit.
//    songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:nil];

    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    songAsset = [[AVURLAsset alloc] initWithURL:theURL options:nil];
   
    // The keys that must be set for the completion hander to be called.
    NSArray *keys = @[@"tracks",@"duration"];
    
//    NSLog(@"loadTrackDataWithCallbackOnCompletion for song %@ and wantsCallback %@",[self songID],wantsCallback?@"YES":@"NO");
    //NSLog(@"I gots %lu",(unsigned long)[artworks count]);
    NSAssert(songAsset, @"Song asset is missing!");
    [songAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        NSError *error = nil;
        AVKeyValueStatus assetStatus = [songAsset statusOfValueForKey:@"tracks" error:&error];
        
        switch (assetStatus) {
            case AVKeyValueStatusLoaded:
            {
                if ([self loadStatus] == kLoadStatusDurationCompleted) {
                    
                    [self setSongStatus:kSongStatusReady];
                   
                } else
                    [self setLoadStatus:kLoadStatusTrackCompleted];
                
                break;
            }
            case AVKeyValueStatusFailed:
            {
                NSLog(@"URL track %@ load failed.",theURL);
                [self setLoadStatus:kLoadStatusFailed];
                break;
            }
            case AVKeyValueStatusCancelled:
            {
                // Do whatever is appropriate for cancelation.
                [self setLoadStatus:kLoadStatusCancelled];
                break;
            }
            case AVKeyValueStatusUnknown:
                NSLog(@"Status for song duration unknown");
                break;
            case AVKeyValueStatusLoading:
                NSLog(@"Status for song duration loading");

        }
        
        assetStatus = [songAsset statusOfValueForKey:@"duration"
                                             error:&error];
        switch (assetStatus) {
            case AVKeyValueStatusLoaded:
            {
                
                [self setSongDuration:songAsset.duration];
                if ([self loadStatus] == kLoadStatusTrackCompleted) {
                    
                    [self setSongStatus:kSongStatusReady];
                    
                } else
                    [self setLoadStatus:kLoadStatusDurationCompleted];
        
                //NSLog(@"The loaded song has a duration of %f",CMTimeGetSeconds(_songDuration));
                break;
            }
            case AVKeyValueStatusFailed:
            {
                NSLog(@"URL duration %@ load failed.",theURL);
                [self setLoadStatus:kLoadStatusDurationFailed];
                [self setSongStatus:kSongStatusFailed];
                break;
            }
            case AVKeyValueStatusCancelled:
                NSLog(@"Status for song duration cancelled");
                break;
            case AVKeyValueStatusUnknown:
                NSLog(@"Status for song duration unknown");
                break;
            case AVKeyValueStatusLoading:
                NSLog(@"Status for song duration loading");
        }
        
        if ((wantsCallback == YES) && [self songStatus] == kSongStatusReady) {
            //[self songDataHasLoaded];
            if ([[self delegate] respondsToSelector:@selector(songReadyForPlayback:)]) {
                [[self delegate] songReadyForPlayback:self];
            }
        }
    }];
}
*/

- (BOOL)loadSongMetadata {    
    NSString *tmpString = [self.TEOData.urlString stringByDeletingPathExtension];
    NSString* fileName = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* album = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* artist = [tmpString lastPathComponent];
    
    // Get other metadata via the MDItem of the file.
    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    MDItemRef metadata = MDItemCreate(NULL, (__bridge CFStringRef)[theURL path]);
    
    // Add reasonable defaults
    self.TEOData.artist = [artist stringByRemovingPercentEncoding];//@"Unknown";
    self.TEOData.title  = [fileName stringByRemovingPercentEncoding];//@"Unknown";
    self.TEOData.album  = [album stringByRemovingPercentEncoding];//@"Unknown";
    self.TEOData.genre  = @"Unknown";
    
    if (metadata) {
        NSString* aString;
        NSArray* artists;
        
        if ((artists = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAuthors)))) {
           self.TEOData.artist = [artists objectAtIndex:0];
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemTitle)))) {
            self.TEOData.title = aString;
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAlbum)))) {
            self.TEOData.album = aString;
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemMusicalGenre)))) {
            self.TEOData.genre = aString;
        }
        
        // Make sure that sucker is released.
        CFRelease(metadata);
        return YES;
    }
    return NO;
}

- (NSNumber *)startTime {
    return [NSNumber numberWithFloat:CMTimeGetSeconds([self songStartTime])];
}


// This method can get called before the song has finished loading its duration from the datafile.
// Since we cannot assume we know the duration we cannot check it against the given start time.
// Because the startTime can (currently) only be set by listening to the song we have to assume it will be < song duration.
- (void)setStartTime:(NSNumber *)startTime {
    float floatStart = [startTime floatValue];
    if ( _songStatus == kSongStatusReady) {
        float floatDuration = CMTimeGetSeconds([self songDuration]);
        
        if ((floatStart >= 0) && (floatStart < floatDuration)) {
            //NSLog(@"setting start time to %f",floatStart);
            [self setSongStartTime:CMTimeMakeWithSeconds(floatStart, _songTimeScale)];
        } else {
            // -1 means the start time hasn't been set.
            if (floatStart != -1) {
                NSLog(@"setStartTime error: Start time is %f",floatStart);
            }
        }
    } else {
        //NSLog(@"setting start time to %f without knowing duration",floatStart);
        [self setSongStartTime:CMTimeMakeWithSeconds(floatStart, _songTimeScale)];
    }
}


- (BOOL)playStart {
    if ([self songStatus] == kSongStatusReady) {
        
        if (songPlayerItem == nil) {
            songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
        }
        if (songPlayer == nil) {
            songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
        }
        [songPlayer setVolume:0.2];
        
        // if the requestedSongStartTime is -1 then play the song from the user's selected sweet spot.
        if (CMTimeGetSeconds(_requestedSongStartTime) == -1) {
            [songPlayer seekToTime:_songStartTime];
        } else
            [songPlayer seekToTime:_requestedSongStartTime];
        

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:songPlayerItem];
        
        if (playerObserver == nil) {
            // Add a periodic observer so we can update the timeline GUI.
            CMTime eachSecond = CMTimeMake(10, 100);
            dispatch_queue_t timelineSerialQueue = [_delegate serialQueue];
            
            // Make a weakly retained self for use inside the block to avoid retain cycle.
            __unsafe_unretained typeof(self) weakSelf = self;
            
            // Every 1/10 of a second update the delegate's playhead position variable.
            playerObserver = [songPlayer addPeriodicTimeObserverForInterval:eachSecond queue:timelineSerialQueue usingBlock:^void(CMTime time) {
                CMTime currentPlaybackTime = [weakSelf->songPlayer currentTime];
                [[weakSelf delegate] songDidUpdatePlayheadPosition:[NSNumber numberWithDouble:CMTimeGetSeconds(currentPlaybackTime)]];
            }];
        }

        [songPlayer play];
        return YES;
    }
    return NO;
}


- (void)playDidFinish {
    if ([[self delegate] respondsToSelector:@selector(songDidFinishPlayback:)]) {
        [[self delegate] songDidFinishPlayback:self];
    }
}

- (void)playStop {

    [songPlayer removeTimeObserver:playerObserver];
    playerObserver = nil;
    
    [songPlayer pause];
    // TEO: test to release asset and associated threads. This should for songs not marked as cached.
    return;
    {
    songAsset = NULL;
    songPlayerItem = NULL;
    songPlayer = NULL;
#pragma SPEED
#pragma TEO: The unloading is not yet implemented. By setting the song status to something other than ready we reload it every time we play it.
    [self setLoadStatus:kLoadStatusUnloaded];
    [self setSongStatus:kSongStatusUnloading];
    }
}

//- (void)setCurrentPlayTime:(Float64)playTimeInSeconds {
- (void)setCurrentPlayTime:(NSNumber *)playTimeInSeconds {
    double playTime = [playTimeInSeconds doubleValue];
    if ((playTime >= 0) && (playTime < CMTimeGetSeconds([self songDuration]))) {
        [songPlayer seekToTime:CMTimeMake(playTime*100, 100)];
    }
}

- (double)getDuration {
    return CMTimeGetSeconds([self songDuration]);
}

- (Float64)getCurrentPlayTime {
    if (songPlayer != nil) {
        return CMTimeGetSeconds([songPlayer currentTime]);
    }
    return 0;
}

// TEO Never called.
// Looks in the common metadata of the asset for the given string.
- (NSString *)getStringValueForStringKey:(NSString *)theString fromAsset:(AVURLAsset *)theAsset
{
    NSArray *songMeta = [theAsset commonMetadata];
    
    for (AVMetadataItem *item in songMeta ) {
        NSString *key = [item commonKey];
        NSString *value = [item stringValue];
        if ([key isNotEqualTo:@"artwork"]) {
            NSLog(@"songMeta key:%@ value:%@",key,value);
        }

        if ([key isEqualToString:theString]) {
            return value;
        }
    }
    return @"no data.";
}


@end
