//
//  TGSong.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSong.h"
#import "TGSongPool.h"
#import "TEOSongData.h"
#import "NSImage+TGHashId.h"

#import <AVFoundation/AVFoundation.h>


@implementation TGSong

- (id)init {
    self = [super init];
    if (self) {
        
        _songTimeScale = 100; // Centiseconds.
        _fingerPrintStatus = kFingerPrintStatusEmpty;
        _SSCheckCountdown = 0;
        _artID = nil;
        _songDuration = CMTimeMakeWithSeconds(0, 1);
        _songStatus = kSongStatusUninited;
        _serialTestQueue = dispatch_queue_create("serial test queue", NULL);
    }
    return self;
}


//TODO: Move to songpool?
- (void)searchMetadataForCoverImageWithHandler:(void (^)(NSImage *))imageHandler {

    if (songAsset == nil) {
        /// This initializes the asset with the song's url.
        ///Since the options are nil the default will be to not require precise timing.
        songAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.urlString] options:nil];
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
}

//- (void)performBlockWhenReadyForPlayback:(void (^)(void))completionBlock {
//    if ([self songStatus] == kSongStatusReady) {
//        completionBlock();
//    } else {
//        //if ([self songStatus] == kSongStatusLoading) {
//            self.customBlock = (MyCustomBlock)completionBlock;
////        } else {
////            NSLog(@"ERROR: Song status is %ld. Returning without setting completion block.",[self songStatus]);
////        }
//    }
//}

// Make the context point to its own pointer.
static const void *ItemStatusContext = &ItemStatusContext;

- (void)prepareForPlayback {
    
    if ([self songStatus] == kSongStatusReady) {
        return ;
    }
    //CACH2
    if ([self songStatus] == kSongStatusLoading) {
        NSLog(@"Song %@ was already loading. Returning.",self.songID);
        return;
    }
    
    NSURL *theURL = [NSURL URLWithString:self.urlString];
    [self setSongStatus:kSongStatusLoading];
    NSLog(@"------------------------------------------------------------------------------------ Song %@ is now loading.",self.songID);
    if (songAsset == nil) {
        /// This initializes the asset with the song's url.
        ///Since the options are nil the default will be to not require precise timing.
        songAsset = [AVAsset assetWithURL:theURL];
    }
    if (CMTimeGetSeconds(self.songDuration) == 0) {
        
        // [songAsset duration] may block for a bit which is just how we want it.
        // WHY?
        // Because, since this whole method is sitting in an op queue, if it takes too long
        // and the user moves on to another song that should be played instead it and all the
        // subsequent queued calls can be cancelled.
        // If it just returned immediately there would be a large uncancellable backlog of song asset loads.
        [self setSongDuration:[songAsset duration]];
        
        NSError* error;
        AVKeyValueStatus tracksStatus = [songAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                // Prepare the asset for playback by loading its tracks.
                [songAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
                    // Now, associate the asset with the player item.
                    if (songPlayerItem == nil) {
                        songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
                        // Observe the status keypath of the songPlayerItem. When the status changes to ready self.customBlock will be called.
                        [songPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                    }
                    
                    // This will trigger the player's preparation to play.
                    if (songPlayer == nil) {
                        songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
                    }
                }];
                
                break;
            }
            case AVKeyValueStatusFailed:
                NSLog(@"There was an error getting track duration.");
                break;
            default:
                NSLog(@"The track is not (yet) loaded!");
                break;
        }
    }
}

- (void)performWhenReadyForPlayback:(void (^)(void))completionBlock {
    // Set the completion block to be called when the songPlayerItem's status changes to ready.
    self.customBlock = (MyCustomBlock)completionBlock;
    
    // If the song is ready to play, just call the completion block and return.
    if ([self songStatus] == kSongStatusReady) {
        NSLog(@"performWhenReadyForPlayback: Song was ready. Calling completion block.");
        completionBlock();
        return;
    }
    
    // If the song is currently loading (waiting for the status to change to ready) then set the completionBlock to call.
    // Note this will overwrite any existing completion block.
    if ([self songStatus] == kSongStatusLoading) {
        NSLog(@"performWhenReadyForPlayback: song is Loading. Replacing completion block.");
        self.customBlock = (MyCustomBlock)completionBlock;
        return;
    }
}

