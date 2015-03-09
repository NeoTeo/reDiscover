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
#import "TGPlaylistViewController.h"
//#import "TGSongUIViewController.h"
#import "TGSongInfoViewController.h"
#import "TGSongTimelineViewController.h"
#import "TGMainViewController.h"
#import "TGSongCellMatrix.h"


#import "CAKeyframeAnimation+Parametric.h"

//#include <os/trace.h>
//#include <os/activity.h>

// Trying out some pop animation.
//#import <POP/POP.h>

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

@synthesize songPoolAPI = _songPoolAPI;

- (id<SongPoolAccessProtocol>)songPoolAPI {
    return _songPoolAPI;
}

- (void)setSongPoolAPI:(id<SongPoolAccessProtocol>)songPoolAPI {
    _songPoolAPI = songPoolAPI;
    _songTimelineController.songPoolAPI = songPoolAPI;
}

-(void)awakeFromNib {
    zoomFactor = 1.0;
    _currentCellSize = 150;
    _interCellHSpace = 0;//3;
    _interCellVSpace = 0;//3;
    
    
    _songTimelineController = [[TGSongTimelineViewController alloc] initWithNibName:@"TGSongTimelineView" bundle:nil];
    [_songTimelineController setDelegate:self];
    // Make sure the timeline controller's other views are also loaded right away.
    [_songTimelineController view];
//    [[_songTimelineController view] setNeedsDisplay:YES];
    
    [self setupSongGrid];
    
    
    // Set up the animations we're going to use.
    
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
    
    _bounceAnimation = [self makeBounceAnimation];
    
    // Debug
    _debugLayerDict = [[NSMutableDictionary alloc] init];
    
    // Now's a good time to load the genre-to-colour map
//    [self loadGenreToColourMap];
}

- (CAKeyframeAnimation*)makeBounceAnimation {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    // Set the keyframes for the pop animation.
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.1],
                              [NSNumber numberWithFloat:1.5],
                              [NSNumber numberWithFloat:0.95],
                              [NSNumber numberWithFloat:1.0], nil];
    
    bounceAnimation.duration = 0.25;
    bounceAnimation.removedOnCompletion = YES;
    return bounceAnimation;
}



- (void)setupSongGrid {
    
    int verticalCellNumber = 0;
    int horizontalCellNumber = 0;
    
    CGRect thisFrame = [self view].frame;
    
//    _defaultImage = [NSImage imageNamed:@"songImage"];
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
    
    [[_songGridScrollView documentView] setWantsLayer:YES];
    
    [[self view] addSubview:_songGridScrollView];
    
    // Make sure the unmapped songs array is allocated.
    unmappedSongIDArray = [[NSMutableArray alloc] init];
    
    // OS 10.9 feature.
    [[self view] setCanDrawSubviewsIntoLayer:YES];
    
    testingQueue = dispatch_queue_create("Testing queue", NULL);

}

