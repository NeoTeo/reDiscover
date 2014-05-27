//
//  TGSongGridScrollView.m
//  Proto3
//
//  Created by Teo Sartori on 30/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//


#import "TGSongGridScrollView.h"
#import "TGSongCellMatrix.h"
#import "TGGridCell.h"

@implementation TGSongGridScrollView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        [self setAutohidesScrollers:YES];
//        [self setHasHorizontalScroller:YES];
        [self setHasVerticalScroller:YES];

        
        [self setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"scrollviewBGImage"]]];
        // TEO - could we set this to draw concurrently?!? What does this actually do?
        //[self setCanDrawConcurrently:YES];
        
        // Track the mouse movements.
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                        initWithRect:NSMakeRect(0, 0, NSWidth(frame), NSHeight(frame))
                                        options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                        owner:self userInfo:nil];
    
        [self addTrackingArea:trackingArea];
        
        // Request that boundsChanged is called on scroll notifications of self.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSScrollViewDidLiveScrollNotification object:self];
    }
    
    return self;
}


// Called when the scrollview ([self documentView]) is scrolled.
- (void)boundsChanged:(NSEvent *)theEvent {
    
    NSPoint mPos = [[self window] mouseLocationOutsideOfEventStream];
// TEO: commmented this out as it's not currently being used and anyway prolly should be called from within the songGridScrollViewDidChangeToRow.
/*
    NSInteger mouseRow, mouseCol;
    // Notifiy the delegate of a scroll movement.
    // Convert mouse position from window base coords to the matrix view coords.
    NSPoint mouseLoc = [[self documentView] convertPoint:mPos fromView:nil];
    
    // Get the row and column in the matrix for the mouse location.
    [[self documentView] getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
    if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidScrollToRect:)]) {
        
        // Convert from (document view) matrix coordinates to window coordinates.
        NSRect testRect = [[self documentView] convertRect:[[self documentView] cellFrameAtRow:mouseRow column:mouseCol] toView:self];
        [_delegate songGridScrollViewDidScrollToRect:testRect];
    }
*/
    // Notify the delegate iff the movement causes the cursor to move over a different cell.
    [self updateFocus:mPos];

}


- (void)mouseMoved:(NSEvent *)theEvent {
    [super mouseMoved:theEvent];
    [self updateFocus:[theEvent locationInWindow]];
}


// This to make sure the matrix doesn't steal the mousedown.
-(NSView *)hitTest:(NSPoint)aPoint {
//    NSLog(@"it's a hit");
    return self;
}

-(void)mouseDown:(NSEvent *)theEvent {
    
    NSLog(@"lmb");
    NSPoint mouseLoc = [[self documentView] convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger mouseRow, mouseCol;
    [[self documentView] getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
    TGGridCell *currentCell = [[self documentView] cellAtRow:mouseRow column:mouseCol];
    if ([currentCell tag] != -1) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(buttonDownInCellFrame:)]) {
            
            NSRect theRect = [[self documentView] cellFrameAtRow:mouseRow column:mouseCol];
            [_delegate buttonDownInCellFrame:theRect];
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rmb");
    // Find out where in the grid the click event occurred by converting from the window base coordinates,
    // to the coordinates of the document view (the view being scrolled by the scroll view).
    NSPoint mouseLoc = [[self documentView] convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger mouseRow, mouseCol;
    [[self documentView] getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    TGGridCell *currentCell = [[self documentView] cellAtRow:mouseRow column:mouseCol];
    if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidRightClickSongID:)]) {
        [_delegate songGridScrollViewDidRightClickSongID:[currentCell tag]];
    }

}

// Update focus notifies the delegate when we change the focus (via the pointer) to a different song.
- (void)updateFocus:(NSPoint)locationInWindow {
    
    
    // If the scrolling vector is > x then drop out without informing the delegate of the change.
    static NSPoint previousPoint;
    static NSPoint previousSpeed;
    
    NSPoint nowPoint = [[self documentView] convertPoint:locationInWindow fromView:nil];
    NSPoint currentSpeed = NSMakePoint(nowPoint.x-previousPoint.x, nowPoint.y-previousPoint.y);
    
//    CGFloat ySpdDelta = abs(currentSpeed.y-previousSpeed.y);
//    NSLog(@"ySpdDelta %f",ySpdDelta);
//    for (int d=0; d<ySpdDelta; d++) {
//        printf(">");
//    }
//    printf("\n");
    
    previousPoint = nowPoint;
    previousSpeed = currentSpeed;
    
//    int maxDelta = 15;
//    if ( (abs(currentSpeed.x) > maxDelta) || (abs(currentSpeed.y) > maxDelta) ) {
//        return;
//    }
    
    TGSongCellMatrix *theMatrix = [self documentView];
    NSInteger mouseRow, mouseCol;
    
    // Find out what the mouse location is in the coordinates of the document view (the matrix).
    //NSPoint mouseLoc = [theMatrix convertPoint:locationInWindow fromView:nil];
    
    [theMatrix getRow:&mouseRow column:&mouseCol forPoint:nowPoint];
//    [theMatrix getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
    if ((mouseCol >= 0) && (mouseRow >= 0)) {
        if ((mouseCol != _currentMouseCol) || (mouseRow != _currentMouseRow)) {
            
            // Find the cell that corresponds to the new coordinates and ask it for its id.
            if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidChangeToRow:andColumn:withSpeedVector:)]) {
                [_delegate songGridScrollViewDidChangeToRow:mouseRow andColumn:mouseCol withSpeedVector:currentSpeed];
            }
        }
    }
    
    _currentMouseCol = mouseCol;
    _currentMouseRow = mouseRow;
}


@end
