//
//  TGSongGridController.m
//  Proto3
//
//  Created by teo on 18/03/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "TGSongGridViewController.h"
#import "TGGridCell.h"
#import "TGSongGridScrollView.h"
#import "TGSongPool.h"
#import "TGSong.h"
#import "TGPlaylistViewController.h"
#import "TGSongUIViewController.h"
#import "TGSongInfoViewController.h"
#import "TGSongTimelineViewController.h"

#import "TGSongCellMatrix.h"
#import "CAKeyframeAnimation+Parametric.h"

// The private interface declaration overrides the public one to implement the TGSongDelegate protocol.
//@interface TGSongGridController () <TGSongUIViewControllerDelegate,TGSongGridScrollViewDelegate, TGSongPoolDelegate>
//
//@end

@interface TGSongGridViewController ()

@end

@implementation TGSongGridViewController

-(id)initWithFrame:(NSRect)newFrame {
    self = [super init];
    if (self) {
        // do stuff
    }
    return self;
}


-(void)awakeFromNib {
    NSLog(@"song grid controller awake.");
    zoomFactor = 1.0;
    _currentCellSize = 150;
    _interCellHSpace = 0;//3;
    _interCellVSpace = 0;//3;
    
    
    _songTimelineController = [[TGSongTimelineViewController alloc] initWithNibName:@"TGSongTimelineView" bundle:nil];
    [_songTimelineController setDelegate:self];
    // Make sure the timeline controller's other views are also loaded right away.
    [_songTimelineController view];
    
    [self setupSongGrid];
    
    
    // Set up the animations we're going to use.
    
    NSLog(@"TGSongGridViewController awakeFromNib: setting up animations");
    
    KeyframeParametricBlock function = ^double(double time) {
        // the range is -1.14 >= x <= 0
        double x = -1.0457+(time*1.0457);
        // y = amplitude*sin(angle*frequency)
        return(0.2*x*sin(x*9));
    };
    
    _pushBounceAnimation = [CAKeyframeAnimation
                         animationWithKeyPath:@"transform.scale"
                         function:function fromValue:1.0 toValue:0];
    
    [_pushBounceAnimation setDuration:0.35];
    
    // Now's a good time to load the genre-to-colour map
//    [self loadGenreToColourMap];
}


- (void)setupSongGrid {
    
    int verticalCellNumber = 0;
    int horizontalCellNumber = 0;
    
    CGRect thisFrame = [self view].frame;
    
    _defaultImage = [NSImage imageNamed:@"songImage"];
    
    // The scroll view will hold the matrix of song cells.
    _songGridScrollView = [[TGSongGridScrollView alloc] initWithFrame:thisFrame];
//    [_songGridScrollView setBackgroundColor:[NSColor brownColor]];
    
    [_songGridScrollView setDelegate:self];
    
    // The maximum number of columns in the grid. There may be less columns displayed within the viewable area of the scroll view.
    _colsPerRow = round(NSWidth(thisFrame)/(_currentCellSize+_interCellHSpace));
    
    TGGridCell *protoGrid = [[TGGridCell alloc] init];
//    [protoGrid setTarget:self];
//    [protoGrid setAction:@selector(buttonDownInMatrixCell:)];
    
    // The gridRect defines the dimensions of the songCellGrid. The songGridView defined above is a "window" onto that surface.
    _songCellMatrix = [[TGSongCellMatrix alloc] initWithFrame:thisFrame
                                                         mode:NSHighlightModeMatrix
                                                    prototype:protoGrid //[[TGGridCell alloc] init]
                                                 numberOfRows:verticalCellNumber
                                              numberOfColumns:horizontalCellNumber];
        
    // Set the cell size and spacing of the matrix's cells.
    [_songCellMatrix setCellSize:NSMakeSize(_currentCellSize, _currentCellSize)];
    [_songCellMatrix setIntercellSpacing:NSMakeSize(_interCellHSpace, _interCellVSpace)];
    
    // Tell the matrix that we're handling actions on it with our buttonDownInMatrixCell: method.
//    [_songCellMatrix setTarget:self];
//    [_songCellMatrix setAction:@selector(buttonDownInMatrixCellWithID:)];
    
    // Set the matrix as the document view of the scroll view.
    [_songGridScrollView setDocumentView:_songCellMatrix];
    
    [[self view] addSubview:_songGridScrollView];
    
    // Make sure the unmapped songs array is allocated.
    unmappedSongIDArray = [[NSMutableArray alloc] init];
    
    // OS 10.9 feature.
    [[self view] setCanDrawSubviewsIntoLayer:YES];
}