- (CALayer*)makeLayerWithImage:(NSImage*)theImage atRect:(CGRect)cellRect {
    CALayer* frontLayer = [CALayer layer];
    CGFloat desiredScaleFactor = [[[self view] window] backingScaleFactor];
    CGFloat actualScaleFactor = [theImage recommendedLayerContentsScale:desiredScaleFactor];

    id layerContents = [theImage layerContentsForContentsScale:actualScaleFactor];

    [frontLayer setContents:layerContents];
    [frontLayer setBounds:CGRectMake(0, 0, cellRect.size.width, cellRect.size.height)];
    [frontLayer setContentsScale:actualScaleFactor];
    [frontLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    CGPoint aPoint = CGPointMake(CGRectGetMidX(cellRect), CGRectGetMidY(cellRect));
    [frontLayer setPosition:aPoint];
    
    return frontLayer;
}

//- (CALayer*)makeLayerWithImage:(NSImage*)theImage atRect:(CGRect)cellRect {
//    
//    CALayer* frontLayer = [CALayer layer];
//    [frontLayer setContents:theImage];
//    [frontLayer setBounds:CGRectMake(0, 0, cellRect.size.width, cellRect.size.height)];
//    [frontLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
//    CGPoint aPoint = CGPointMake(CGRectGetMidX(cellRect), CGRectGetMidY(cellRect));
//    [frontLayer setPosition:aPoint];
//    
//    return frontLayer;
//}

/*
- (void)loadGenreToColourMap {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GenreColours" ofType:@"plist"];
        
        // This loads the contents into the plistXML field
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        // And convert the static property list into property list objects
        _genreToColourDictionary = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
}
*/

//FIX:
// MARK: This can never work! Is it even called?
//- (void)getRow:(NSUInteger *)row andCol:(NSUInteger *)col forSongID:(NSUInteger)songID {
//    NSAssert(_colsPerRow > 0, @"Error. 0 columns will cause a div by zero.");
//    *row = floor(songID / _colsPerRow);
//    *col = songID - (*row) * _colsPerRow;
//}

- (void)setCoverImage:(NSImage *)theImage forSongWithID:(id<SongIDProtocol>)songID {

    NSInteger cellTag = [_songCellMatrix indexOfObjectWithSongID:songID];
    TGGridCell * theCell = [_songCellMatrix cellWithTag:cellTag];
    NSAssert(theCell != nil, @"WTF, the cell is nil");
//    NSAssert(theCell.hideImage == NO, @"WTF, the cell image is hidden.");
    theCell.hideImage = NO;
    NSAssert(theImage != nil, @"ERROR! setCoverImage, the image is nil");
    
    //TODO: This should only be animated if the cover is visible on screen.
    // If we are setting the cover for the currently playing song do a pop animation,
    // otherwise just fade it in.
    if (songID == [_songPoolAPI lastRequestedSongID]) {
        [self coverPushAndFadeAnimationForCell:theCell withImage:theImage];
    }else {
        [self coverFadeInAnimation:theCell withImage:theImage];
    }
}

- (NSImage*)coverImageForSongWithId:(id<SongIDProtocol>)songId {
    NSInteger cellTag = [_songCellMatrix indexOfObjectWithSongID:songId];
    TGGridCell * theCell = [_songCellMatrix cellWithTag:cellTag];

    if ((theCell == nil) || (theCell.image == nil) || (theCell.hideImage == YES)) {
        NSLog(@"WTF! coverImageForSongWithId theCell or theCell.image was nil");
    }
    NSAssert(((theCell != nil) && (theCell.image != nil)), @"coverImageForSongWithId theCell or theCell.image was nil");
    
    theCell.hideImage = NO;
    return theCell.image;
}

//// Obviously this will animate the change eventually.
//- (void)animateCoverChange:(NSImage *)theImage forCell:(TGGridCell *)theCell {
//    [self coverPushAndFadeAnimationForCell:theCell withImage:theImage];
//}



static NSInteger const kUndefinedID =  -1;

- (id<SongIDProtocol>)cellToSongID:(TGGridCell*)theCell {
    
    if ( theCell == nil ) return nil;
    
    NSInteger cellTag = [theCell tag];
    // If the cell has not yet been connected to a song ID, pick one from the unmapped songs and connect it.
    if (cellTag ==  kUndefinedID) {
        // No id yet, so pick one from the unmapped song set.
        u_int32_t unmappedCount =(u_int32_t)[unmappedSongIDArray count];
        if (unmappedCount < 1) {
            NSLog(@"eek");
            return nil;
        }
        
        int randomSongIDIndex = arc4random_uniform(unmappedCount);
        
        // get the randomSong id out of the array.
        id<SongIDProtocol> songID = [unmappedSongIDArray objectAtIndex:randomSongIDIndex];
        [unmappedSongIDArray removeObjectAtIndex:randomSongIDIndex];
        
        [theCell setTag:[_songCellMatrix tagForSongWithID:songID]];
        
        return songID;
    } else
        return [_songCellMatrix songIDForSongWithTag:cellTag];
}

/*
-(TGGridCell*)songIDToCell:(id)songID {
    // Traverse the cellTagToSongID array and return the cell that matches it or null if none is found.
    for (int idx=0; idx < [[_songCellMatrix cellTagToSongID] count]; idx++) {
        NSString* tmpID = [[_songCellMatrix cellTagToSongID] objectAtIndex:idx];
        // TEO: comparison of the song id really ought to be done in a id class that knows how instead of
        // assuming it's a string.
        if ([tmpID isEqualToString:songID]) {
            // The cellTagToSongID index is the same as the cell's tag.
            return [_songCellMatrix cellWithTag:idx];
        }
    }
    return nil;
}
*/

- (void)runTest {
    
    dispatch_async(testingQueue, ^{
    NSInteger rowCount, colCount;
    NSPoint spd = NSMakePoint(1, 1);
    [_songCellMatrix getNumberOfRows:&rowCount columns:&colCount];
    
        for (int row=0; row < rowCount; row++) {
            for (int col=0; col < colCount; col++) {
//                NSRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
//                [_songCellMatrix scrollRectToVisible:cellRect];
                
//                NSLog(@"the frame of the cell at %d,%d is %@",row,col,NSStringFromRect(cellRect));
                
//                [_songCellMatrix scrollCellToVisibleAtRow:row column:col];
//                [_songCellMatrix display];
//                [_songCellMatrix setNeedsDisplay];

//                [_songGridScrollView setNeedsDisplay:YES];
//    CGRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
//                [_songGridScrollView scrollPoint:cellRect.origin];
                [self songGridScrollViewDidChangeToRow:row andColumn:col withSpeedVector:spd];
                
                // Wait a bit.
//                usleep(50000);
                [_songCellMatrix getNumberOfRows:&rowCount columns:&colCount];
            }
        }
        NSLog(@"TESTING DONE");
    });
}

/** growMatrix runs on the main thread.
 Increments the matrix by one new cell and returns it.
 */
-(TGGridCell*)growMatrix {

    static int songSerialNumber = 0;
    NSInteger rowCount, colCount, newRow, newCol;
    
    // Calculate the current (before we have grown the matrix) row and column.
    NSUInteger row = floor(songSerialNumber/ _colsPerRow);
    NSUInteger col = songSerialNumber - (row*_colsPerRow);
    
    // Get the actual rows and columns in the matrix.
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
    
    [_songCellMatrix renewAndSizeRows:newRow columns:newCol];
    
    NSAssert([[_songCellMatrix cells] count] > songSerialNumber, @"Eeek. songID is bigger than the song cell matrix");
    
    // Find the existing cell for this serial number.
    TGGridCell *existingCell = [[_songCellMatrix cells] objectAtIndex:songSerialNumber];

    // Increment serial number ready for the next call.
    songSerialNumber++;
    
    return existingCell;
}


/** addMatrixCell2 runs on main thread.
 Called for every new song added by the song pool (via main view controller's songPoolDidLoadSongURLWithID)
 */
- (void)addMatrixCell2:(id<SongIDProtocol>)songID {
    
    // Do pop up anim before we add the actual cell.
    NSInteger row,col;
    TGGridCell* existingCell = [self growMatrix];
    [_songCellMatrix incrementActiveCellCount];

    [_songCellMatrix getRow:&row column:&col ofCell:existingCell];
    
    // Add the id of this song to an array of unassigned songs.
    // We will then pick randomly from that array to assign to a cell in the matrix.
    [unmappedSongIDArray addObject:songID];

    
    CGRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
    CGRect theFrame = [[self songGridScrollView] documentVisibleRect];

    // Only do the work if we're actually visible.
    if (NSIntersectsRect(cellRect, theFrame)) {
        
        CALayer* frontLayer =[self makeLayerWithImage:_defaultImage atRect:cellRect];
        
        [[[[self songGridScrollView] documentView] layer] addSublayer:frontLayer];
        [CATransaction commit];
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            
            [frontLayer addAnimation:_bounceAnimation forKey:@"bounce"];
        } completionHandler:^{
            
            [frontLayer removeFromSuperlayer];
            
              // This is now done JIT or when all songs have been loaded.
            [existingCell setImage:_defaultImage];
        
            [_songCellMatrix setNeedsDisplay];
            
        }];
    } else
    {
          // This is now done JIT or when all songs have been loaded.
        [existingCell setImage:_defaultImage];
    }
    
    [_songCellMatrix setNeedsDisplay];
}


