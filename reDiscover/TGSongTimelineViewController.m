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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSweetSpots:) name:@"SweetSpotsUpdated" object:nil];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)updateSweetSpots:(NSNotification*)notification {
    id<SongIDProtocol> songID = notification.object;

    NSLog(@"song timeline notified of sweet spot update with songID %@.",songID);
    //wipEv
    [self setCurrentSongID:songID];
}

- (void)userCreatedNewSweetSpot:(id)sender {
//    [[self delegate] userCreatedSweetSpotMarkerAtIndex:[sender tag]];
}

- (void)userSelectedExistingSweetSpot:(id)sender {
    [[self delegate] userSelectedSweetSpotMarkerAtIndex:[sender tag]];
}

- (void)sweetspotMarkerAction:(id)sender {
    // I would have preferred to set the slider's (timelineBar) value directly which, by being bound to the songpool's playheadPos, would
    // have updated the playhead, but because the slider works in percent I would not get the precision I want.

    // This should just pass up the chain that the user wanted to change sweet spots to x.
    // It in turn should tell the main controller which has a handle to the song pool and can call its setRequestedPlayheadPosition:
    // The delegate is the TGSongGridViewController
    [[self delegate] userSelectedSweetSpotMarkerAtIndex:[sender tag]];
    
}

/**
 Ensure the timeline cell is updated with the new song's duration and sweet spots.
 @Param songID The id of the song we are making current.
 @Param theSongPool The songpool where the song is held.
 */
-(void)setCurrentSongID:(id<SongIDProtocol>)songID { //wipEv fromSongPool:(TGSongPool *)theSongPool {
    
    TGTimelineSliderCell *theCell = _timelineBar.cell;
    
    [theCell setTheController:self];
    
    NSNumber *songDuration = [_songPoolAPI songDurationForSongID:songID];
    NSArray *songSweetSpots = [_songPoolAPI sweetSpotsForSongID:songID];
    
    [theCell makeMarkersFromSweetSpots:songSweetSpots forSongDuration:songDuration];
}

/**
 Toggle the visibility of the timeline popover window at the give rect.
 @Param theBounds The bounds of the area from which the popover appears.
 @Param theView The view within which the bounds refer to.
 */
- (void)toggleTimelinePopoverRelativeToBounds:(CGRect)theBounds ofView:(NSView *)theView {
    if ([_songTimelinePopover isShown]) {
        [_songTimelinePopover close];
    } else {
        // Make sure wiew is loaded
        [self view];
        
        [_songTimelinePopover showRelativeToRect:theBounds ofView:theView preferredEdge:NSRectEdgeMaxY];
    }
}

/**
 Show the timeline popover window.
 @Param theBounds The bounds of the area from which the popover appears.
 @Param theView The view within which the bounds refer to.
 */
- (void)showTimelinePopoverRelativeToBounds:(CGRect)theBounds ofView:(NSView *)theView {
    // Since there is a gap between the top edge of the selected cell and the bottom edge of the popover
    // it is possible for the cursor to select a different cell when moving from the cell to the popover and
    // thus inadvertedly move the popover.
    // To avoid this, reduce the height of the rect we pass to the popover so that there is no gap between it
    // and the rect it belongs to.
    int offset = 13;
    NSRect newRect = NSMakeRect(theBounds.origin.x, theBounds.origin.y+offset, theBounds.size.width, theBounds.size.height-offset);
    
    [_songTimelinePopover showRelativeToRect:newRect ofView:theView preferredEdge:NSRectEdgeMinY];
}
@end