- (void)loadGenreToColourMap {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GenreColours" ofType:@"plist"];
        
        // This loads the contents into the plistXML field
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        // And convert the static property list into property list objects
        _genreToColourDictionary = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
}


- (void)getRow:(NSUInteger *)row andCol:(NSUInteger *)col forSongID:(NSUInteger)songID {
    NSAssert(_colsPerRow > 0, @"Error. 0 columns will cause a div by zero.");
    *row = floor(songID / _colsPerRow);
    *col = songID - (*row) * _colsPerRow;
}


- (void)setCoverImage:(NSImage *)theImage forSongWithID:(NSUInteger)songID {
    
    // First convert the songID to the matrix index.
    TGGridCell * theCell = [_songCellMatrix cellWithTag:songID];
    
    // This core stuff has to happen on the main thread apparently #TEO CHECK_THIS
    dispatch_async(dispatch_get_main_queue(), ^{
        [self animateCoverChange:theImage forCell:theCell];
//        [self animateCoverChange:theImage forSongWithID:songID];
    });
}


// Obviously this will animate the change eventually.
- (void)animateCoverChange:(NSImage *)theImage forCell:(TGGridCell *)theCell {
    
//    TGGridCell *existingCell = [[_songCellMatrix cells] objectAtIndex:songID];
//    if (theCell.image == _defaultImage) {
        NSLog(@"here we'd flip and change.");
        [self coverPushAndFadeAnimationForCell:theCell withImage:theImage];
//        [self coverFlipAnimationForCell:theCell withImage:theImage];
//    }
    
//    [_songCellMatrix setNeedsDisplay];
    // Attempt to only invalidate the cell area.
//    NSUInteger row, col;
//    [_songCellMatrix getRow:&row column:&col ofCell:existingCell];
//    NSRect cellRect = [_songCellMatrix cellFrameAtRow:row column:col];
//    [_songCellMatrix setNeedsDisplayInRect:cellRect];
}



static NSInteger const kUndefinedID =  -1;

- (NSInteger)cellIndexToSongID:(NSInteger)cellIndex {
    NSAssert(cellIndex < [[_songCellMatrix cells] count], @"cell index is greater than the size of the cells array");
    TGGridCell *theCell = [[_songCellMatrix cells] objectAtIndex:cellIndex];
    
    // If the cell has not yet been connected to a song ID, pick one from the unmapped songs and connect it.
    if ([theCell tag] ==  kUndefinedID) {
        
        // No id yet, so pick one from the unmapped song set.
        u_int32_t unmappedCount =(u_int32_t)[unmappedSongIDArray count];
        if (unmappedCount > 0) {
            int randomSongIDIndex = arc4random_uniform(unmappedCount);
            
            // get the randomSong id out of the array.
            NSNumber *songIDNumber = [unmappedSongIDArray objectAtIndex:randomSongIDIndex];
            [unmappedSongIDArray removeObjectAtIndex:randomSongIDIndex];
            
            [theCell setTag:[songIDNumber integerValue]];
        }
    }
    
    return [theCell tag];
}


