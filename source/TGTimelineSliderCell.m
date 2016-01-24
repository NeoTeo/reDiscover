//
//  TGTimelineSliderCell.m
//  Proto3
//
//  Created by Teo Sartori on 22/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "rediscover-swift.h"
#import "TGTimelineSliderCell.h"
//#import "TGSweetSpotControl.h"
//#import "TGTimelineBarView.h"
//#import "TGSongTimelineViewController.h"

@implementation TGTimelineSliderCell


/**
 When the slider is released the signal is given to store the sweet spot at this position.
 */
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
    NSLog(@"Done tracking!");
    // Notify that the user has created a sweet spot at the current time.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserCreatedSweetSpot" object:nil];
//    [_theController userCreatedNewSweetSpot:<#(id)#>]
}

/**
    Grow the timeline bar and all the sweet spot controls to twice their current height.
    Called when the mouse pointer enters the slider cell area.
 */
-(void)mouseEntered:(NSEvent *)theEvent {
    
    int halfSweetSpot = kSweetSpotMarkerHeight/2;

    // Setting the view's animator frame uses AppKit animation (on the main thread) rather than Core Animation on a bg thread.
    // Tell the sweet spot controls to grow.
    for (TGSweetSpotControl *spot in [sweetSpotsView subviews]) {
        
        spot.animator.frame = NSRectFromCGRect(CGRectInset(spot.frame, -halfSweetSpot, -halfSweetSpot));
        

    }
    
    // Change the size of the barRect
    timelineBarView.animator.frame = NSRectFromCGRect(CGRectInset(barRect, 0, -4));
}

/**
 Shrink the timeline bar and all the sweet spot controls to half their current height.
 Called when the mouse pointer enters the slider cell area.
 */
-(void)mouseExited:(NSEvent *)theEvent {
    
    int halfSweetSpot = kSweetSpotMarkerHeight/2;
    
    for (TGSweetSpotControl *spot in [sweetSpotsView subviews]) {
        
        spot.animator.frame = NSRectFromCGRect(CGRectInset(spot.frame, halfSweetSpot, halfSweetSpot));
    }
    
    // Restore the size of the timeline bar.
    timelineBarView.animator.frame = barRect;
}

-(void)awakeFromNib {
    
//    NSRect theFrame = [_controlView frame];
    int frameHeight = (int)CGRectGetHeight([_controlView frame]);
    CGSize frameSize = [_controlView frame].size;
    
    // If the height of the control view frame is odd our halfway point is half+1 otherwise
    // just set it to half the height.
    int halfFrameHeight = frameHeight % 2 ? (frameHeight+1)/2 : frameHeight/2;
    
    // Setting the rect of the bar here since I can't seem to get it from the superclass.
    barRect = NSMakeRect(0, halfFrameHeight-kTimelineBarHeight/2, frameSize.width, kTimelineBarHeight);
    
    // Allow controlview to draw subviews' layers into its own.
    [_controlView setCanDrawSubviewsIntoLayer:YES];
    
    
    // Throws uncommitted CATransaction when not run on the main thread.
    // Need to find out whether I can commit transaction explicitly.
//    // Make it so that subviews can be drawn into the controlview's layer instead of their own.
//    [_controlView setWantsLayer:YES];
    
    sweetSpotsView = [[NSView alloc] initWithFrame:NSMakeRect(0,
                                                              2,
//                                                              halfFrameHeight-kSweetSpotMarkerHeight/2,
                                                              frameSize.width,
                                                              frameSize.height)];
    
    timelineBarView = [[TGTimelineBarView alloc] initWithFrame:barRect];

    knobImage = [NSImage imageNamed:@"ssButton"];
    knobImageView = [[NSImageView alloc] init];
    [knobImageView setImage:knobImage];
    
    [_controlView addSubview:timelineBarView];
    [_controlView addSubview:sweetSpotsView];
    [_controlView addSubview:knobImageView];
    
    
}

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    [self drawBarInside:[timelineBar frame] flipped:NO];
    
    // The actual drawing of the knob is done by the knobImageView itself. This updates its position.
    [self drawKnob];
}

