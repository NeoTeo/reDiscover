//
//  TGSongTimelineViewController.h
//  Proto3
//
//  Created by Teo Sartori on 01/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// CMTime is a struct so it can't be forward declared and must be imported.
#import <CoreMedia/CMTime.h>

// Forward declarations

//@class TGSongPool;
@protocol TGSongTimelineViewControllerDelegate;
@protocol SongIDProtocol;
@protocol SongPoolAccessProtocol;


@interface TGSongTimelineViewController : NSViewController

//@property TGSong *currentSong;

@property id<TGSongTimelineViewControllerDelegate> delegate;
@property id<SongPoolAccessProtocol>songPoolAPI;

@property IBOutlet NSPopover *songTimelinePopover;
@property (weak) IBOutlet NSSlider *timelineBar;

@property NSArray *sweetSpotControls;


- (void)showTimelinePopoverRelativeToBounds:(CGRect)theBounds ofView:(NSView *)theView;

-(void)setCurrentSongID:(id<SongIDProtocol>)songID;//wipEv fromSongPool:(TGSongPool *)theSongPool;
//-(void)setCurrentSongID:(NSInteger)songID fromSongPool:(TGSongPool *)theSongPool;

// sweet spot action method called when a progress bar sweetspot is clicked.
- (void)sweetspotMarkerAction:(id)sender;

@end

@protocol TGSongTimelineViewControllerDelegate
- (void)userCreatedNewSweetSpot:(id)sender;
- (void)userSelectedExistingSweetSpot:(id)sender;
- (void)userSelectedSweetSpotMarkerAtIndex:(NSUInteger)ssIndex;

@end