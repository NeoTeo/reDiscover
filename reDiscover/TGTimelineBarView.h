//
//  TGTimelineBarView.h
//  Proto3
//
//  Created by Teo Sartori on 04/12/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TGTimelineBarView : NSView

@property double playheadPositionInPercent;

- (NSPoint)knobPosition;


@end