/* CDFIX
- (void)prepareForPlaybackWithCompletionBlock:(void (^)(void))completionBlock {
    //dispatch_async(_serialTestQueue, ^{
        // Set the completion block to be called when the songPlayerItem's status changes to ready.
        self.customBlock = (MyCustomBlock)completionBlock;

    // If the song is ready to play, just call the completion block and return.
    if ([self songStatus] == kSongStatusReady) {
        NSLog(@"prepareForPlayback song was already prepared. Calling completion block.");
        completionBlock();
        return;
    }
    
    // If the song is currently loading (waiting for the status to change to ready) then set the completionBlock to call.
    // Note this will overwrite any existing completion block.
    if ([self songStatus] == kSongStatusLoading) {
        NSLog(@"prepareForPlayback song is already loading. Replacing completion block.");
        self.customBlock = (MyCustomBlock)completionBlock;
        return;
    }
    
    NSURL *theURL = [NSURL URLWithString:self.urlString];
    [self setSongStatus:kSongStatusLoading];
    
    if (songAsset == nil) {
        /// This initializes the asset with the song's url.
        ///Since the options are nil the default will be to not require precise timing.
        songAsset = [AVAsset assetWithURL:theURL];
    }
    if (CMTimeGetSeconds(self.songDuration) == 0) {
        
        // [songAsset duration] may block for a bit which is just how we want it.
        // WHY?
        // Because, since this whole method is sitting in an op queue, if it takes too long
        // and the user moves on to another song that should be played instead it and all the
        // subsequent queued calls can be cancelled.
        // If it just returned immediately there would be a large uncancellable backlog of song asset loads.
        [self setSongDuration:[songAsset duration]];
        
        
        NSError* error;
        AVKeyValueStatus tracksStatus = [songAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                // Prepare the asset for playback by loading its tracks.
                [songAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
                    // Now, associate the asset with the player item.
                    if (songPlayerItem == nil) {
                        songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
                        // Observe the status keypath of the songPlayerItem. When the status changes to ready self.customBlock will be called.
                        [songPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                    }
                    
                    // This will trigger the player's preparation to play.
                    if (songPlayer == nil) {
                        songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
                    }
                    
//                    // Set the completion block to be called when the songPlayerItem's status changes to ready.
//                    self.customBlock = (MyCustomBlock)completionBlock;
                    
                }];
                
                break;
            }
            case AVKeyValueStatusFailed:
                NSLog(@"There was an error getting track duration.");
                break;
            default:
                NSLog(@"The track is not (yet) loaded!");
                break;
        }
    }
    //});
}
CDFIX */

- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback withStartTime:(NSNumber*)startTime {

    NSURL *theURL = [NSURL URLWithString:self.urlString];
    [self setSongStatus:kSongStatusLoading];
    
    if (songAsset == nil) {
        /// This initializes the asset with the song's url.
        ///Since the options are nil the default will be to not require precise timing.
        songAsset = [AVAsset assetWithURL:theURL];
    }

    // Enabling this, aside from slowing loading, also makes scrubbing laggy.
//        NSDictionary *songLoadingOptions = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
//        songAsset = [[AVURLAsset alloc] initWithURL:theURL options:songLoadingOptions];
    
    if (CMTimeGetSeconds(self.songDuration) == 0) {

        // [songAsset duration] may block for a bit which is just how we want it.
        // WHY?
        // Because, since this whole method is sitting in an op queue, if it takes too long
        // and the user moves on to another song that should be played instead it and all the
        // subsequent queued calls can be cancelled.
        // If it just returned immediately there would be a large uncancellable backlog of song asset loads.
        [self setSongDuration:[songAsset duration]];
        
        
        NSError* error;
        AVKeyValueStatus tracksStatus = [songAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                // Prepare the asset for playback by loading its tracks.
                [songAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
                    // Now, associate the asset with the player item.
                    if (songPlayerItem == nil) {
                        songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
                        // Observe the status keypath of the songPlayerItem.
                        [songPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                    }
                    
                    // This will trigger the player's preparation to play.
                    if (songPlayer == nil) {
                        songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
                    }

                    if (!wantsCallback) return;
                    /// This creates a block that will effect the delegate callback and adds it to the customBlock property.
                    //  This block will be called by the observeValueForKeypath: method that is called when the songPlayerItem is ready
                    // thus ensuring songReadyForPlayback is not called too early.
                    // The block is necessary to be able to capture the startTime as it is not possible to (safely) pass a value through
                    // the observeValueForKeypath method.
                    
                    // Make a weakly retained self for use inside the block to avoid retain cycle.
                    __unsafe_unretained typeof(self) weakSelf = self;

                    self.customBlock = ^{
                        [[weakSelf delegate] songReadyForPlayback:weakSelf atTime:startTime];
                    };

                }];
            
                break;
            }
            case AVKeyValueStatusFailed:
                NSLog(@"There was an error getting track duration.");
                break;
            default:
                NSLog(@"The track is not (yet) loaded!");
                break;
        }
        
        //}];
    }
