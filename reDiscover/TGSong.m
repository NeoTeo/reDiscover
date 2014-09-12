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

- (id)init {
    self = [super init];
    if (self) {
        
        _songTimeScale = 100; // Centiseconds.
        
//        [self setSongStartTime:CMTimeMake(-1, 1)];
//        _requestedSongStartTime = CMTimeMake(-1, 1);

        _fingerPrintStatus = kFingerPrintStatusEmpty;
//        _songSweetSpots = nil;
        _SSCheckCountdown = 0;
        _artID = -1;
    }
    return self;
}
//TODO: Move to songpool?
- (void)requestCoverImageWithHandler:(void (^)(NSImage *))imageHandler {

    if (songAsset == nil) {
        songAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.TEOData.urlString] options:nil];
    }
    [songAsset loadValuesAsynchronouslyForKeys:@[@"commonMetadata"] completionHandler:^{
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            NSArray *artworks = [AVMetadataItem metadataItemsFromArray:songAsset.commonMetadata  withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];

            for (AVMetadataItem *metadataItem in artworks) {
                
                // Use the passed in callback to return image.
                imageHandler([[NSImage alloc] initWithData:[metadataItem.value copyWithZone:nil]]);
                return;
            }
            
            // No luck. Call the image handler with nil.
            imageHandler(nil);
            
        });
    }];
//    NSLog(@"requestCoverImageWithHandler all done");

}

//MARK: Why is this not done asynchronously with...
// ...loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:
- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback {
    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    [self setSongStatus:kSongStatusLoading];
    
    songAsset = [AVAsset assetWithURL:theURL];
// Enabling this, aside from slowing loading, also makes scrubbing laggy.
//        NSDictionary *songLoadingOptions = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
//        songAsset = [[AVURLAsset alloc] initWithURL:theURL options:songLoadingOptions];

    // Get the song duration.
    //    This may block which is just how we want it.
    [self setSongDuration:[songAsset duration]];
    if ([songAsset isPlayable]) {
        [self setSongStatus:kSongStatusReady];
        
        if (!wantsCallback) return;
        
        [[self delegate] songReadyForPlayback:self];
    }
}

/**
    Load metadata from the file associated with this song and store it in the TEOData managed context.
    @returns YES on success and NO on failure to find any metadata. 
    In either case the TEOData will be set to some reasonable defaults.
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

/**
 Return the start time for this song, which is given by this song's selected sweet spot.
 @returns Start time in seconds.
 */
- (NSNumber *)startTime {
    if (self.oneOffStartTime) {
        return self.oneOffStartTime;
    }
    return self.TEOData.selectedSweetSpot;
}

/**
 Set the start time for this song by creating a sweet spot at the requested time and setting it as the currently selected sweet spot.
 :params: startTime The offset, in seconds, from the beginning of the song (time 0) that we wish this song to start playing from.
 */
- (void)setStartTime:(NSNumber *)startTime makeSweetSpot:(BOOL)makeSS {
    // This method can get called before the song has finished loading its duration from the datafile.
    // Since we cannot assume we know the duration we cannot check it against the given start time.
    // Because the startTime can (currently) only be set by listening to the song we have to assume it will be < song duration.
    
    float floatStart = [startTime floatValue];
    if ( _songStatus == kSongStatusReady) {
        float floatDuration = CMTimeGetSeconds([self songDuration]);
        
        if ((floatStart < 0) || (floatStart > floatDuration)) {
            NSLog(@"setStartTime error: Start time is %f",floatStart);
            return;
        }
    }
    // This sets song.songStartTime which we are deprecating for teo.TEOData.selectedSweetSpot and teo.TEOData.sweetSpotArray
//    [self setSongStartTime:CMTimeMakeWithSeconds(floatStart, _songTimeScale)];
    
    self.oneOffStartTime = startTime;
    if (makeSS) {
        [self setSweetSpot:startTime];
    }
}