- (void)animateMatrixZoom:(NSInteger)zoomQuantum {

    // Note which cell is the currently selected so that we can keep it in view after the zooming is done.

    NSInteger theTag = [_songCellMatrix tagForSongWithID:[_songPoolAPI lastRequestedSongID]];
    TGGridCell* selectedCell = [_songCellMatrix cellWithTag:theTag];
//    TGGridCell *selectedCell = [self songIDToCell:[_delegate lastRequestedSongID]];
    
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
    NSRect newGridRect = [_songGridScrollView bounds];
    NSLog(@"the new grid rect is %@",NSStringFromRect(newGridRect));
    
    // Make a view to cover the existing grid view before re-configuring it and to draw the zooming songs onto.
    NSView *bgView = [[NSView alloc] initWithFrame:newGridRect];
    [_songCellMatrix setFrame:newGridRect];

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
    
    for (int cellCol=0; cellCol < loopCols; cellCol++) {
        
        for (NSInteger cellRow=startRow; cellRow < startRow+loopRows; cellRow++) {
            
            if (cellRow*_colsPerRow+cellCol < currentSongCount) {
                
                // Get the cell's current frame.
                NSRect cellFrame = [_songCellMatrix coverFrameAtRow:cellRow column:cellCol];
                
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

//- (void)zoomAnimation:(NSView *)theView {
//    
//}
//
//
//- (void)coverPushAnimation:(TGGridCell *)theCell withImage:(NSImage *)theImage {
//    
//}

- (void)coverFadeInAnimation:(TGGridCell *)theCell withImage:(NSImage *)theImage {
    
    // First we get the cell's rect.
    NSInteger row, col;
    [_songCellMatrix getRow:&row column:&col ofCell:theCell];
    CGRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
    
    CABasicAnimation* fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnim.fromValue = [NSNumber numberWithFloat:0.0];
    fadeAnim.toValue = [NSNumber numberWithFloat:1.0];
    fadeAnim.duration = 1.0;
    
    CALayer* frontLayer = [self makeLayerWithImage:theImage atRect:cellRect];

        [[[[self songGridScrollView] documentView] layer] addSublayer:frontLayer];

        // Flush layer to screen.
        [CATransaction commit];
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            
            [frontLayer addAnimation:fadeAnim forKey:@"opacity"];
            
        }completionHandler:^{
        
            theCell.image = theImage;
            [frontLayer removeFromSuperlayer];

            // Ensure that the matrix redraws the rect of the cell we've just hidden.
            [_songCellMatrix setNeedsDisplayInRect:cellRect];

        }];
}

// This animation will push the blank cover image into the screen whilst its cover image fades in and it pops back up to fill its frame.
- (void)coverPushAndFadeAnimationForCell:(TGGridCell *)theCell withImage:(NSImage *)theImage {
    
    NSInteger row, col;
    // Get the cell's row and column.
    [_songCellMatrix getRow:&row column:&col ofCell:theCell];
    
    // Get the cell's rect.
    CGRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
    
    // Make a layer from the given image.
    CALayer *frontLayer = [self makeLayerWithImage:theImage atRect:cellRect];
    
    // This breaks if not running on main thread. But it also causes uncommitted CATransactions to occur :(

    [[[[self songGridScrollView] documentView] layer] addSublayer:frontLayer];
    
    // Flush layer to screen.
    [CATransaction commit];
        
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        
            // Since we're about to animate a layer on top of the current cell, we temporarily hide it.
            theCell.hideImage = YES;
        
            // This sets the cell's image to the "fetching" image. But when I do this, in the completion handler, the image is drawn as though nothing is there.
            // If, instead, the image is set to nil the completion handler will show theCell.image just fine as the "fetching" image.
            theCell.image = theImage;

            // Ensure that the matrix redraws the rect of the cell we've just hidden.
            [_songCellMatrix setNeedsDisplayInRect:cellRect];
        
            [frontLayer addAnimation:_pushBounceAnimation forKey:@"scale"];
            
        }completionHandler:^{
            
            // We're done with the animation, so now we can show it again.
            theCell.hideImage = NO;
            
            // And remove the animation layer.
            [frontLayer removeFromSuperlayer];
            
            // Ensure that the matrix redraws the rect of the cell we've just made visible.
            [_songCellMatrix setNeedsDisplayInRect:cellRect];

        }];
//    });
}