//    // Get the song duration.
//    //    This may block which is just how we want it.
//    if (CMTimeGetSeconds(self.songDuration) == 0) {
//        [self setSongDuration:[songAsset duration]];
//    }
////FIXME: What is to keep this from not failing if the asset is not ready? Why not as mentioned above?
//    if ([songAsset isPlayable]) {
//        [self setSongStatus:kSongStatusReady];
//
//        if (!wantsCallback) return;
//        //MARK: consider a closure instead.
//        [[self delegate] songReadyForPlayback:self atTime:startTime];
//    }
}

/**
    Load metadata from the file associated with this song and store it in the TEOData managed context.
 
    @returns YES on success and NO on failure to find any metadata. 
    In either case the TEOData will be set to some reasonable defaults.
 */
- (BOOL)loadSongMetadata {
    //TODO: use the verbose url type.
//    NSString *tmpString = [self.TEOData.urlString stringByDeletingPathExtension];
    NSString *tmpString = [self.urlString stringByDeletingPathExtension];
    NSString* fileName = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* album = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* artist = [tmpString lastPathComponent];
    
    // Get other metadata via the MDItem of the file.
//    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    NSURL *theURL = [NSURL URLWithString:self.urlString];

    MDItemRef metadata = MDItemCreate(NULL, (__bridge CFStringRef)[theURL path]);
    
    // Add reasonable defaults
//    self.TEOData.artist = [artist stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.title  = [fileName stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.album  = [album stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.genre  = @"Unknown";
    self.artist = [artist stringByRemovingPercentEncoding];//@"Unknown";
    self.title  = [fileName stringByRemovingPercentEncoding];//@"Unknown";
    self.album  = @"Unknown";//[album stringByRemovingPercentEncoding];//@"Unknown";
    self.genre  = @"Unknown";
    
    if (metadata) {
        NSString* aString;
        NSArray* artists;
        
        if ((artists = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAuthors)))) {
//           self.TEOData.artist = [artists objectAtIndex:0];
            self.artist = [artists objectAtIndex:0];
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemTitle)))) {
            //self.TEOData.title = aString;
            self.title = aString;
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAlbum)))) {
            //self.TEOData.album = aString;
            self.album = aString;
        }
        
        if ((aString = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemMusicalGenre)))) {
            //self.TEOData.genre = aString;
            self.genre = aString;
        }
        
        // Make sure that sucker is released.
        CFRelease(metadata);
        return YES;
    }
    return NO;
}

/**
 Return the start time for this song.
 
 If the song has a previously set one-off start time set it will destructively return it.
 Otherwise it returns this song's selected sweet spot.
 
 @returns Start time in seconds.
 */
//- (NSNumber *)startTime {
//
//    if (self.oneOffStartTime) {
//        return self.oneOffStartTime;
//    }
//    return self.TEOData.selectedSweetSpot;
//}
- (NSNumber*)currentSweetSpot {
    //return self.TEOData.selectedSweetSpot;
    return self.selectedSweetSpot;
}

