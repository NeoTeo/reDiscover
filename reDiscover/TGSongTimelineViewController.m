//
//  TGSongTimelineViewController.m
//  Proto3
//
//  Created by Teo Sartori on 01/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSongTimelineViewController.h"
#import "TGTimelineSliderCell.h"
#import "TGSweetSpotControl.h"
#import "TGSongPool.h"


@interface TGSongTimelineViewController ()

@end

@implementation TGSongTimelineViewController

//@synthesize currentSong;

- (void)awakeFromNib {
    
    // The view of this controller is the popover view (in its own window)
    
    // We set up a mouse enter/exit tracking area so we can animate it.
    NSRect trackingRect = [self view].frame;
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                    initWithRect:trackingRect
                                    options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow )
                                    owner:_timelineBar.cell userInfo:nil];
//                                    owner:self userInfo:nil];
    
    [[self view] addTrackingArea:trackingArea];
//    TGTimelineSliderCell *thecell = _timelineBar.cell;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

//-(void)keyDown:(NSEvent *)theEvent {
////    [super keyDown:theEvent];
//    NSLog(@"key down in timeline controller");
//}

-(void)mouseEntered:(NSEvent *)theEvent {
// Initiate the animation that grows the timeline from a narrow strip to a taller strip with sweetspot handles.
    NSLog(@"The subviews are %@",[[self view] subviews]);
    NSLog(@"The slider layer is %@",[_timelineBar layer]);
    // The timeline bar's (an NSSlider) frame is NOT the bar inside it.
//    NSRect tlframe = [_timelineBar frame];
////    tlframe.origin.y += tlframe.size.height;
//    tlframe.size.height *=2;
//    [_timelineBar setFrame:tlframe];
}

-(void)mouseExited:(NSEvent *)theEvent {
    
    NSLog(@"eek mouse exited popover");
//    NSRect tlframe = [_timelineBar frame];
//    tlframe.origin.y -= tlframe.size.height;
//    tlframe.size.height /=2;
//    [_timelineBar setFrame:tlframe];
}
//-(void)mouseMoved:(NSEvent *)theEvent {
//    
//    NSLog(@"eek mouse moved in popover");
//}
-(void)mouseUp:(NSEvent *)theEvent {
    
    NSLog(@"mouse up in timeline controller");
    NSLog(@"the timeline value is %f",[_timelineBar doubleValue]);
}

- (void)sweetspotMarkerAction:(id)sender {
    // I would have preferred to set the slider's (timelineBar) value directly which, by being bound to the songpool's playheadPos, would
    // have updated the playhead, but because the slider works in percent I would not get the precision I want.
    
    // This should just pass up the chain that the user wanted to change sweet spots to x.
    // It in turn should tell the main controller which has a handle to the song pool and can call its setRequestedPlayheadPosition:
    // The delegate is the TGSongGridViewController
    [[self delegate] userSelectedSweetSpotMarkerAtIndex:[sender tag]];
    
}


//-(TGSong *)currentSong {
//    return currentSong;
//}

//-(void)setCurrentSongID:(NSInteger)songID fromSongPool:(TGSongPool *)theSongPool {
-(void)setCurrentSongID:(id)songID fromSongPool:(TGSongPool *)theSongPool {
    
    
    TGTimelineSliderCell *theCell = _timelineBar.cell;
    
    [theCell setTheController:self];
    
//    NSNumber *songDuration = [NSNumber numberWithDouble:CMTimeGetSeconds([theSong songDuration])];
    NSNumber *songDuration = [theSongPool songDurationForSongID:songID];
    NSArray *songSweetSpots = [theSongPool sweetSpotsForSongID:songID];
    
    [theCell makeMarkersFromSweetSpots:songSweetSpots forSongDuration:songDuration];
    
}

- (void)updateTimelinePositionWithTime:(CMTime)newTime {
        // The x position is: (the width of the timeline / the total time of the song) * newTime
    
}


//- (void)popGoesTheWeasel:(CGRect)theBounds :(NSView *)theView {
- (void)showTimelinePopoverRelativeToBounds:(CGRect)theBounds ofView:(NSView *)theView {
    [_songTimelinePopover showRelativeToRect:theBounds ofView:theView preferredEdge:CGRectMinYEdge];
//    [self setValue:[NSNumber numberWithDouble:42] forKey:@"arse"];
//    NSLog(@"the timelinebar %@",_timelineBar);
//    [_timelineBar setDoubleValue:69];
}
@end