//// Test for cover flip animation.
//- (void)coverFlipAnimationForCell:(TGGridCell *)theCell withImage:(NSImage *)theImage {
//    
//    NSInteger row, col;
//    [_songCellMatrix getRow:&row column:&col ofCell:theCell];
//    CGRect cellRect = [_songCellMatrix coverFrameAtRow:row column:col];
//    
//    NSImageView *frontView = [[NSImageView alloc] initWithFrame:cellRect];
//    [frontView setImage:[theCell image]];
//    [frontView setWantsLayer:YES];
//    [frontView setCanDrawSubviewsIntoLayer:YES];
//    [frontView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
//    
//    // Breaks if not done on main thread.
//    [[[self songGridScrollView] documentView] addSubview:frontView];
//    
//    // We want the animation to occur from the center of the view layer.
//    // The layer's anchor point is defined in unit points (0 to 1) and should default to its center at (0.5,0.5) but doesn't.
//    // The layer position coordinates are relative to the anchorpoint of the layer in the coordinates of its superview.
//    
//    /*
//    +Super view+––––––––––+
//    |                     |
//    |       +Layer+–+     |
//    |       |       |     |
//    +––––––––-–>*   |     |
//    | x pos |   ^   |     |
//    |       +–––+–––+     |
//    |           |         |
//    |           |y pos    |
//    |           |         |
//    +–––––––––––+–––––––-–+
//    */
//    
//    [frontView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//    
//    CGPoint center = CGPointMake(CGRectGetMidX(frontView.frame), CGRectGetMidY(frontView.frame));
//    
//    // Disable implicit animations whilst we set the visible view's initial position.
//    [CATransaction begin];
//    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
// 
//    // The layer's position is relative to the anchor point.
//    // Since we've moved the layer's anchor point to the middle of its bounds it should be set to the center to avoid moving.
//    [frontView.layer setPosition:center];
//    
//    [CATransaction commit];
//    
//    theCell.image = nil;
//    
//    
//    // Set up the back side of the cover.
//    NSImageView *backView= [[NSImageView alloc] initWithFrame:cellRect];
//    [backView setImage:theImage];
//    [backView setWantsLayer:YES];
//    [backView setCanDrawSubviewsIntoLayer:YES];
//    [backView setHidden:YES];
//    
//    [[[self songGridScrollView] documentView] addSubview:backView];
//    
//    // We want the animation to occur from the center of the view.
//    [backView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//    center = CGPointMake(CGRectGetMidX(backView.frame), CGRectGetMidY(backView.frame));
//    [backView.layer setPosition:center];
//    
//    // Do this as the first thing.
//    CATransform3D perspectiveTransform = CATransform3DIdentity;
//    perspectiveTransform.m34 = 1.0/-500;
//    backView.layer.transform = perspectiveTransform;
//    
//    // Set the backview layer's transform to the position we want to end at *after* the animation is done and the presentation layer removed.
//    // This flips the layer on the y axis (upside down)
//    backView.layer.transform = CATransform3DScale(backView.layer.transform, 1, -1, 1);
//    
//    // Rotate it pi radians so the back is facing the projection plane. It should look right way up.
//    backView.layer.transform = CATransform3DRotate(backView.layer.transform, M_PI, 1, 0, 0);
//    
//    
//    NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
//    
//    int count = 12;
//    CGFloat frac = M_PI/count;
//    for (int i=0; i<count; i++) {
//        [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
//    }
//    
//    NSArray *frontVals = [sinVals subarrayWithRange:NSMakeRange(0, count/2+1)];
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
//        
//        if (frontView.layer == nil) {
//            return ;
//        }
//        
//        
//        CATransform3D tranny = CATransform3DIdentity;
//        tranny.m34 = 1.0/-500;//eyePosition;
//        
//        // Apply the transform to the view layer.
//        frontView.layer.transform = tranny;
//        
//        CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
//        
//        flipAnimation.values = frontVals;
//        
//        flipAnimation.duration = 2;
//        flipAnimation.removedOnCompletion = YES;
//        
//        // Ensure that the model layer is in the same final state as the presentation layer to avoid glitching.
//        // This needs to happen before the animation is added so that the implicit animation is overridden by the explicit one.
//        frontView.layer.transform = CATransform3DRotate(tranny, M_PI_2, 1.0f, 0.0f, 0.0f);
//        
//        // Add the explicit animation.
//        [frontView.layer addAnimation:flipAnimation forKey:@"flip"];
//        
//    }completionHandler:^{
//        
//        [frontView removeFromSuperviewWithoutNeedingDisplay];
//        
//        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
//            
//            if (backView.layer == nil) {
//                return ;
//            }
//            
//            // We are about to see the back view so make sure it's not hidden.
//            [backView setHidden:NO];
//            
////            NSArray *backVals = [sinVals subarrayWithRange:NSMakeRange(count/2, count/2)];
//            
//            // reverse the front vals so the front layer can tip back and reveal itself.
//            NSMutableArray *testVals = [NSMutableArray arrayWithCapacity:[frontVals count]];
//            NSEnumerator *enumerator = [frontVals reverseObjectEnumerator];
//            for (id element in enumerator) {
//                [testVals addObject:element];
//            }
//            
//            CAKeyframeAnimation *flopAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
//            
//            flopAnimation.values = testVals;
//            
//            flopAnimation.duration = 2;
//            
//            [backView.layer addAnimation:flopAnimation forKey:@"flop"];
//            
//        } completionHandler:^{
//            
//            [backView removeFromSuperviewWithoutNeedingDisplay];
//            
//            // Remove newURLImage without needing display because we have to call setNeedsDisplay on the whole matrix anyway.
//            [theCell setImage:theImage];
//            
//            [_songCellMatrix setNeedsDisplay];
//            
//        }];
//    }];
//}


