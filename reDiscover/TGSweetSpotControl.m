//
//  TGSweetSpotControl.m
//  Proto3
//
//  Created by Teo Sartori on 27/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSweetSpotControl.h"

@implementation TGSweetSpotControl

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

/*
- (void)mouseEntered:(NSEvent *)theEvent {
    NSLog(@"mouse entered sweet spot");
}

-(void)mouseExited:(NSEvent *)theEvent {
    NSLog(@"mouse exited sweet spot");
}

- (void)enableTracking {
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                    initWithRect:self.animator.frame
                                    options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways )
                                    owner:self userInfo:nil];
    
    [self addTrackingArea:trackingArea];
}
*/

- (void)drawRect:(NSRect)dirtyRect
{
    [[self image] drawInRect:dirtyRect];
//	[super drawRect:dirtyRect];
	
//    [[NSColor blueColor] setFill];
//    // Drawing code here.
//    NSRectFill(dirtyRect);
}

@end