// This messes with the drawing of the bar because it still draws its own on top.
// To avoid, override drawWithFrame.
//-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    [self drawBarInside:[timelineBar frame] flipped:NO];
//    [self drawKnob];
//}

-(void)drawKnob:(NSRect)knobRect {
    // Update the knob position.
    [knobImageView setFrame:knobRect];
}


-(NSNumber *)currentPlayheadPositionInPercent {
    return currentPlayheadPositionInPercent;
}


-(void)setCurrentPlayheadPositionInPercent:(NSNumber *)newCurrentPlayheadPositionInPercent {
    currentPlayheadPositionInPercent = newCurrentPlayheadPositionInPercent ;
    
    [timelineBarView setPlayheadPositionInPercent:[newCurrentPlayheadPositionInPercent doubleValue]];
    
    [_controlView setNeedsDisplay:YES];
//    NSLog(@"the controlview dims are %@",NSStringFromRect([_controlView frame]));
}

-(void)makeMarkersFromSweetSpots:(NSSet*)sweetSpots forSongDuration:(NSNumber *)songDuration {
    
    // Adding and removing subviews need to happen on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        int spotIndex = 0;
        // Clear out the existing sweet spot markers from the sweetSpotsView.
        [[sweetSpotsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
        
        // Add the new sweet spot markers.
        for (NSNumber *sspot in sweetSpots) {
            // skip on bogus duration
            if ([songDuration doubleValue] == 0) {NSLog(@"ERROR: Song duration is 0!");continue;}
            double ssXPos = CGRectGetWidth(barRect)/[songDuration doubleValue]*[sspot doubleValue];
            if(isnan(ssXPos) == YES || isfinite(ssXPos) == NO) {
                NSLog(@"Something wrong with ssXPos");
            }
            TGSweetSpotControl *aSSControl = [[TGSweetSpotControl alloc] initWithFrame:NSMakeRect(ssXPos,
                                                                                                  kSweetSpotMarkerHeight,
                                                                                                  kSweetSpotMarkerHeight,
                                                                                                  kSweetSpotMarkerHeight)];
            [aSSControl setTag:spotIndex++];
            [aSSControl setTarget:_theController];
            //        [aSSControl setAction:@selector(sweetspotMarkerAction:)];
            [aSSControl setAction:@selector(userSelectedExistingSweetSpot:)];
            [aSSControl setImage:knobImage];
            
            [sweetSpotsView addSubview:aSSControl];
        }
    });
}

/** REFAC
-(void)makeMarkersFromSweetSpots:(NSArray *)sweetSpots forSongDuration:(NSNumber *)songDuration {
    
    // Adding and removing subviews need to happen on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        int spotIndex = 0;
        // Clear out the existing sweet spot markers from the sweetSpotsView.
        [[sweetSpotsView subviews] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
        
        // Add the new sweet spot markers.
        for (NSNumber *sspot in sweetSpots) {
            // skip on bogus duration
            if ([songDuration doubleValue] == 0) {NSLog(@"ERROR: Song duration is 0!");continue;}
            double ssXPos = CGRectGetWidth(barRect)/[songDuration doubleValue]*[sspot doubleValue];
            if(isnan(ssXPos) == YES || isfinite(ssXPos) == NO) {
                NSLog(@"Something wrong with ssXPos");
            }
            TGSweetSpotControl *aSSControl = [[TGSweetSpotControl alloc] initWithFrame:NSMakeRect(ssXPos,
                                                                                                  kSweetSpotMarkerHeight,
                                                                            kSweetSpotMarkerHeight,
                                                                            kSweetSpotMarkerHeight)];
            [aSSControl setTag:spotIndex++];
            [aSSControl setTarget:_theController];
    //        [aSSControl setAction:@selector(sweetspotMarkerAction:)];
            [aSSControl setAction:@selector(userSelectedExistingSweetSpot:)];
            [aSSControl setImage:knobImage];
            
            [sweetSpotsView addSubview:aSSControl];
        }
    });
}
*/

-(void)drawSweetSpotsInView:(NSView *)theView {
    
}



@end
