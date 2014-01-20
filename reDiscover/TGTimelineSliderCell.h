//
//  TGTimelineSliderCell.h
//  Proto3
//
//  Created by Teo Sartori on 22/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Forward class declaration
@class TGTimelineBarView;

static const int kSweetSpotMarkerHeight = 8;
static const int kTimelineBarHeight = 8;

@interface TGTimelineSliderCell : NSSliderCell 
{
    NSNumber *currentPlayheadPositionInPercent;
    NSNumber *currentSongDuration;
    
    NSRect barRect;
    TGTimelineBarView *timelineBar;
    NSView *sweetSpotsView;
    NSImage *knobImage;
    NSImageView *knobImageView;
}

-(void)makeMarkersFromSweetSpots:(NSArray *)sweetSpots forSongDuration:(NSNumber *)songDuration;

//-(void)mouseEntered:(NSEvent *)theEvent;
//-(void)mouseExited:(NSEvent *)theEvent;

@property NSArray *sweetSpotPositions;
@property id theController;

@end