//- (void)flipAnimation:(NSView *)theView {
//    
//    if (theView.layer != nil) {
//        
//        CATransform3D tranny = CATransform3DIdentity;
//        tranny.m34 = 1.0/-500;//eyePosition;
////        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
//        
//        // Apply the transform to the view layer.
//        theView.layer.transform = tranny;
//        
//        CGPoint center = CGPointMake(CGRectGetMidX(theView.frame), CGRectGetMidY(theView.frame));
//        [theView.layer setPosition:center];
//        
//        // We want the animation to occur from the center of the view.
//        [theView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//        
//        CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
//        
//        NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
//        
//        CGFloat frac = M_PI*2/10;
//        for (int i=0; i<10; i++) {
//            [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
//        }
//        flipAnimation.values = sinVals;
//        // Set the keyframes for the flip animation.
////        flipAnimation.values = [NSArray arrayWithObjects:
////                                  [NSNumber numberWithFloat:0.1],
////                                  [NSNumber numberWithFloat:1.5],
////                                  [NSNumber numberWithFloat:0.95],
////                                  [NSNumber numberWithFloat:1.0], nil];
//        
//        flipAnimation.duration = 1;//0.25;
//        flipAnimation.removedOnCompletion = YES;
//        
//        [theView.layer addAnimation:flipAnimation forKey:@"flip"];
//        
//    }
//}

