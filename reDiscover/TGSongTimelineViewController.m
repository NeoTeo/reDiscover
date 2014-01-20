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
#import "TGSong.h"


@interface TGSongTimelineViewController ()

@end

@implementation TGSongTimelineViewController

@synthesize currentSong;

- (void)awakeFromNib {
    NSLog(@"timeline awoken");
    NSLog(@"Its view is %@",[self view]);
    NSLog(@"the timelinepopover view is %@",_songTimelinePopover);
    
    // The view of this controller is the popover view (in its own window)
    
    // We set up a mouse enter/exit tracking area so we can animate it.
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                    initWithRect:[self view].frame
                                    options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow )
                                    owner:_timelineBar.cell userInfo:nil];
//                                    owner:self userInfo:nil];
    
    [[self view] addTrackingArea:trackingArea];
    TGTimelineSliderCell *thecell = _timelineBar.cell;
    NSLog(@"the cell size is %@",NSStringFromRect(thecell.controlView.frame));
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
    [[self delegate] userSelectedSweetSpotMarkerAtIndex:[sender tag]];
    
}


-(TGSong *)currentSong {
    return currentSong;
}

-(void)setCurrentSong:(TGSong *)theSong {
    
    currentSong = theSong;
    
    TGTimelineSliderCell *theCell = _timelineBar.cell;
    
    [theCell setTheController:self];
    
    NSNumber *songDuration = [NSNumber numberWithDouble:CMTimeGetSeconds([theSong songDuration])];
    [theCell makeMarkersFromSweetSpots:[theSong songSweetSpots] forSongDuration:songDuration];
    
}

//- (void)setSweetSpotPositions:(NSArray *)ssPositions forSongOfDuration:(NSNumber *)songDuration {
//   
//    TGTimelineSliderCell *theCell = _timelineBar.cell;
//    
//    [theCell setTheController:self];
//    [theCell makeMarkersFromSweetSpots:ssPositions forSongDuration:songDuration];
//    
//}

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
