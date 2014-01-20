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
        // Initialization code here.
//        NSLog(@"the scroll view has a document view frame of %@",[self documentView]);
        // We want the scroll view to have layer backing.
        [self setWantsLayer:YES];
        [self setAutohidesScrollers:YES];
        [self setHasHorizontalScroller:YES];
        [self setHasVerticalScroller:YES];

        
        // TEO - could we set this to draw concurrently?!? What does this actually do?
        //[self setCanDrawConcurrently:YES];
        
        // Make sure to track the mouse movements.
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
                                        initWithRect:NSMakeRect(0, 0, NSWidth(frame), NSHeight(frame))
                                        options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                        owner:self userInfo:nil];
    
        [self addTrackingArea:trackingArea];
        
        // Mavericks uses a different scrolling paradigm that means scrollWheel: doesn't get to see every scroll event.
        // Instead WWDC '13 suggests we use a clipview bounds change observer & notification to call our own scroll handler.
        // An additional advantage is that this catches all types of scrolls, including programmatic, scroll bar, etc.
        // The disadvantage is that the event doesn't encode information about what caused it, so we won't know which type of scroll event happened.
        // With 10.0 we will get NSScrollViewWillStartLiveScroll event types.
        NSClipView *clipper = [self contentView];
        [clipper setPostsBoundsChangedNotifications:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSViewBoundsDidChangeNotification object:clipper];
    }
    
    return self;
}


- (void)boundsChanged:(NSEvent *)theEvent {
    NSPoint mPos = [[self window] mouseLocationOutsideOfEventStream];
//    NSLog(@"The visible rect is %@",NSStringFromRect([[self contentView] visibleRect]));
//    NSLog(@"the mouse location (in window coords) is %@",NSStringFromPoint(mPos));
    
    // Convert mouse position from window base coords to the matrix view coords.
    NSPoint mouseLoc = [[self documentView] convertPoint:mPos fromView:nil];
    NSInteger mouseRow, mouseCol;
    
    // Get the row and column in the matrix for the mouse location.
    [[self documentView] getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
    // Make sure the matrix view is updated. But this causes the grid to be redrawn...hmm
    //[[self documentView] setNeedsDisplay];
    
    // Notifiy the delegate of a scroll movement.
    if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidScrollToRect:)]) {
        
        // Convert from (document view) matrix coordinates to window coordinates.
        NSRect testRect = [[self documentView] convertRect:[[self documentView] cellFrameAtRow:mouseRow column:mouseCol] toView:self];
        [_delegate songGridScrollViewDidScrollToRect:testRect];
    }
    
    // Notify the delegate iff the movement causes the cursor to move over a different cell.
    [self updateFocus:mPos];

}

//- (void)scrollWheel:(NSEvent *)theEvent {
//    [super scrollWheel:theEvent];
//}

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
            
//            NSRect testRect = [[self documentView] convertRect:[[self documentView] cellFrameAtRow:mouseRow column:mouseCol] toView:self];
            NSRect testRect = [[self documentView] cellFrameAtRow:mouseRow column:mouseCol];
            [_delegate buttonDownInCellFrame:testRect];
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
    if ([[self documentView] isKindOfClass:[TGSongCellMatrix class]]) {
        
        TGSongCellMatrix *theMatrix = [self documentView];
        NSInteger mouseRow, mouseCol;
        
        // Find out what the mouse location is in the coordinates of the document view (the matrix).
        NSPoint mouseLoc = [theMatrix convertPoint:locationInWindow fromView:nil];
        
        [theMatrix getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];

        if ((mouseCol >= 0) && (mouseRow >= 0)) {
            if ((mouseCol != _currentMouseCol) || (mouseRow != _currentMouseRow)) {
                
                // Find the cell that corresponds to the new coordinates and ask it for its id.
//                TGGridCell *currentCell = [theMatrix cellAtRow:mouseRow column:mouseCol];
//                if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidChangeToCell:withRect:)]) {
//                    NSRect testRect = [theMatrix convertRect:[theMatrix cellFrameAtRow:mouseRow column:mouseCol] toView:self];
//                    [_delegate songGridScrollViewDidChangeToCell:currentCell withRect:testRect];
                if (_delegate && [_delegate respondsToSelector:@selector(songGridScrollViewDidChangeToRow:andColumn:)]) {
                    [_delegate songGridScrollViewDidChangeToRow:mouseRow andColumn:mouseCol];
                }
            }
        }

        _currentMouseCol = mouseCol;
        _currentMouseRow = mouseRow;
    }
//    NSLog(@"location of mouse in window is %@",NSStringFromPoint(locationInWindow));
//    if ([self isFlipped]) {
//        NSLog(@"Heck!");
//    }
//    NSLog(@"location of mouse in scroll view is %@",NSStringFromPoint([self convertPoint:locationInWindow fromView:nil]));
//    NSLog(@"location of mouse in matrix view is %@",NSStringFromPoint([[self documentView] convertPoint:locationInWindow fromView:nil]));
//    if ([[self documentView] isFlipped]) {
//        NSLog(@"Heck doc!");
//    }

}

//- (NSRect)getRectFromSongID:(NSInteger)songID {
//    NSCell *theCell = [[self documentView] cellWithTag:songID];
//    if (theCell != nil) {
//        NSInteger row,col;
//        [[self documentView] getRow:&row column:&col ofCell:theCell];
//        return [[self documentView] cellFrameAtRow:row column:col];
//    }
//    return nil;
//}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

@end