//- (void)flipAnimationFrom:(NSView *)frontView toView:(NSView *)backView {
//    
//        NSMutableArray *sinVals = [[NSMutableArray alloc]initWithCapacity:10];
//    
//    int count = 12;
//        CGFloat frac = M_PI/count;
//        for (int i=0; i<count; i++) {
//            [sinVals addObject:[NSNumber numberWithFloat:-i*frac]];
//        }
//    
//    
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
//        if (frontView.layer != nil) {
//            
//            NSArray *frontVals = [sinVals subarrayWithRange:NSMakeRange(0, count/2)];
//            
//            CATransform3D tranny = CATransform3DIdentity;
//            tranny.m34 = 1.0/-500;//eyePosition;
//            //        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
//            
//            // Apply the transform to the view layer.
//            frontView.layer.transform = tranny;
//            
//            CGPoint center = CGPointMake(CGRectGetMidX(frontView.frame), CGRectGetMidY(frontView.frame));
//            [frontView.layer setPosition:center];
//            
//            // We want the animation to occur from the center of the view.
//            [frontView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//            
//            CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
//            
//            flipAnimation.values = frontVals;
//            
//            flipAnimation.duration = 5;//0.25;
//            flipAnimation.removedOnCompletion = YES;
//            
//            [frontView.layer addAnimation:flipAnimation forKey:@"flip"];
//        }
//        
//    }completionHandler:^{
//        NSLog(@"flip completion handler");
//        if (backView.layer != nil) {
//            
//            [backView setHidden:NO];
//            NSArray *backVals = [sinVals subarrayWithRange:NSMakeRange(count/2, count/2)];
//            CATransform3D tranny = CATransform3DIdentity;
//            tranny.m34 = 1.0/-500;//eyePosition;
//            //        perspective = CATransform3DRotate(perspective, 45.0f * M_PI / 180.0f, 0, 1, 0);
//            
//            // Apply the transform to the view layer.
//            backView.layer.transform = tranny;
//            
//            CGPoint center = CGPointMake(CGRectGetMidX(backView.frame), CGRectGetMidY(backView.frame));
//            [backView.layer setPosition:center];
//            
//            // We want the animation to occur from the center of the view.
//            [backView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//            
//            CAKeyframeAnimation *flipAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
//            
//            flipAnimation.values = backVals;
//            
//            flipAnimation.duration = 5;//0.25;
//            flipAnimation.removedOnCompletion = YES;
//            
//            [backView.layer addAnimation:flipAnimation forKey:@"flip"];
//        }
//    }];
//    
//}


//- (void)bouncyPopAnimation:(NSView *)theView {
//    
//    if (theView.layer != nil) {
//        
//        CGPoint center = CGPointMake(CGRectGetMidX(theView.frame), CGRectGetMidY(theView.frame));
//        [theView.layer setPosition:center];
//        
//        // We want the animation to occur from the center of the view.
//        [theView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
//        
//        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
//        
//        // Set the keyframes for the pop animation.
//        bounceAnimation.values = [NSArray arrayWithObjects:
//                                  [NSNumber numberWithFloat:0.1],
//                                  [NSNumber numberWithFloat:1.5],
//                                  [NSNumber numberWithFloat:0.95],
//                                  [NSNumber numberWithFloat:1.0], nil];
//        
//        bounceAnimation.duration = 0.25;
//        bounceAnimation.removedOnCompletion = YES;
//        
//        [theView.layer addAnimation:bounceAnimation forKey:@"bounce"];
//        
//    }
//}

