//
//  TGSong.m
//  Proto3
//
//  Created by Teo Sartori on 02/04/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSong.h"
#import <AVFoundation/AVFoundation.h>


@implementation TGSong

- (id)initWithURL:(NSURL *)anURL {
    
    self = [super init];
    if (self) {
        
        _songURL = anURL;
        _songTimeScale = 100; // Centiseconds.
        
        [self setSongStartTime:CMTimeMake(-1, 1)];
        _fingerprint = nil;
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
        songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:nil];
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


- (void)requestSongAlbumImage:(void (^)(NSImage *))imageHandler {

    if (songAsset == nil) {
        songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:nil];
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
            
            // At this point we check if other tracks in the same directory have embedded album art.
            
            // No luck. Call the image handler with nil.
            imageHandler(nil);
            
        });
    }];
}



// Just-in-time track data loading.
- (void)loadTrackData {
    
    // If the song is already loaded we just need to tell the delegate.
    if ([self songStatus] == kSongStatusReady) {
//        [self songDataHasLoaded];
        if ([[self delegate] respondsToSelector:@selector(songReadyForPlayback:)]) {
            [[self delegate] songReadyForPlayback:self];
        }
        return;
    }
           NSLog(@"song %@ is not cached.",self);
    
    // Start off marking this song as currently loading.
    [self setSongStatus:kSongStatusLoading];
    
//  Loading the asset with precise duration and timing significantly slows down playback response times.
    // If used, should only be enabled on songs that are not returning accurate timing values. (Eg. the Abba stuff)
//    NSDictionary *songLoadingOptions = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
//    songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:songLoadingOptions];
#pragma TEO can get stuck in here (Often!) semaphore_wait_trap
    songAsset = [[AVURLAsset alloc] initWithURL:_songURL options:nil];
    NSArray *keys = @[@"tracks",@"duration"];
    
    //NSLog(@"I gots %lu",(unsigned long)[artworks count]);
    
    [songAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        NSError *error = nil;
        AVKeyValueStatus assetStatus = [songAsset statusOfValueForKey:@"tracks"
                                                              error:&error];
        
        // At this point a load may have completed after we'd decided to remove the asset again,
        // eg. if the user moves quickly across songs.
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
                NSLog(@"URL track %@ load failed.",_songURL);
                [self setLoadStatus:kLoadStatusFailed];
                break;
            }
            case AVKeyValueStatusCancelled:
            {
                // Do whatever is appropriate for cancelation.
                [self setLoadStatus:kLoadStatusCancelled];
                break;
            }
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
                NSLog(@"URL duration %@ load failed.",_songURL);
                [self setLoadStatus:kLoadStatusDurationFailed];
                [self setSongStatus:kSongStatusFailed];
                break;
            }
        }
        
        if ([self songStatus] == kSongStatusReady) {
            //[self songDataHasLoaded];
            if ([[self delegate] respondsToSelector:@selector(songReadyForPlayback:)]) {
                [[self delegate] songReadyForPlayback:self];
            }
        }
    }];
}

- (void)loadSongMetadata {
    if (_songData == NULL) {
        
        NSString *titleString = @"no data.";
        NSString *albumString = @"no data.";
        NSString *artistString = @"no data.";
        NSString *genreString = @"Unknown";
        
        
        // Get other metadata via the MDItem of the file.
        MDItemRef metadata = MDItemCreate(NULL, (__bridge CFStringRef)[_songURL path]);
        if (metadata) {
            
            NSString *title, *album, *genre;
            NSArray* artists;
            
            if ((genre = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemMusicalGenre))))
                genreString = genre;
            
            if ((title = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemTitle))))
                titleString = title;
            
            if ((album = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAlbum))))
                albumString = album;
            
            if ((artists = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAuthors))))
                artistString = [artists objectAtIndex:0];
            
            // Make sure that sucker is released.
            CFRelease(metadata);
        }
        
        _songData = [[NSDictionary alloc] initWithObjects:@[titleString,albumString,artistString,genreString] forKeys:@[@"Title",@"Album",@"Artist",@"Genre"]];
    }
}