- (void)addMatrixCell2:(NSUInteger)songID {
    
    
    NSInteger rowCount, colCount, newRow, newCol;
    
    // Let the song id decide the position in the matrix.
    NSUInteger row = floor(songID / _colsPerRow);
    NSUInteger col = songID - (row*_colsPerRow);
    
    [_songCellMatrix getNumberOfRows:&rowCount columns:&colCount];
    
    // Grow the rows and columns as songs are added.
    if (row >= rowCount) {
        newRow = row+1;
    } else
        newRow = rowCount;

    // If there is more than one row the number of columns is already set.
    if (row > 0) {
        newCol = _colsPerRow;
    } else {
        if (col >= colCount) {
            newCol = col+1;
        } else
            newCol = colCount;
    }
    [_songCellMatrix renewRows:newRow columns:newCol];
    
    [_songCellMatrix sizeToCells];
    // How about sizeToFit?
    
    NSAssert([[_songCellMatrix cells] count] > songID, @"Eeek. songID is bigger than the song cell matrix");
    
    // Find the existing cell for this songID.
    TGGridCell *existingCell = [[_songCellMatrix cells] objectAtIndex:songID];
    
    // Do pop up anim before we add the actual cell.
    CGRect cellRect = [_songCellMatrix cellFrameAtRow:row column:col];
    CGRect theFrame = [[self songGridScrollView] documentVisibleRect];

    // Only do the work if we're actually visible.
//    if (NSPointInRect(cellRect.origin,theFrame)) {
    if (NSIntersectsRect(cellRect, theFrame)) {
        // TEO: Should this just use a layer rather than a layer-backed view?
        NSImageView *newURLImage = [[NSImageView alloc] initWithFrame:cellRect];
        [newURLImage setWantsLayer:YES];
        [newURLImage setImage:_defaultImage];

        [[[self songGridScrollView] documentView] addSubview:newURLImage];
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            
            // This has to go after the addSubview as it resets the view's anchorPoint.
            [self bouncyPopAnimation:newURLImage];
            
        } completionHandler:^{
            
            // Remove newURLImage without needing display because we have to call setNeedsDisplay on the whole matrix anyway.
            [newURLImage removeFromSuperviewWithoutNeedingDisplay];
            
            // Add the id of this song to an array of unassigned songs.
            // We will then pick randomly from that array to assign to a cell in the matrix.
            [unmappedSongIDArray addObject:[NSNumber numberWithInteger:songID]];
            
              // This is now done JIT or when all songs have been loaded.
//            [existingCell setTag:songID];
            [existingCell setImage:_defaultImage];
            [_songCellMatrix incrementActiveCellCount];
        
            [_songCellMatrix setNeedsDisplay];
            
        }];
    } else
    {
        // Add the id of this song to an array of unassigned songs.
        // We will then pick randomly from that array to assign to a cell in the matrix.
        [unmappedSongIDArray addObject:[NSNumber numberWithInteger:songID]];
        
        // Set the cell's tag to the songID we've been passed.
          // This is now done JIT or when all songs have been loaded.
//        [existingCell setTag:songID];
        [existingCell setImage:_defaultImage];
        [_songCellMatrix incrementActiveCellCount];
        [_songCellMatrix setNeedsDisplay];
    }
}


