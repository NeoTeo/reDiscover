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
#import "TGSongProtocol.h"
/*
@implementation TGSong

- (id)init {
    self = [super init];
    if (self) {
        _fingerPrintStatus = kFingerPrintStatusEmpty;
        _SSCheckCountdown = 0;
        _artID = nil;
        _songDuration = CMTimeMakeWithSeconds(0, 1);
    }
    return self;
}


- (id)copy {
    return [self copyWithZone:nil];
}

- (id)copyWithZone:(NSZone *)zone {
    TGSong *newSong = [[TGSong alloc] init];
    newSong.metadata            = self.metadata;    // is declared as a copy
    
    newSong.album               = [self.album copy];
    newSong.artist              = [self.artist copy];
    newSong.sweetSpots          = [self.sweetSpots copy];
    newSong.urlString           = [self.urlString copy];
    newSong.uuid            	= [self.uuid copy];
    newSong.year            	= [self.year copy];
    newSong.fingerprint     	= [self.fingerprint copy];
    newSong.title           	= [self.title copy];
    newSong.genre               = [self.genre copy];
    newSong.selectedSweetSpot   = [self.selectedSweetSpot copy];
    newSong.songReleases        = [self.songReleases copy];
    newSong.songID              = self.songID ;//[self.songID copy];
    newSong.fingerPrintStatus   = self.fingerPrintStatus;
    newSong.songDuration        = self.songDuration;

    return newSong;
}

 - (NSNumber*)currentSweetSpot {
    return self.TEOData.selectedSweetSpot;
    return self.selectedSweetSpot;
}

- (void)makeSweetSpotAtTime:(NSNumber*)startTime {
    float floatStart = [startTime floatValue];
    if ( _songStatus == kSongStatusReady) {
        float floatDuration = CMTimeGetSeconds([self songDuration]);
        
        if ((floatStart < 0) || (floatStart > floatDuration)) {
            TGLog(TGLOG_ALL,@"setStartTime error: Start time is %f",floatStart);
            return;
        }
    }
    
    [self setSweetSpot:startTime];
}

- (void)setSweetSpot:(NSNumber*)theSS {
    if ([theSS floatValue] == 0.0) {
        return;
    }

    self.TEOData.selectedSweetSpot = theSS;
    self.selectedSweetSpot = theSS;
}



 Add the selected sweet spot to the song's sweetSpots array.
 It is not saved to disk yet.

- (void)storeSelectedSweetSpot {

    NSNumber* theSS = self.selectedSweetSpot;
    if (theSS) {

        NSMutableArray* updatedSS = [NSMutableArray arrayWithArray:self.sweetSpots];
        FIXME: Use an NSSet to avoid dupes
         put the ss in the array
        [updatedSS addObject:theSS];

        self.sweetSpots = [updatedSS copy];
    } else {
        TGLog(TGLOG_ALL,@"No sweet spot selected!");
    }
    
}


@end
*/