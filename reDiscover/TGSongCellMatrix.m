//
//  TGSongCellMatrix.m
//  Proto3
//
//  Created by Teo Sartori on 16/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSongCellMatrix.h"

@implementation TGSongCellMatrix

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _activeCellCount = 0;
    }
    
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    [self setWantsLayer:NO];
    // Mavericks API that ensures that subviews won't get layers. This is a speed optimization as their updateLayer is not used.
    [self setCanDrawSubviewsIntoLayer:YES];
    return self;
}


//-(void)mouseDown:(NSEvent *)theEvent {
////    [super mouseDown:theEvent];
//    NSLog(@"matrix mouse down in %@",[self selectedCell]);
//    [self sendAction];
//}


- (void)incrementActiveCellCount {
    _activeCellCount++;
}


- (void)decrementActiveCellCount {
    _activeCellCount--;
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
