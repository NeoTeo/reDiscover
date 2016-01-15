//
//  TGTimelineBarView.m
//  Proto3
//
//  Created by Teo Sartori on 04/12/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGTimelineBarView.h"

@implementation TGTimelineBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _playheadPositionInPercent = 0;
    }
    return self;
}

- (NSPoint)knobPosition {
    NSRect aRect = [self bounds];
    return NSMakePoint(CGRectGetWidth(aRect)/100*_playheadPositionInPercent, CGRectGetMidY(aRect));
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    NSRect aRect = [self bounds];
    [[NSColor lightGrayColor] setFill];
    NSRectFill(aRect);
    
    // Calculate the width of the rect based on current playhead position
    double wid = CGRectGetWidth(aRect)/100*_playheadPositionInPercent;
    NSRect playbackRect = NSMakeRect(aRect.origin.x+1,aRect.origin.y+1, wid, aRect.size.height-2);
    [[NSColor darkGrayColor] setFill];
    NSRectFill(playbackRect);
    
//    [[NSColor greenColor] setFill];
//    NSRect testRect = NSMakeRect(0, 0, 20, 2);
//    NSRectFill(testRect);
}

@end
