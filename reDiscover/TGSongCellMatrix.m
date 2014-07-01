//
//  TGSongCellMatrix.m
//  Proto3
//
//  Created by Teo Sartori on 16/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSongCellMatrix.h"

@implementation TGSongCellMatrix

- (id)initWithFrame:(NSRect)frameRect mode:(NSMatrixMode)aMode prototype:(NSCell *)aCell numberOfRows:(NSInteger)rowsHigh numberOfColumns:(NSInteger)colsWide
{
    self = [super initWithFrame:frameRect mode:aMode prototype:aCell numberOfRows:rowsHigh numberOfColumns:colsWide];
    if (self) {
        // Initialization code here.
        _activeCellCount = 0;

        cellTagToSongID = [[NSMutableArray alloc] init];
        
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
        [self setWantsLayer:NO];
        // Mavericks API that ensures that subviews won't get layers. This is a speed optimization as their updateLayer is not used.
        [self setCanDrawSubviewsIntoLayer:YES];

        _matrixAccessQueue = dispatch_queue_create("matrixAccessQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


//-(void)mouseDown:(NSEvent *)theEvent {
////    [super mouseDown:theEvent];
//    NSLog(@"matrix mouse down in %@",[self selectedCell]);
//    [self sendAction];
//}

- (void)renewAndSizeRows:(NSInteger)newRows columns:(NSInteger)newCols {
    dispatch_sync(_matrixAccessQueue,^{
        [super renewRows:newRows columns:newCols];
        [super sizeToCells];
    });
}

- (id)songIDForSongWithTag:(NSInteger)songTag {
    __block id songID;
    dispatch_sync(_matrixAccessQueue,^{
        songID = [cellTagToSongID objectAtIndex:songTag];
    });
    return songID;
}


- (NSInteger)tagForSongWithID:(id)songID {
    __block NSInteger songTag;
    dispatch_sync(_matrixAccessQueue,^{
        songTag = [cellTagToSongID count];
        [cellTagToSongID addObject:songID];
    });
    return songTag;
}


- (void)incrementActiveCellCount {
    OSAtomicIncrement32(&_activeCellCount);
}


- (void)decrementActiveCellCount {
    OSAtomicDecrement32(&_activeCellCount);
//    _activeCellCount--;
}

- (NSInteger)indexOfObjectWithSongID:(id)songID {
    __block NSInteger retVal = -1;
    dispatch_sync(_matrixAccessQueue,^{
        retVal = [cellTagToSongID indexOfObject:songID];
    });
    return retVal;
}


-(void)scrollCellToVisibleAtRow:(NSInteger)row column:(NSInteger)col {
    dispatch_sync(_matrixAccessQueue,^{
        [super scrollCellToVisibleAtRow:row column:col];
    });
}


-(id)cellWithTag:(NSInteger)anInt {
    __block id retVal;
    dispatch_sync(_matrixAccessQueue,^{
        retVal = [super cellWithTag:anInt];
    });
    return retVal;
}

-(id)cellAtRow:(NSInteger)row column:(NSInteger)col {
    __block id retVal = nil;
    dispatch_sync(_matrixAccessQueue,^{
        if ([self validateCellRow:row andColumn:col]) {
            retVal = [super cellAtRow:row column:col];
        }
    });
    return retVal;
}

-(BOOL)getRow:(NSInteger *)row column:(NSInteger *)col forPoint:(NSPoint)aPoint {
    __block BOOL retVal;
    dispatch_sync(_matrixAccessQueue,^{
        retVal = [super getRow:row column:col forPoint:aPoint];
    });
    return retVal;
}

-(BOOL)getRow:(NSInteger *)row column:(NSInteger *)col ofCell:(NSCell *)aCell {
    __block BOOL retVal;
    dispatch_sync(_matrixAccessQueue,^{
        retVal = [super getRow:row column:col ofCell:aCell];
    });
    return retVal;
}


-(NSRect)cellFrameAtRow:(NSInteger)row column:(NSInteger)col {
    __block NSRect retVal;
    dispatch_sync(_matrixAccessQueue,^{
        retVal = [super cellFrameAtRow:row column:col];
    });
    return retVal;
}


-(BOOL)validateCellRow:(NSInteger)row andColumn:(NSInteger)col {
    return (row*self.numberOfColumns+col < self.activeCellCount);
}


// Speed optimisations
- (BOOL)isOpaque {
    return NO;
}


- (BOOL)wantsDefaultClipping {
    return NO;
}


- (void)getNumberOfVisibleRows:(NSInteger *)rowCount columns:(NSInteger *)colCount {
    *colCount = [self frame].size.width / [self cellSize].width;
    *rowCount = [self frame].size.height / [self cellSize].height;
}


- (void)clearView {
    NSRectFill([self frame]);
}
//- (void)drawRect:(NSRect)dirtyRect
//{
//    [super drawRect:dirtyRect];
//    NSLog(@"drawin'");
//    // Drawing code here.
//}

@end