//- (void)loadSongMetadata {
//    
//    // At this point we can signal to the song pool that we are ready for playback and let it decide if it still wants playback.
//    // As this can be run in many separate threads but it only makes sense to play one song at a time we make sure the call to songReadyForPlayback
//    // is placed in a serial queue.
//    
//    if (_songData == NULL) {
//        NSString *titleString =[self getStringValueForStringKey:@"title" fromAsset:songAsset];
//        NSString *albumString =[self getStringValueForStringKey:@"albumName" fromAsset:songAsset];
//        NSString *artistString =[self getStringValueForStringKey:@"artist" fromAsset:songAsset];
//
//        NSString *genre;
//        
//        
//        // Get other metadata via the MDItem of the file.
//        MDItemRef metadata = MDItemCreate(NULL, (CFStringRef)[_songURL path]);
//        if (metadata) {
//            
//            genre = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemMusicalGenre));
//            
//            NSString *title, *album;
//            NSArray* artists;
//            
//            if ([titleString isEqualToString:@"no data."] && (title = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemTitle)))) {
//                titleString = title;
//            }
//            
//            if ([albumString isEqualToString:@"no data."] && (album = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAlbum)))) {
//                albumString = album;
//            }
//            
//            if ([artistString isEqualToString:@"no data."] && (artists = CFBridgingRelease(MDItemCopyAttribute(metadata, kMDItemAuthors)))) {
//                artistString = [artists objectAtIndex:0];
//            }
//            
//            // Make sure that sucker is released.
//            CFRelease(metadata);
//        }
//
//        // Set the default if no genre is found.
//        if (genre == NULL) {
//            genre = @"Unknown";
//        }
//        _songData = [[NSDictionary alloc] initWithObjects:@[titleString,albumString,artistString,genre] forKeys:@[@"Title",@"Album",@"Artist",@"Genre"]];
//    }
//
//    // TEO: Find out why some songs don't find the metadata (such as all the songs on The Cure - Disintegration) despite iTunes managing it.
////    NSArray *tracks =[songAsset tracksWithMediaType:AVMediaTypeAudio];
////    AVAssetTrack *aTrack = [tracks objectAtIndex:0];
////    NSLog(@"number of tracks %ld",[tracks count]);
////    NSArray *metadataFormats =[aTrack availableMetadataFormats];
////    NSLog(@"songdata has loaded a track %@",[aTrack commonMetadata]);
////    dispatch_async(songReadyToPlayQueue, ^{
//        //[[self delegate] songReadyForPlayback:self];
////    });
//    
//}


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

//// If the selectedSweetSpot is not -1 return the time it is pointing to.
//// Otherwise just return the beginning of the song.
//-(CMTime)songStartTime {
//    if ((_songSweetSpots != nil) && (_selectedSweetSpot < [_songSweetSpots count])) {
//        NSNumber *ssNum = [_songSweetSpots objectAtIndex:_selectedSweetSpot];
//        return CMTimeMakeWithSeconds([ssNum floatValue],_songTimeScale);
//    } else
//        return CMTimeMake(-1, 1);
//}

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
        

//        NSString *labelString = [NSString stringWithFormat:@"%@ by %@ from %@",[[self songData] objectForKey:@"Title"],[[self songData] objectForKey:@"Artist"],[[self songData] objectForKey:@"Album"]];
//        NSLog(@"about to play (%ld) %@ at position %f",_songID,labelString,CMTimeGetSeconds(_songStartTime));
//        NSLog(@"The song has UUID %@",_songUUIDString);

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

// Looks in the common metadata of the asset for the given string.
- (NSString *)getStringValueForStringKey:(NSString *)theString fromAsset:(AVURLAsset *)theAsset
{
    NSArray *songMeta = [theAsset commonMetadata];
    
    for (AVMetadataItem *item in songMeta ) {
        NSString *key = [item commonKey];
        NSString *value = [item stringValue];
        
        if ([key isEqualToString:theString]) {
            return value;
        }
    }
    return @"no data.";
}


@end