- (void)animateMatrixZoom:(NSInteger)zoomQuantum {

    // Note which cell is the currently selected so that we can keep it in view after the zooming is done.
    TGGridCell *selectedCell = [_songCellMatrix cellWithTag:[_delegate lastRequestedSongID]];
    
    zoomFactor = 0.1*zoomQuantum;
    NSUInteger currentSongCount = [_songCellMatrix activeCellCount];//[[_songCellMatrix cells] count];
    CGFloat newCellSize = _currentCellSize*zoomFactor;
    
    // Get the current number of cols and rows.
    NSInteger oldCols, oldRows;
    [_songCellMatrix getNumberOfRows:&oldRows columns:&oldCols];
    NSLog(@"old rows %lu and cols %lu and numSongs %lu",oldRows,oldCols,currentSongCount);
    // The new number of columns should be determined by the width of the scroll view (not its content view) divided by the new cell size.
    _colsPerRow = round([_songGridScrollView frame].size.width/(newCellSize+_interCellHSpace));
    _colsPerRow = (currentSongCount < _colsPerRow) ? currentSongCount : _colsPerRow;
    
    NSUInteger newRows = currentSongCount/_colsPerRow;
    // Make sure we don't lose any rows in the division.
    if (newRows*_colsPerRow < currentSongCount){
        newRows += 1;
    }
    NSLog(@"new rows %lu and cols %lu and numSongs %lu",newRows,_colsPerRow,currentSongCount);
    
    int maxVisibleRows = [_songGridScrollView frame].size.height / [_songCellMatrix cellSize].height;
    __block NSInteger animCount = 0;
    // We need to figure out how big the new frame needs to be and set both the songCellMatrix and the bgView to it.
    NSRect newGridRect = [_songGridScrollView bounds];//NSMakeRect(0, 0, _colsPerRow*(newCellSize+_interCellHSpace), newRows*(newCellSize+_interCellVSpace));
    NSLog(@"the new grid rect is %@",NSStringFromRect(newGridRect));
    
    // Make a view to cover the existing grid view before re-configuring it and to draw the zooming songs onto.
//    TGFlippedView *bgView = [[TGFlippedView alloc] initWithFrame:newGridRect];
    NSView *bgView = [[NSView alloc] initWithFrame:newGridRect];
    [_songCellMatrix setFrame:newGridRect];

    //[_songCellMatrix setHidden:YES];
    //[_songGridScrollView setDocumentView:bgView];
    [_songCellMatrix addSubview:bgView];


    // Find out the row number visible at the top.
    NSInteger theRow,theCol;
    [_songCellMatrix getRow:&theRow column:&theCol forPoint:[_songGridScrollView documentVisibleRect].origin];
    NSLog(@"the row %ld",theRow);


    NSInteger loopCols, loopRows, startRow;
    // If we are zooming in...
    if (oldCols > _colsPerRow) {
        // we need only animate the old visible cells because, as cells get bigger, we get fewer cols and more rows.
        loopCols = oldCols;
        loopRows = oldRows;
        startRow = theRow;
    } else {
        loopCols = _colsPerRow;
        loopRows = newRows < maxVisibleRows ? newRows : maxVisibleRows;
        startRow = theRow - (oldRows-loopRows);
        startRow = startRow < 0 ? 0 : startRow;
    }
    NSLog(@"start row is %ld",(long)startRow);
    NSLog(@"loopCols %lu loopRows %lu",loopCols,loopRows);
    
    // clip to maxVisible
//    loopRows = newRows < maxVisibleRows ? newRows : maxVisibleRows;
    
    for (int cellCol=0; cellCol < loopCols; cellCol++) {
        
        for (NSInteger cellRow=startRow; cellRow < startRow+loopRows; cellRow++) {
            
            if (cellRow*_colsPerRow+cellCol < currentSongCount) {
                
                // Get the cell's current frame.
                NSRect cellFrame = [_songCellMatrix cellFrameAtRow:cellRow column:cellCol];
                
                NSImageView *newURLImage = [[NSImageView alloc] initWithFrame:cellFrame];
                
                [newURLImage setWantsLayer:YES];
                [newURLImage setImage:[NSImage imageNamed:@"songImage"]];
                
                [_songCellMatrix addSubview:newURLImage];
                
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                    
                    animCount++;
                    context.duration = 0.25;
                    ((NSImageView *)newURLImage.animator).frame = NSMakeRect(cellCol*(newCellSize+_interCellHSpace), cellRow*(newCellSize+_interCellVSpace), newCellSize, newCellSize);
                    
                } completionHandler:^{
                    
                    animCount--;
                    
                    [newURLImage removeFromSuperviewWithoutNeedingDisplay];
                    
                    if (animCount == 0) {
                        
                        // Change the number of rows and columns in the song cell matrix.
                        [_songCellMatrix renewRows:newRows columns:_colsPerRow];
                    
                        // Set the size of the cells according to the zoom factor.
                        [_songCellMatrix setCellSize:NSMakeSize(newCellSize, newCellSize)];
                    
                        // This ensures the matrix is always only as big as it needs to be.
                        [_songCellMatrix sizeToCells];
//                        NSLog(@"songCellMatrix sized to %@",NSStringFromRect([_songCellMatrix frame]));
                        
                        // Ensure that the currently selected song is still visible after the zoom.
                        NSInteger curCol,curRow;
                        [_songCellMatrix getRow:&curRow column:&curCol ofCell:selectedCell];
                        [_songCellMatrix scrollCellToVisibleAtRow:curRow column:curCol];
                        
                        // Return the matrix as the scroll view's document view.
                        [bgView removeFromSuperview];
                            NSUInteger wellSongCount = [_songCellMatrix activeCellCount];
                        NSLog(@"well...%lu",wellSongCount);
                    }
                }];
            }
        }
    }
}

- (void)zoomAnimation:(NSView *)theView {
    
}


- (void)coverPushAnimation:(TGGridCell *)theCell withImage:(NSImage *)theImage {
    
}

