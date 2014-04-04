//
//  TGGridCell.m
//  Proto3
//
//  Created by Teo Sartori on 15/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGGridCell.h"
#import <QuartzCore/CoreImage.h>

@implementation TGGridCell

- (id)init {
    self = [super init];
    if (self) {
        // This is where we should request a song reference from the songsmodel via this cell's controller.
        NSLog(@"cell innit");
        [self setTag:-1];
        
//        [self setSongImage:nil];
//        [self setImage:[NSImage imageNamed:@"songImage"]];
    }
    return self;
}


// This tracks the mouse down in a cell. Called if a superview doesn't catch it first (eg. the matrix).
//-(BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
//    return YES;
//}


//- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
//{
//    // Only called on mouse down.
//    NSLog(@"tracking %@",NSStringFromPoint(startPoint));
//    NSLog(@"The control view is %@",[self controlView]);
//}

// The controlView passed in is the matrix view which is (the content view of the scroll view) being scrolled around.
// The cell frame is dimension of the cell that we're drawing.
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

    NSImage *theImage = [self image];

    if (theImage) {
        
//        [theImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeCopy fraction:1 respectFlipped:YES hints:nil];
        // 10.9 Mavericks version of the above. Might want to check for OS version for backward compatibility.
        [[self image] drawInRect:cellFrame];
        if (_tintColour != NULL) {
            [_tintColour set];
            
            NSRectFillUsingOperation(cellFrame,NSCompositeDestinationOver);
        } 
    }
}

@end
