//
//  TGSongGridController.h
//  Proto3
//
//  Created by teo on 18/03/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

// Needed for protocol.
// Fwd decl. of protocols cannot be used because the delegate methods need to be known to become a part of the delegate class.
#import "TGSongPool.h"
#import "TGSongGridScrollView.h"
#import "TGSongUIViewController.h"
#import "TGSongTimelineViewController.h"

// Forward declarations
@class TGSongCellMatrix;
@class TGPlaylistViewController;
@class TGSongInfoViewController;
@class TGSongTimelineViewController;
@class CAKeyframeAnimation;

// Forward declaration of protocol.
@protocol TGSongGridViewControllerDelegate;
@protocol TGSongTimelineViewControllerDelegate;

@interface TGSongGridViewController : NSViewController <TGSongGridScrollViewDelegate,TGSongTimelineViewControllerDelegate>
{
    float zoomFactor;
    NSMutableArray *unmappedSongIDArray;
    NSTimeInterval popupTimerStart;
    NSMutableSet *songIDCache;
}

@property id<TGSongGridViewControllerDelegate> delegate;

@property NSDictionary *genreToColourDictionary;
// Dimensions
@property NSUInteger interCellHSpace;
@property NSUInteger interCellVSpace;
@property NSUInteger currentCellSize;
@property NSUInteger numSongs;
@property NSUInteger colsPerRow;

@property NSImage *defaultImage;

//@property TGSongPool *songPool;
@property TGSongGridScrollView *songGridScrollView;
@property TGSongUIViewController *songUIViewController;

@property TGSongTimelineViewController *songTimelineController;

//@property NSView *songGridTopView;
@property TGSongCellMatrix *songCellMatrix;
@property NSProgressIndicator *pgIndicator;
@property CAKeyframeAnimation *pushBounceAnimation;

// Not sure we keep this
@property NSInteger currentSongID;

- (id)initWithFrame:(NSRect)newFrame;

//- (void)initSongGrid:(NSUInteger)songCount;
- (void)addMatrixCell2:(NSUInteger)songID;
- (void)animateMatrixZoom:(NSInteger)zoomQuantum;
- (void)setCoverImage:(NSImage *)theImage forSongWithID:(NSUInteger)songID;

// Delegate methods.
// TGSongGridScrollViewDelegate methods

//- (void)songGridScrollViewDidChangeToCell:(TGGridCell *)theCell withRect:(NSRect)theRect;
- (void)songGridScrollViewDidChangeToRow:(NSInteger)theRow andColumn:(NSInteger)theColumn;
- (void)songGridScrollViewDidScrollToRect:(NSRect)theRect;
- (void)songGridScrollViewDidRightClickSongID:(NSUInteger)songID;

// TGSongTimelineViewControllerDelegate methods
- (void)userSelectedSweetSpotMarkerAtIndex:(NSUInteger)ssIndex;

@end

@protocol TGSongGridViewControllerDelegate <NSObject>

- (NSInteger)lastRequestedSongID;
- (void)userSelectedSweetSpot:(NSUInteger)ssIndex;
-(void)userSelectedSongID:(NSUInteger)songID ;
- (void)requestSongArrayPreload:(NSArray *)theArray;

@end