- (void)setSweetSpot:(NSNumber*)theSS {
    if ([theSS floatValue] == 0.0) {
        return;
    }

    self.TEOData.selectedSweetSpot = theSS;
}

- (void)storeSelectedSweetSpot {
    NSNumber* theSS = self.TEOData.selectedSweetSpot;
    if (theSS) {
        NSMutableSet* updatedSet = [self.TEOData.sweetSpots mutableCopy];
        // put the ss in the set
        [updatedSet addObject:theSS];
        self.TEOData.sweetSpots = [updatedSet copy];
    } else {
        NSLog(@"No sweet spot selected!");
    }
    
}

//MARK: Audio playback code.
- (NSNumber*)playStart {

    if ([self songStatus] == kSongStatusReady) {
        
        NSNumber* theTime;
        
        if (songPlayerItem == nil) {
            NSDate* preDate = [NSDate date];
            songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
            NSDate* postDate = [NSDate date];
            NSLog(@"Creating a new AVPlayerItem took: %f",[postDate timeIntervalSinceDate:preDate]);
//            songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[]];
        }
        
        // This is where I would add some KVO on the player item.
        // It needs to happen before we associate the player item with the player because
        // it may start changing things straight away.
//        [songPlayerItem addObserver:self
//                         forKeyPath:@"timebase"
//                            options:NSKeyValueObservingOptionNew
//                            context:presentationSizeObservationContext];
//        See WWDC14 503 at 33:40 and NSHipster's article http://nshipster.com/key-value-observing/
        
        if (songPlayer == nil) {
            NSDate* preDate = [NSDate date];
                
            //FIXME: repeated EXC_BAD_ACCESS crash here
            songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
            NSDate* postDate = [NSDate date];
            NSLog(@"Creating a new AVPlayer took: %f",[postDate timeIntervalSinceDate:preDate]);
        }
        [songPlayer setVolume:0.2];
        
        theTime = self.oneOffStartTime;
        if (theTime) {
            NSLog(@"Seeking to time %f as a one off",[theTime floatValue]);
            self.oneOffStartTime = nil;
            NSLog(@"The current time is %f",CMTimeGetSeconds([songPlayer currentTime]));
        } else {
            theTime = self.TEOData.selectedSweetSpot;
        }
        
        [songPlayer seekToTime:CMTimeMakeWithSeconds([theTime floatValue], 1)];

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
        return theTime;
    }
    return [NSNumber numberWithFloat:0];
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

- (void)setCache:(AVAudioFile*) theFile {
    NSAssert(theFile != nil, @"The audio file is nil!");
#ifdef AE
    _cachedFile = theFile;
    _cachedFileLength = _cachedFile.length;
#endif
    if( songPlayer ) {
        // First cancel any pending prerolls
        [songPlayer cancelPendingPrerolls];
        // Then set a new preroll request.
//        [songPlayer prerollAtRate:5 completionHandler:^{NSLog(@"Go preroll");}];
    }
    NSLog(@"cached file %@ of length %lld",_cachedFile,_cachedFileLength);
}

- (void)clearCache {
    _cachedFile = nil;
}

/**
    Immediately set the playhead to the given time offset.
    :Param: The offset in seconds.
 */
- (void)setCurrentPlayTime:(NSNumber *)playTimeInSeconds {
    double playTime = [playTimeInSeconds doubleValue];
//    NSLog(@"playTime %f",playTime);
    if ((playTime >= 0) && (playTime < CMTimeGetSeconds([self songDuration]))) {
        [songPlayer seekToTime:CMTimeMake(playTime*100, 100)];
    }
}

- (double)getDuration {
    return CMTimeGetSeconds([self songDuration]);
}

/// Gets the current play time in seconds.
- (Float64)getCurrentPlayTime {
    if (songPlayer != nil) {
        return CMTimeGetSeconds([songPlayer currentTime]);
    }
    return 0;
}


/*
/// Looks in the common metadata of the asset for the given string.
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
*/

@end