// This animation will push the blank cover image into the screen whilst its cover image fades in and it pops back up to fill its frame.
- (void)coverPushAndFadeAnimationForCell:(TGGridCell *)theCell withImage:(NSImage *)theImage {
    
    // First we get the cell's rect.
    NSInteger row, col;
    [_songCellMatrix getRow:&row column:&col ofCell:theCell];
    CGRect cellRect = [_songCellMatrix cellFrameAtRow:row column:col];
    
    CALayer *frontLayer = [CALayer layer];
    [frontLayer setContents:theImage];
    [[[self songGridScrollView] documentView] setWantsLayer:YES];
    [[[[self songGridScrollView] documentView] layer] addSublayer:frontLayer];
    
    [frontLayer setBounds:CGRectMake(0, 0, cellRect.size.width, cellRect.size.height)];
    [frontLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    CGPoint aPoint = CGPointMake(CGRectGetMidX(cellRect), CGRectGetMidY(cellRect));
    [frontLayer setPosition:aPoint];
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        
        [frontLayer addAnimation:_pushBounceAnimation forKey:@"scale"];
        theCell.image = nil;
        
    }completionHandler:^{
    
        theCell.image = theImage;
        [frontLayer removeFromSuperlayer];
    }];
}


// Test for cover flip animation.
- (void)coverFlipAnimationForCell:(TGGridCell *)theCell withImage:(NSImage *)theImage {
    
    NSInteger row, col;
    [_songCellMatrix getRow:&row column:&col ofCell:theCell];
    CGRect cellRect = [_songCellMatrix cellFrameAtRow:row column:col];
    
    NSImageView *frontView = [[NSImageView alloc] initWithFrame:cellRect];
    [frontView setImage:[theCell image]];
    [frontView setWantsLayer:YES];
    [frontView setCanDrawSubviewsIntoLayer:YES];
    [frontView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    
    [[[self songGridScrollView] documentView] addSubview:frontView];
    
    // We want the animation to occur from the center of the view layer.
    // The layer's anchor point is defined in unit points (0 to 1) and should default to its center at (0.5,0.5) but doesn't.
    // The layer position coordinates are relative to the anchorpoint of the layer in the coordinates of its superview.
    
    /*
    +Super view+––––––––––+
    |                     |
    |       +Layer+–+     |
    |       |       |     |
    +––––––––-–>*   |     |
    | x pos |   ^   |     |
    |       +–––+–––+     |
    |           |         |
    |           |y pos    |
    |           |         |
    +–––––––––––+–––––––-–+
    */
    
    [frontView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    CGPoint center = CGPointMake(CGRectGetMidX(frontView.frame), CGRectGetMidY(frontView.frame));
    
    // Disable implicit animations whilst we set the visible view's initial position.
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
 
    // The layer's position is relative to the anchor point.
    // Since we've moved the layer's anchor point to the middle of its bounds it should be set to the center to avoid moving.
    [frontView.layer setPosition:center];
    
    [CATransaction commit];
    
    theCell.image = nil;
    
    
    // Set up the back side of the cover.
    NSImageView *backView= [[NSImageView alloc] initWithFrame:cellRect];
    [backView setImage:theImage];
    [backView setWantsLayer:YES];
    [backView setCanDrawSubviewsIntoLayer:YES];
    [backView setHidden:YES];
    
    [[[self songGridScrollView] documentView] addSubview:backView];
    
    // We want the animation to occur from the center of the view.
    [backView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    center = CGPointMake(CGRectGetMidX(backView.frame), CGRectGetMidY(backView.frame));
    [backView.layer setPosition:center];
    
    // Do this as the first thing.
    CATransform3D perspectiveTransform = CATransform3DIdentity;
    perspectiveTransform.m34 = 1.0/-500;
    backView.layer.transform = perspectiveTransform;
    
    // Set the backview layer's transform to the position we want to end at *after* the animation is done and the presentation layer removed.
    // This flips the layer on the y axis (upside down)
    backView.layer.transform = CATransform3DScale(backView.layer.transform, 1, -1, 1);
    
    // Rotate it pi radians so the back is facing the projection plane. It should look right way up.
    backView.layer.transform = CATransform3DRotate(backView.layer.transform, M_PI, 1, 0, 0);
    
    
    NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
    
    int count = 12;
    CGFloat frac = M_PI/count;
    for (int i=0; i<count; i++) {
        [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
    }
    
    NSArray *frontVals = [sinVals subarrayWithRange:NSMakeRange(0, count/2+1)];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        
        if (frontView.layer == nil) {
            return ;
        }
        
        
        CATransform3D tranny = CATransform3DIdentity;
        tranny.m34 = 1.0/-500;//eyePosition;
        
        // Apply the transform to the view layer.
        frontView.layer.transform = tranny;
        
        CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
        
        flipAnimation.values = frontVals;
        
        flipAnimation.duration = 2;
        flipAnimation.removedOnCompletion = YES;
        
        // Ensure that the model layer is in the same final state as the presentation layer to avoid glitching.
        // This needs to happen before the animation is added so that the implicit animation is overridden by the explicit one.
        frontView.layer.transform = CATransform3DRotate(tranny, M_PI_2, 1.0f, 0.0f, 0.0f);
        
        // Add the explicit animation.
        [frontView.layer addAnimation:flipAnimation forKey:@"flip"];
        
    }completionHandler:^{
        
        [frontView removeFromSuperviewWithoutNeedingDisplay];
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            
            if (backView.layer == nil) {
                return ;
            }
            
            // We are about to see the back view so make sure it's not hidden.
            [backView setHidden:NO];
            
//            NSArray *backVals = [sinVals subarrayWithRange:NSMakeRange(count/2, count/2)];
            
            // reverse the front vals so the front layer can tip back and reveal itself.
            NSMutableArray *testVals = [NSMutableArray arrayWithCapacity:[frontVals count]];
            NSEnumerator *enumerator = [frontVals reverseObjectEnumerator];
            for (id element in enumerator) {
                [testVals addObject:element];
            }
            
            CAKeyframeAnimation *flopAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
            
            flopAnimation.values = testVals;
            
            flopAnimation.duration = 2;
            
            [backView.layer addAnimation:flopAnimation forKey:@"flop"];
            
        } completionHandler:^{
            
            [backView removeFromSuperviewWithoutNeedingDisplay];
            
            // Remove newURLImage without needing display because we have to call setNeedsDisplay on the whole matrix anyway.
            [theCell setImage:theImage];
            
            [_songCellMatrix setNeedsDisplay];
            
        }];
    }];
}


