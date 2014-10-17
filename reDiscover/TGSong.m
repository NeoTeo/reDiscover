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

#import <AVFoundation/AVFoundation.h>


@implementation TGSong

- (id)init {
    self = [super init];
    if (self) {
        
        _songTimeScale = 100; // Centiseconds.
        _fingerPrintStatus = kFingerPrintStatusEmpty;
        _SSCheckCountdown = 0;
        _artID = -1;
        _songDuration = CMTimeMakeWithSeconds(0, 1);
    }
    return self;
}


//TODO: Move to songpool?
- (void)searchMetadataForCoverImageWithHandler:(void (^)(NSImage *))imageHandler {

    if (songAsset == nil) {
        songAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.URLString] options:nil];
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

//MARK: Why is this not done asynchronously with...
// ...loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:
- (void)loadTrackDataWithCallBackOnCompletion:(BOOL)wantsCallback withStartTime:(NSNumber*)startTime {
//    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    NSURL *theURL = [NSURL URLWithString:self.URLString];
    [self setSongStatus:kSongStatusLoading];
    
    // What if the asset is already available?
    if (songAsset == nil) {
        songAsset = [AVAsset assetWithURL:theURL];
    }

// Enabling this, aside from slowing loading, also makes scrubbing laggy.
//        NSDictionary *songLoadingOptions = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
//        songAsset = [[AVURLAsset alloc] initWithURL:theURL options:songLoadingOptions];

    // Get the song duration.
    //    This may block which is just how we want it.
    if (CMTimeGetSeconds(self.songDuration) == 0) {
        [self setSongDuration:[songAsset duration]];
    }

    if ([songAsset isPlayable]) {
        [self setSongStatus:kSongStatusReady];
        
        if (!wantsCallback) return;
        //MARK: consider a closure instead.
        [[self delegate] songReadyForPlayback:self atTime:startTime];
    }
}

/**
    Load metadata from the file associated with this song and store it in the TEOData managed context.
 
    @returns YES on success and NO on failure to find any metadata. 
    In either case the TEOData will be set to some reasonable defaults.
 */
- (BOOL)loadSongMetadata {    
//    NSString *tmpString = [self.TEOData.urlString stringByDeletingPathExtension];
    NSString *tmpString = [self.URLString stringByDeletingPathExtension];
    NSString* fileName = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* album = [tmpString lastPathComponent];
    tmpString =[tmpString stringByDeletingLastPathComponent];
    NSString* artist = [tmpString lastPathComponent];
    
    // Get other metadata via the MDItem of the file.
//    NSURL *theURL = [NSURL URLWithString:self.TEOData.urlString];
    NSURL *theURL = [NSURL URLWithString:self.URLString];

    MDItemRef metadata = MDItemCreate(NULL, (__bridge CFStringRef)[theURL path]);
    
    // Add reasonable defaults
//    self.TEOData.artist = [artist stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.title  = [fileName stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.album  = [album stringByRemovingPercentEncoding];//@"Unknown";
//    self.TEOData.genre  = @"Unknown";
    self.artist = [artist stringByRemovingPercentEncoding];//@"Unknown";
    self.title  = [fileName stringByRemovingPercentEncoding];//@"Unknown";
    self.album  = [album stringByRemovingPercentEncoding];//@"Unknown";
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
        
        if (songPlayerItem == nil) {
//            NSDate* preDate = [NSDate date];
            songPlayerItem = [AVPlayerItem playerItemWithAsset:songAsset];
//            NSDate* postDate = [NSDate date];
//            NSLog(@"Creating a new AVPlayerItem took: %f",[postDate timeIntervalSinceDate:preDate]);
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
//            NSDate* preDate = [NSDate date];
            
            //FIXME: repeated EXC_BAD_ACCESS crash here
            songPlayer = [AVPlayer playerWithPlayerItem:songPlayerItem];
//            NSDate* postDate = [NSDate date];
//            NSLog(@"Creating a new AVPlayer took: %f",[postDate timeIntervalSinceDate:preDate]);
        }
        [songPlayer setVolume:0.2];
        
        
        if (startTime != nil) {
            [songPlayer seekToTime:CMTimeMakeWithSeconds([startTime floatValue], 1)];
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
        }
    }
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


@end