//- (void)test:(NSView *)aView {
//    
//    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
//    a.fromValue = [NSNumber numberWithFloat:0];
//    a.toValue = [NSNumber numberWithFloat:-M_PI*2];
//    
//    a.duration = 1.8; // seconds
//    a.repeatCount = HUGE_VAL;
//    [aView.layer addAnimation:a forKey:nil];
//}
/*
// Build a list of song ids to pass to the song pool so it can cache them.
// Internally the cache is a set to which we can add and perform other set operations on (such as differences)
- (NSArray *)buildCacheArrayWithStrategy:(CacheStrategy)cacheStrategy
                            forRow:(NSInteger)theRow
                         andColumn:(NSInteger)theColumn
                    andSpeedVector:(NSPoint)speedVector {
    
    // First we need to decide on a caching strategy.
    // For now we will simply do a no-brains area caching of two songs in every direction from the current cursor position.

    // Make sure we have an inited cache.
    
    NSMutableSet* wantedCache = [[NSMutableSet alloc] initWithCapacity:25];
    
    
    NSInteger radius = 2;
    NSInteger maxRows = [_songCellMatrix numberOfRows];
    NSInteger maxCols = [_songCellMatrix numberOfColumns];
    
    for (NSInteger matrixRows=theRow-radius; matrixRows<=theRow+radius; matrixRows++) {
        for (NSInteger matrixCols=theColumn-radius; matrixCols<=theColumn+radius; matrixCols++) {
            if ((matrixRows >= 0) && (matrixRows <maxRows)) {
                if((matrixCols >=0) && (matrixCols < maxCols)) {
                    
                    // skip if this is the selected cell (which is already cached or requested).
                    if ((matrixRows == theRow) && (matrixCols == theColumn))
                        continue;
                    
                    NSAssert([[_songCellMatrix cells] count] > 0, @"shit no cells");
                    TGGridCell *theCell = [_songCellMatrix cellAtRow:matrixRows column:matrixCols];
                    
                    // Skip if invalid cell.
                    if (theCell == nil) {
                        continue;
                    }
                    
                    id songID = [self cellToSongID:theCell];
                    if (songID != nil) {
                        [wantedCache addObject:songID];
                    }
                }
            }
        }
    }
    // Remove from the wanted cache what's already cached.
    [wantedCache minusSet:songIDCache];
    
    // Remove from the existing cache what is not in the wanted cache.
    [songIDCache intersectSet:wantedCache];
    
    // now the existing cache becomes the stale cache
    NSSet* staleCache = songIDCache;
    [_delegate clearSongCache:[staleCache allObjects]];
    
    // Now load the wantedCache
    [_delegate loadSongCache:[wantedCache allObjects]];

    songIDCache = wantedCache;
    
//    NSLog(@"I'm thinking %@",cellIndexArray);
    // Then we build a list of song ids.
    return [songIDCache allObjects];
}
*/

- (id<SongIDProtocol>)lastRequestedSong {
    return [_songPoolAPI lastRequestedSongID];
}

- (id<SongIDProtocol>)currentlyPlayingSongId {
    return [_songPoolAPI currentlyPlayingSongID];
}

- (id<SongIDProtocol>)songIDFromGridColumn:(NSInteger)theCol andRow:(NSInteger)theRow {
    TGGridCell *theCell = [_songCellMatrix cellAtRow:theRow column:theCol];
    return [self cellToSongID:theCell];
}

-(void)keyDown:(NSEvent *)theEvent {
    NSLog(@"songgridcontroller keydown");
}