- (void)flipAnimation:(NSView *)theView {
    
    if (theView.layer != nil) {
        
        CATransform3D tranny = CATransform3DIdentity;
        tranny.m34 = 1.0/-500;//eyePosition;
//        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
        
        // Apply the transform to the view layer.
        theView.layer.transform = tranny;
        
        CGPoint center = CGPointMake(CGRectGetMidX(theView.frame), CGRectGetMidY(theView.frame));
        [theView.layer setPosition:center];
        
        // We want the animation to occur from the center of the view.
        [theView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
        
        CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
        
        NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
        
        CGFloat frac = M_PI*2/10;
        for (int i=0; i<10; i++) {
            [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
        }
        flipAnimation.values = sinVals;
        // Set the keyframes for the flip animation.
//        flipAnimation.values = [NSArray arrayWithObjects:
//                                  [NSNumber numberWithFloat:0.1],
//                                  [NSNumber numberWithFloat:1.5],
//                                  [NSNumber numberWithFloat:0.95],
//                                  [NSNumber numberWithFloat:1.0], nil];
        
        flipAnimation.duration = 1;//0.25;
        flipAnimation.removedOnCompletion = YES;
        
        [theView.layer addAnimation:flipAnimation forKey:@"flip"];
        
    }
}

- (void)flipAnimationFrom:(NSView *)frontView toView:(NSView *)backView {
    
        NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
    
    int count = 12;
        CGFloat frac = M_PI/count;
        for (int i=0; i<count; i++) {
            [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
        }
    
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        if (frontView.layer != nil) {
            
            NSArray *frontVals = [sinVals subarrayWithRange:NSMakeRange(0, count/2)];
            
            CATransform3D tranny = CATransform3DIdentity;
            tranny.m34 = 1.0/-500;//eyePosition;
            //        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
            
            // Apply the transform to the view layer.
            frontView.layer.transform = tranny;
            
            CGPoint center = CGPointMake(CGRectGetMidX(frontView.frame), CGRectGetMidY(frontView.frame));
            [frontView.layer setPosition:center];
            
            // We want the animation to occur from the center of the view.
            [frontView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
            
            CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
            
            flipAnimation.values = frontVals;
            
            flipAnimation.duration = 5;//0.25;
            flipAnimation.removedOnCompletion = YES;
            
            [frontView.layer addAnimation:flipAnimation forKey:@"flip"];
        }
        
    }completionHandler:^{
        NSLog(@"flip completion handler");
        if (backView.layer != nil) {
            
            [backView setHidden:NO];
            NSArray *backVals = [sinVals subarrayWithRange:NSMakeRange(count/2, count/2)];
            CATransform3D tranny = CATransform3DIdentity;
            tranny.m34 = 1.0/-500;//eyePosition;
            //        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
            
            // Apply the transform to the view layer.
            backView.layer.transform = tranny;
            
            CGPoint center = CGPointMake(CGRectGetMidX(backView.frame), CGRectGetMidY(backView.frame));
            [backView.layer setPosition:center];
            
            // We want the animation to occur from the center of the view.
            [backView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
            
            CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
            
            flipAnimation.values = backVals;
            
            flipAnimation.duration = 5;//0.25;
            flipAnimation.removedOnCompletion = YES;
            
            [backView.layer addAnimation:flipAnimation forKey:@"flip"];
        }
    }];
    
}


- (void)bouncyPopAnimation:(NSView *)theView {
    
    if (theView.layer != nil) {
        
        CGPoint center = CGPointMake(CGRectGetMidX(theView.frame), CGRectGetMidY(theView.frame));
        [theView.layer setPosition:center];
        
        // We want the animation to occur from the center of the view.
        [theView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        
        // Set the keyframes for the pop animation.
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:0.1],
                                  [NSNumber numberWithFloat:1.5],
                                  [NSNumber numberWithFloat:0.95],
                                  [NSNumber numberWithFloat:1.0], nil];
        
        bounceAnimation.duration = 0.25;
        bounceAnimation.removedOnCompletion = YES;
        
        [theView.layer addAnimation:bounceAnimation forKey:@"bounce"];
        
    }
}

- (void)test:(NSView *)aView {
    
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    a.fromValue = [NSNumber numberWithFloat:0];
    a.toValue = [NSNumber numberWithFloat:-M_PI*2];
    
    a.duration = 1.8; // seconds
    a.repeatCount = HUGE_VAL;
    [aView.layer addAnimation:a forKey:nil];
}

// Build a list of song ids to pass to the song pool so it can cache them.
// Internally the cache is a set to which we can add and perform other set operations on (such as differences)
- (NSArray *)buildCacheArray:(NSUInteger)cacheType forRow:(NSInteger)theRow andColumn:(NSInteger)theColumn {
    // First we need to decide on a caching strategy.
    // For now we will simply do a no-brains area caching of two songs in every direction from the current cursor position.
    // Finally we pass that list to the song pool.
    
    // Make sure we have an inited cache.
    if (songIDCache == nil) {
        songIDCache = [[NSMutableSet alloc] initWithCapacity:25];
    }
    
    NSInteger radius = 2;
    NSInteger maxRows = [_songCellMatrix numberOfRows];
    NSInteger maxCols = [_songCellMatrix numberOfColumns];
    
    for (NSInteger matrixCols=theColumn-radius; matrixCols<=theColumn+radius; matrixCols++) {
        for (NSInteger matrixRows=theRow-radius; matrixRows<=theRow+radius; matrixRows++) {
            if ((matrixRows >= 0) && (matrixRows <maxRows)) {
                if((matrixCols >=0) && (matrixCols < maxCols)) {
                    NSAssert([[_songCellMatrix cells] count] > 0, @"shit no cells");
                    TGGridCell *theCell = [_songCellMatrix cellAtRow:matrixRows column:matrixCols];
                    NSInteger cellIndex = [[_songCellMatrix cells] indexOfObject:theCell];
                    NSInteger songID = [self cellIndexToSongID:cellIndex];
                    if (songID != -1) {
                        [songIDCache addObject:[NSNumber numberWithInteger:songID]];
                    }
                }
            }
        }
    }
    
//    NSLog(@"I'm thinking %@",cellIndexArray);
    // Then we build a list of song ids.
    return [songIDCache allObjects];
}

-(void)keyDown:(NSEvent *)theEvent {
    NSLog(@"songgridcontroller keydown");
}

- (void)buttonDownInCellFrame:(NSRect)cellFrame {
    [self togglePopoverAtCellFrame:cellFrame withDelay:0.0];
    return;
    // If a popover is shown, hide it.
    if ([[_songTimelineController songTimelinePopover] isShown]) {
        [[_songTimelineController songTimelinePopover] close];
    } else
    {
        [_songTimelineController view];
        
        [_songTimelineController showTimelinePopoverRelativeToBounds:cellFrame ofView:_songCellMatrix];
        [[[self view] window] makeFirstResponder:(NSResponder *)_delegate];
    }
}

- (void)togglePopoverAtCellFrame:(NSRect)cellFrame withDelay:(double)delayInSeconds {
    
    // If the frame of the currently showing popover is the same as what we want shown, just leave it alone.
    if ([[_songTimelineController songTimelinePopover] isShown] && NSEqualRects([[_songTimelineController songTimelinePopover] positioningRect], cellFrame)) {
        [[_songTimelineController songTimelinePopover] close];
    } else {
        
        // Start a new timer.
        popupTimerStart = [NSDate timeIntervalSinceReferenceDate];
//        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (([NSDate timeIntervalSinceReferenceDate] - popupTimerStart) >= delayInSeconds) {
                [_songTimelineController view];
                [_songTimelineController showTimelinePopoverRelativeToBounds:cellFrame ofView:_songCellMatrix];
                [[[self view] window] makeFirstResponder:(NSResponder *)_delegate];
            }
        });
    }
    
}

