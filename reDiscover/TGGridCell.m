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

    
//    if (!NSIntersectsRect(cellFrame,controlView.frame)) {
//        NSLog(@"unnecessary display of point %@ inside %@",NSStringFromPoint(cellFrame.origin),NSStringFromRect(controlView.frame));
//    }
    NSImage *theImage = [self image];

    if (theImage) {
//        [theImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
        [theImage drawInRect:cellFrame fromRect:NSZeroRect operation:NSCompositeCopy fraction:1 respectFlipped:YES hints:nil];
        // 10.9 Mavericks version of the above [[self image] drawInRect:cellFrame];
        if (_tintColour != NULL) {
            [_tintColour set];
            
            NSRectFillUsingOperation(cellFrame,NSCompositeDestinationOver);
        } 
    }
    
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
//        
//    } completionHandler:^{
//        [super drawWithFrame:cellFrame inView:controlView];
//    }];
}

/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
//    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(myContext);
    //CGContextSetBlendMode(myContext, kCGBlendModeMultiply);
    CGContextSetRGBFillColor (myContext, 1, 0, 0, 0.3);// 3
    CGContextFillRect (myContext, cellFrame);// 4
    CGContextRestoreGState(myContext);
//    [CIContext contextWithCGContext:myContext options:nil];

    //CIContext *daContext = [[NSGraphicsContext currentContext] CIContext];

//    
//    CGContextSetFillColor(context, CGColorGetComponents((__bridge CGColorRef)([NSColor colorWithSRGBRed:30 green:10 blue:10 alpha:1])));
//    CGContextFillRect(context, cellFrame);
}
*/

/*
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:cellFrame inView:controlView];
    //[self setTitle:[NSString stringWithFormat:@"xpos: %f",cellFrame.origin.x]];
//    NSLog(@"is this really necessary?");
    // Here we should ask the model for the correct image if it's not already set.
    // For now it's just hardcoded in the init.
    if ([self tag] != -1) {
//        NSLog(@"drawing id %ld",[self tag]);

//        if (_songImage == nil) {
//            _songImage = [NSImage imageNamed:@"songImage"];
//        }
//        
////        [_songImage drawInRect:cellFrame fromRect:NSMakeRect(0, 0, _songImage.size.width, _songImage.size.height) operation:NSCompositeSourceOver fraction:1.0];
//        [_songImage drawInRect:cellFrame fromRect:NSMakeRect(0, 0, _songImage.size.width, _songImage.size.height) operation:NSCompositeCopy fraction:1.0 respectFlipped:YES hints:nil];
//        
//        controlView.layer.transform = CATransform3DMakeScale(0.6, 0.6, 0.6);
    }
    
//    NSTextField *cellText = [[NSTextField alloc] initWithFrame:cellFrame];
//    [cellText setStringValue:[NSString stringWithFormat:@"%f",cellFrame.origin.y]];
//    [controlView addSubview:cellText];
//    NSLog(@"yess. The frame is %@",NSStringFromRect(cellFrame));
}
*/
@end