- (void)lmbDownAtMousePos:(NSPoint)mousePos {
    NSPoint mouseLoc = [_songGridScrollView convertPoint:mousePos fromView:nil];
    NSInteger mouseRow, mouseCol;
    [_songGridScrollView.documentView getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
    TGGridCell *currentCell = [_songGridScrollView.documentView cellAtRow:mouseRow column:mouseCol];
    if ([currentCell tag] != -1) {
        
        NSRect theRect = [_songGridScrollView.documentView coverFrameAtRow:mouseRow column:mouseCol];
        [self buttonDownInCellFrame:theRect];
    }
   
}

-(NSPoint)centerOfCellAtMousePos:(NSPoint)mousePos {
    NSPoint mouseLoc = [_songGridScrollView convertPoint:mousePos fromView:nil];
    NSInteger mouseRow, mouseCol;
    [_songGridScrollView.documentView getRow:&mouseRow column:&mouseCol forPoint:mouseLoc];
    
//    TGGridCell *currentCell = [_songGridScrollView.documentView cellAtRow:mouseRow column:mouseCol];
//    NSRect theRect = [_songCellMatrix convertRect:[_songCellMatrix coverFrameAtRow:mouseRow column:mouseCol] toView:_songGridScrollView];
    NSRect theRect = [_songCellMatrix coverFrameAtRow:mouseRow column:mouseCol];
    return [_songGridScrollView convertPoint:theRect.origin toView:nil];
}

- (void)buttonDownInCellFrame:(NSRect)cellFrame {
//    [self togglePopoverAtCellFrame:cellFrame withDelay:0.0];
//    return;
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

- (void)userSelectedSweetSpotMarkerAtIndex:(NSUInteger)ssIndex {
    
    // Ask the song pool for the currently playing song.
    id<SongIDProtocol> theSongID = [_songPoolAPI currentlyPlayingSongID];
    // Ask the song pool for the sweet spots for the given song and extract the sweet spot at the given index.
    NSNumber* sweetSpotTime = [[_songPoolAPI sweetSpotsForSongID:theSongID] objectAtIndex:ssIndex];
    
    // Ask the song pool to set the playhead position (and the playback) to the given time for the given song.
//    [_songPoolAPI setRequestedPlayheadPosition:sweetSpotTime forSongID:theSongID];
    [_songPoolAPI setRequestedPlayheadPosition:sweetSpotTime];
}

- (void)userSelectedExistingSweetSpot:(id)sender {
    NSLog(@"userSelectedExistingSweetSpot called");
}
- (void)userCreatedNewSweetSpot:(id)sender {
    NSLog(@"userCreatedNewSweetSpot called");    
}



// TGSongGridScrollViewDelegate methods:
- (void)songGridScrollViewDidScrollToRect:(NSRect)theRect {
    // TEO: Make a method inside the songUIViewController that is a delegate of the TGSongGridScrollView that is called whenever scrolling/moving.
    //[_songUIViewController setUIPosition:theRect.origin withPopAnimation:NO];
}



// Called when a new row and column is selected either by moving mouse pointer or scrolling a new cell under it.
- (void)songGridScrollViewDidChangeToRow:(NSInteger)theRow
                               andColumn:(NSInteger)theColumn
                               withSpeedVector:(NSPoint)theSpeed {
    
    // If a popover is shown, don't change cells.
        if ([[_songTimelineController songTimelinePopover] isShown]) {
            return;
        }
    
//    NSLog(@"The selection speed %@",NSStringFromPoint(theSpeed));
    
    //NSRect theRect = [_songCellMatrix convertRect:[_songCellMatrix coverFrameAtRow:theRow column:theColumn] toView:_songGridScrollView];
    //[_songUIViewController setUIPosition:theRect.origin withPopAnimation:YES];
    
    TGGridCell *theCell = [_songCellMatrix cellAtRow:theRow column:theColumn];
    // Early out if the coordinates are pointing to an invalid cell.
    if (theCell == nil) return;
    
    id<SongIDProtocol> songID = [self cellToSongID:theCell];
    // Early out if the cell is not pointing at an actual song.
    if (songID == nil) return;
    
    // Collect the context for this selection and pass it to the mainviewcontroller which will pass
    // it on to the songpool where the cache is generated.
    NSValue* selectionPos = [NSValue valueWithPoint:NSMakePoint(theColumn, theRow)];
    NSValue* speedVector = [NSValue valueWithPoint:theSpeed];
    NSValue* gridDims = [NSValue valueWithPoint:NSMakePoint([_songCellMatrix numberOfColumns], [_songCellMatrix numberOfRows])];

    //CDFIX moved below caching so we cache first.
    [_delegate userSelectedSongID:songID withContext:@{@"pos" : selectionPos, @"spd" : speedVector, @"gridDims" : gridDims}];
    
    // If a popover is shown, hide it.
//    if ([[_songTimelineController songTimelinePopover] isShown]) {
//        [[_songTimelineController songTimelinePopover] close];
//    }
    
//    NSRect cellFrame = [_songCellMatrix coverFrameAtRow:theRow column:theColumn];
//    [self togglePopoverAtCellFrame:cellFrame withDelay:3.0];
}


- (void)setDebugCachedFlagForSongID:(id<SongIDProtocol>)songID toValue:(BOOL)value {
    
    // Get the cell for the id
    TGGridCell* aCell = [_songCellMatrix cellWithTag:[_songCellMatrix tagForSongWithID:songID]];
    NSInteger row, col;
    [_songCellMatrix getRow:&row column:&col ofCell:aCell];
    NSRect cellFrame = [_songCellMatrix coverFrameAtRow:row column:col];
    NSRect cachedFrame = NSMakeRect(cellFrame.origin.x+10 , cellFrame.origin.y+10, 15, 15);
    CALayer* theLayer = [_debugLayerDict objectForKey:songID];
    
    if (value) {
        if (theLayer == nil) {
            theLayer = [self makeLayerWithImage:[NSImage imageNamed:@"cached"] atRect:cachedFrame];
            [_debugLayerDict setObject:theLayer forKey:songID];
        }
        [[[[self songGridScrollView] documentView] layer] addSublayer:theLayer];
        [CATransaction commit];
        
    } else {
        if (theLayer) {
            [theLayer removeFromSuperlayer];
            [_debugLayerDict removeObjectForKey:songID];
        }
    }
    
}

- (void)songGridScrollViewDidRightClickSongID:(id<SongIDProtocol>)songID {
    NSLog(@"RMB");
    // Turn song id to song
    //[_songPool fetchSongData];
    //[_songPool offsetSweetSpotForSongID:songID bySeconds:-0.25];
}

@end