// // Delegate methods.

// TGSongTimelineViewControllerDelegate methods:

// This method just passes the call through from the timeline view controller to the main controller (this class' delegate).
- (void)userSelectedSweetSpotMarkerAtIndex:(NSUInteger)ssIndex {
    
    if([[self delegate] respondsToSelector:@selector(userSelectedSweetSpot:)]) {
        
        [[self delegate] userSelectedSweetSpot:ssIndex];
    }
}

// TGSongGridScrollViewDelegate methods:
- (void)songGridScrollViewDidScrollToRect:(NSRect)theRect {
    // TEO: Make a method inside the songUIViewController that is a delegate of the TGSongGridScrollView that is called whenever scrolling/moving.
    [_songUIViewController setUIPosition:theRect.origin withPopAnimation:NO];
}


//- (void)songGridScrollViewDidChangeToCell:(TGGridCell *)theCell withRect:(NSRect)theRect {
//    
//    [_songUIViewController setUIPosition:theRect.origin withPopAnimation:YES];
//    
//    NSInteger cellIndex = [[_songCellMatrix cells] indexOfObject:theCell];
//    [[self delegate] userSelectedSongID:[self cellIndexToSongID:cellIndex]];
//}


- (void)songGridScrollViewDidChangeToRow:(NSInteger)theRow andColumn:(NSInteger)theColumn {
    
    NSRect theRect = [_songCellMatrix convertRect:[_songCellMatrix cellFrameAtRow:theRow column:theColumn] toView:_songGridScrollView];
    [_songUIViewController setUIPosition:theRect.origin withPopAnimation:YES];
    
    TGGridCell *theCell = [_songCellMatrix cellAtRow:theRow column:theColumn];
    
    
    NSAssert(theCell, @"cell is nil");
    NSInteger cellIndex = [[_songCellMatrix cells] indexOfObject:theCell];
    
    NSInteger songID = [self cellIndexToSongID:cellIndex];
    if (songID != -1) {
        [[self delegate] userSelectedSongID:songID];
        
        NSArray *theArray =[self buildCacheArray:1 forRow:theRow andColumn:theColumn];
        [[self delegate] requestSongArrayPreload:theArray];
    
        // If a popover is shown, hide it.
        if ([[_songTimelineController songTimelinePopover] isShown]) {
            [[_songTimelineController songTimelinePopover] close];
        }
        
        NSRect cellFrame = [_songCellMatrix cellFrameAtRow:theRow column:theColumn];
        [self togglePopoverAtCellFrame:cellFrame withDelay:3.0];
    }
}

//- (void)songGridScrollViewDidChangeToSongID:(NSUInteger)songID withRect:(NSRect)theRect {
//    
//    [_songUIViewController setUIPosition:theRect.origin withPopAnimation:YES];
//    
//    [[self delegate] userSelectedSongID:songID];
//}

- (void)songGridScrollViewDidRightClickSongID:(NSUInteger)songID {
    NSLog(@"RMB");
    // Turn song id to song
    //[_songPool fetchSongData];
    //[_songPool offsetSweetSpotForSongID:songID bySeconds:-0.25];
}

@end