- (void)makeSweetSpotAtTime:(NSNumber*)startTime {
    float floatStart = [startTime floatValue];
    if ( _songStatus == kSongStatusReady) {
        float floatDuration = CMTimeGetSeconds([self songDuration]);
        
        if ((floatStart < 0) || (floatStart > floatDuration)) {
            NSLog(@"setStartTime error: Start time is %f",floatStart);
            return;
        }
    }
    
    [self setSweetSpot:startTime];
}

/**
 Set the start time for this song.
 If the makeSS is true a permanent sweet spot is set to the requested time and is set as the currently selected sweet spot.
 If the makeSS is false the start time is set as a on-off and will not affect the sweet spots.
 
 @params startTime The offset, in seconds, from the beginning of the song (time 0) that we wish this song to start playing from.
 @params makeSS A Bool to signal whether to make the start time a one-off or store it as a sweet spot.
 */
//- (void)setStartTime:(NSNumber *)startTime makeSweetSpot:(BOOL)makeSS {
//    
//    float floatStart = [startTime floatValue];
//    if ( _songStatus == kSongStatusReady) {
//        float floatDuration = CMTimeGetSeconds([self songDuration]);
//        
//        if ((floatStart < 0) || (floatStart > floatDuration)) {
//            NSLog(@"setStartTime error: Start time is %f",floatStart);
//            return;
//        }
//    }
//    
//    self.oneOffStartTime = startTime;
//    
//    if (makeSS) {
//        [self setSweetSpot:startTime];
//    }
//}

- (void)setSweetSpot:(NSNumber*)theSS {
    if ([theSS floatValue] == 0.0) {
        return;
    }

    //self.TEOData.selectedSweetSpot = theSS;
    self.selectedSweetSpot = theSS;
}

/**
 Mark this song's selectedSweetSpot for saving.
 
 By moving the selectedSweetSpot into the TEOData.sweetSpots collection, which is backed by
 a core data store, it gets saved on a subsequent call to a songpool save.
 If the selectedSweetSpot it is set to the very beginning of the song it will be ignored 
 because songs without sweet spots play from the beginning by default.
 */
- (void)storeSelectedSweetSpot {
    //NSNumber* theSS = self.TEOData.selectedSweetSpot;
    NSNumber* theSS = self.selectedSweetSpot;
    if (theSS) {
//        NSMutableArray* updatedSS = [NSMutableArray arrayWithArray:self.TEOData.sweetSpots];
        NSMutableArray* updatedSS = [NSMutableArray arrayWithArray:self.sweetSpots];
        //MARK: Add a check for dupes.
        // put the ss in the array
        [updatedSS addObject:theSS];

        //self.TEOData.sweetSpots = [updatedSS copy];
        self.sweetSpots = [updatedSS copy];
    } else {
        NSLog(@"No sweet spot selected!");
    }
    
}

//MARK: Audio playback code.
- (void)playAtTime:(NSNumber*)startTime {

    if ([self songStatus] == kSongStatusReady) {
        [songPlayer setVolume:0.2];
        
        // Start observing the song playback so we can update UI.
        [self setSongPlaybackObserver];
        
        if (startTime != nil) {
            [songPlayer seekToTime:CMTimeMakeWithSeconds([startTime floatValue], 1)];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:songPlayerItem];
            
            [songPlayer play];
        }
    }
}

- (void)setSongPlaybackObserver {
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
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        if (object == songPlayerItem && [keyPath isEqualToString:@"status"]) {
            if (songPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                [self setSongStatus:kSongStatusReady];
                    NSLog(@"------------------------------------------------------------------------------------ Song %@ is now ready.",self.songID);
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"songStatusNowReady" object:self];
                
                if (self.customBlock != nil) {
                    self.customBlock();
                    // reset it.
                    self.customBlock = nil;
                }
            }
        }
        
