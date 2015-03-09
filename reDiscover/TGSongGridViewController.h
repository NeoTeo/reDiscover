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
@protocol TGSongTimelineViewControllerDelegate;


@protocol TGSongGridViewControllerDelegate <NSObject>

//- (id)lastRequestedSongID;
//- (void)userSelectedSweetSpot:(NSUInteger)ssIndex;
//- (void)userSelectedSongID:(id)songID ;
//- (void)cacheWithContext:(NSDictionary*)theContext;


@end


@protocol SongGridAccessProtocol
- (id)songIDFromGridColumn:(NSInteger)theCol andRow:(NSInteger)theRow;
- (id<SongIDProtocol>)currentlyPlayingSongId;
@end

//@interface TGSongGridViewController : NSViewController <TGSongGridViewControllerDelegate, TGSongGridScrollViewDelegate,TGSongTimelineViewControllerDelegate>
@interface TGSongGridViewController : NSViewController <SongGridAccessProtocol, TGSongGridScrollViewDelegate,TGSongTimelineViewControllerDelegate>
{
    float zoomFactor;
    NSMutableArray *unmappedSongIDArray;
    NSTimeInterval popupTimerStart;
    // A queue for running the debug test on
    dispatch_queue_t testingQueue;

}

//@property id<TGSongGridViewControllerDelegate> delegate;
@property id<TGMainViewControllerDelegate> delegate;
@property id<SongPoolAccessProtocol>songPoolAPI;

// debug
@property NSMutableDictionary* debugLayerDict;
@property NSDictionary *genreToColourDictionary;
// Dimensions
@property NSUInteger interCellHSpace;
@property NSUInteger interCellVSpace;
@property NSUInteger currentCellSize;
@property NSUInteger numSongs;
@property NSUInteger colsPerRow;
@property NSImage *defaultImage;

// TEO Move this into a dictionary perhaps?
@property CAKeyframeAnimation *pushBounceAnimation;
@property CAKeyframeAnimation *bounceAnimation;

@property TGSongGridScrollView *songGridScrollView;
@property TGSongUIViewController *songUIViewController;
@property TGSongTimelineViewController *songTimelineController;
@property TGSongCellMatrix *songCellMatrix;
@property NSProgressIndicator *pgIndicator;


- (void)lmbDownAtMousePos:(NSPoint)mousePos;
-(NSRect)cellFrameAtMousePos:(NSPoint)mousePos;
-(NSPoint)centerOfCellAtMousePos:(NSPoint)mousePos;

- (id)initWithFrame:(NSRect)newFrame;
- (void)addMatrixCell2:(id<SongIDProtocol>)songID;
- (void)animateMatrixZoom:(NSInteger)zoomQuantum;
- (void)setCoverImage:(NSImage *)theImage forSongWithID:(id<SongIDProtocol>)songID;
- (NSImage*)coverImageForSongWithId:(id<SongIDProtocol>)songId;

// Other classes' delegate methods we implement.

// TGSongGridScrollViewDelegate methods
- (void)songGridScrollViewDidChangeToRow:(NSInteger)theRow andColumn:(NSInteger)theColumn withSpeedVector:(NSPoint)theSpeed;
- (void)songGridScrollViewDidScrollToRect:(NSRect)theRect;
- (void)songGridScrollViewDidRightClickSongID:(id<SongIDProtocol>)songID;

// TGSongTimelineViewControllerDelegate methods
- (void)userSelectedSweetSpotMarkerAtIndex:(NSUInteger)ssIndex;
- (void)userSelectedExistingSweetSpot:(id)sender;
- (void)userCreatedNewSweetSpot:(id)sender;

// Set the cached flag on a cell that corresponds to the songID
- (void)setDebugCachedFlagForSongID:(id<SongIDProtocol>)songID toValue:(BOOL)value;

- (void)runTest;
@end



