//
//  TGSongGridScrollView.h
//  Proto3
//
//  Created by Teo Sartori on 30/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// forward declarations
@class TGGridCell;

@protocol TGSongGridScrollViewDelegate;

@interface TGSongGridScrollView : NSScrollView

@property id <TGSongGridScrollViewDelegate>delegate;

@property NSInteger currentMouseRow, currentMouseCol;

@end

@protocol TGSongGridScrollViewDelegate <NSObject>
@optional
- (void)songGridScrollViewDidScrollToRect:(NSRect)theRect;
- (void)songGridScrollViewDidChangeToRow:(NSInteger)theRow andColumn:(NSInteger)theColumn withSpeedVector:(NSPoint)theSpeed;
//- (void)songGridScrollViewDidChangeToCell:(TGGridCell *)theCell withRect:(NSRect)theRect;
//- (void)songGridScrollViewDidChangeToSongID:(NSUInteger)songID withRect:(NSRect)theRect;
- (void)songGridScrollViewDidRightClickSongID:(NSUInteger)songID;
- (void)songGridScrollViewDidLeftClickSongID:(NSUInteger)songID;
- (void)buttonDownInCellFrame:(NSRect)cellFrame;
@end