//        if ((object == songPlayer) && [keyPath isEqualToString:@"status"]) {
//            if (songPlayer.status == AVPlayerStatusReadyToPlay) {
//                //[songPlayer play];
//                NSLog(@"Now the songPlayer is ready apparently.");
//                
//            } else if (songPlayer.status == AVPlayerStatusFailed) {
//                // something went wrong. player.error should contain some information
//                NSLog(@"Something went wrong with playback");
//            }
//        }
        return;
    }
    
    // The context isn't ours so call super with it so the call isn't lost.
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)playDidFinish {
    if ([[self delegate] respondsToSelector:@selector(songDidFinishPlayback:)]) {
        [[self delegate] songDidFinishPlayback:self];
    }
}


//- (void)setStartTime:(NSNumber*)startTime forPlayer:(AVPlayer*)thePlayer {
////    [thePlayer prerollAtRate:1.0 completionHandler:^(BOOL finished) {
//    
////        if (finished == NO) {
////            return ;
////        }
//        [songPlayer setVolume:0.2];
//        
//        if (startTime != nil) {
//            [songPlayer seekToTime:CMTimeMakeWithSeconds([startTime floatValue], 1)];
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:songPlayerItem];
//            
//            if (playerObserver == nil) {
//                // Add a periodic observer so we can update the timeline GUI.
//                CMTime eachSecond = CMTimeMake(10, 100);
//                dispatch_queue_t timelineSerialQueue = [_delegate serialQueue];
//                
//                // Make a weakly retained self for use inside the block to avoid retain cycle.
//                __unsafe_unretained typeof(self) weakSelf = self;
//                
//                // Every 1/10 of a second update the delegate's playhead position variable.
//                playerObserver = [songPlayer addPeriodicTimeObserverForInterval:eachSecond queue:timelineSerialQueue usingBlock:^void(CMTime time) {
//                    
//                    CMTime currentPlaybackTime = [weakSelf->songPlayer currentTime];
//                    [[weakSelf delegate] songDidUpdatePlayheadPosition:[NSNumber numberWithDouble:CMTimeGetSeconds(currentPlaybackTime)]];
//                }];
//            }
//        }
//        
////    }];
//}


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
//MARK: SPEED
#pragma TEO: The unloading is not yet implemented. By setting the song status to something other than ready we reload it every time we play it.
    [self setLoadStatus:kLoadStatusUnloaded];
    [self setSongStatus:kSongStatusUnloading];
    }
}

- (void)setCache:(AVAudioFile*) theFile {
//    NSAssert(theFile != nil, @"The audio file is nil!");
//#ifdef AE
//    _cachedFile = theFile;
//    _cachedFileLength = _cachedFile.length;
//#endif
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
    //CDFIX
    if ([self songStatus] == kSongStatusReady) {
        
//        // Unregister observers
//        if (songPlayer) {
//            [songPlayer removeTimeObserver:playerObserver];
//        }
//
//        if (songPlayerItem) {
//            [songPlayerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
//        }
        
//        songPlayer = nil;
//        songAsset = nil;
//        songPlayerItem = nil;
        
        NSLog(@"~~~~~~~~~~~~~~~~~~~~~~~~ Song with Id: %@ has been cleared.",[self songID]);
        [self setSongStatus:kSongStatusUninited];
    }

}

/**
    Immediately set the playhead to the given time offset.
 
    @Params The offset in seconds.
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

- (BOOL)isReadyForPlayback {
    return [self songStatus] == kSongStatusReady;
}

/*
/// TEOSongData access methods.
/// These are provided to ensure that access is done through the managed object context.
- (NSDictionary*)songMetaData {
    
    if (_songPoolAPI == nil) { return nil; }
    
    __block NSDictionary* metaDataDict = nil;
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        // Not sure here, but I think I need to copy the various elements because they are part of a Managed Object
        metaDataDict = @{
                         @"Album"               : self.TEOData.album,
                         @"Artist"              : self.TEOData.artist,
                         @"Sweetspots"          : self.TEOData.sweetSpots,
                         @"URLString"           : self.TEOData.urlString,
                         @"UUID"                : self.TEOData.uuid,
                         @"Year"                : self.TEOData.year,
                         @"Fingerprint"         : self.TEOData.fingerprint,
                         @"Title"               : self.TEOData.title,
                         @"Genre"               : self.TEOData.genre,
                         @"SelectedSweetSpot"   : self.TEOData.selectedSweetSpot
                         };
    }];
    
    return metaDataDict;
}

- (void)setSongMetaData:(NSDictionary*)newMetaData {
    
    if (_songPoolAPI == nil) { return; }
    
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        NSString* album         = [newMetaData objectForKey:@"Album"];
        NSString* artist        = [newMetaData objectForKey:@"Artist"];
        NSArray* sweetSpots     = [newMetaData objectForKey:@"SweetSpots"];
        NSString* uRL           = [newMetaData objectForKey:@"URLString"];
        NSString* uUID          = [newMetaData objectForKey:@"UUID"];
        NSNumber* year          = [newMetaData objectForKey:@"Year"];
        NSString* fingerprint   = [newMetaData objectForKey:@"Fingerprint"];
        NSString* title         = [newMetaData objectForKey:@"Title"];
        NSString* genre         = [newMetaData objectForKey:@"Genre"];
        NSNumber* selectedSS    = [newMetaData objectForKey:@"SelectedSweetSpot"];
        
        if (album) { self.TEOData.album = album; }
        if (artist) { self.TEOData.artist = artist; }
        if (sweetSpots) { self.TEOData.sweetSpots = sweetSpots; }
        if (uRL) { self.TEOData.urlString = uRL; }
        if (uUID) { self.TEOData.uuid = uUID; }
        if (year) { self.TEOData.year = year; }
        if (fingerprint) { self.TEOData.fingerprint = fingerprint; }
        if (title) { self.TEOData.title = title; }
        if (genre) { self.TEOData.genre = genre; }
        if (selectedSS) { self.TEOData.selectedSweetSpot = selectedSS; }
    }];
}

- (NSString*)album {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.album;
    }];
    return theString;
}
- (void)setAlbum:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.album = theString;
    }];
}

- (NSString*)artist {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.artist;
    }];
    return theString;
}
- (void)setArtist:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.artist = theString;
    }];
}

- (NSArray*)sweetSpots {
    __block NSArray* theArray = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theArray = self.TEOData.sweetSpots;
    }];
    return theArray;
}
- (void)setSweetSpots:(NSArray*)theArray {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.sweetSpots = theArray;
    }];
}

- (NSString*)URLString {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.urlString;
    }];
    return theString;
}
- (void)setURLString:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.urlString = theString;
    }];
}

- (NSString*)UUID {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.uuid;
    }];
    return theString;
}
- (void)setUUID:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.uuid = theString;
    }];
}

- (NSNumber*)year {
    __block NSNumber* theNumber = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theNumber = self.TEOData.year;
    }];
    return theNumber;
}
- (void)setYear:(NSNumber*)theNumber {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.year = theNumber;
    }];
}

- (NSString*)fingerprint {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.fingerprint;
    }];
    return theString;
}
- (void)setFingerprint:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.fingerprint = theString;
    }];
}

- (NSString*)title {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.title;
    }];
    return theString;
}
- (void)setTitle:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.title = theString;
    }];
}

- (NSString*)genre {
    __block NSString* theString = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theString = self.TEOData.genre;
    }];
    return theString;
}
- (void)setGenre:(NSString*)theString {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.genre = theString;
    }];
}

- (NSNumber*)selectedSweetSpot {
    __block NSNumber* theNumber = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theNumber = self.TEOData.selectedSweetSpot;
    }];
    return theNumber;
}
- (void)setSelectedSweetSpot:(NSNumber*)theNumber {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.selectedSweetSpot = theNumber;
    }];
}

- (NSData*)songReleases {
    __block NSData* theData = nil;
    [_songPoolAPI.TEOSongDataMOC performBlockAndWait:^{
        theData = self.TEOData.songReleases;
    }];
    return theData;
}
- (void)setSongReleases:(NSData*)theData {
    [_songPoolAPI.TEOSongDataMOC performBlock:^{
        self.TEOData.songReleases = theData;
    }];
}
*/

@end
