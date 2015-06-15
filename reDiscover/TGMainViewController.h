//
//  TGMainViewController.h
//  Proto3
//
//  Created by Teo Sartori on 13/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Forward declarations:
@class TGSongGridViewController;
@class TGSongPool;
@class TGSongCellMatrix;
@class TGPlaylistViewController;
@class TGSongInfoViewController;
@class TGSongUIPopupController;
@class TGCoverDisplayViewController;

//@class TGSongUIViewController;
//@class TGSongTimelineViewController;
@class TGIdleTimer;
@class DebugDisplay;

@protocol TGSongPoolDelegate;
@protocol SongIDProtocol;
@protocol CoverDisplayViewController;

@protocol TGMainViewControllerDelegate <TGSongPoolDelegate>
- (void)userSelectedSongID:(id<SongIDProtocol>)songID withContext:(NSDictionary*)theContext;
- (void)setDebugCachedFlagsForSongIDArray:(NSArray*)songIDs toValue:(BOOL)value;
-(BOOL)isUIShowing;
@end

@interface TGMainViewController : NSViewController //<TGMainViewControllerDelegate>
{
    CGFloat playlistExpandedWidth;
    CGFloat infoExpandedWidth;
    
    NSString *infoLabel;
    NSString *playlistLabel;
    
    NSNumber *numnum;
 
    NSImage* fetchingImage;
    NSImage* defaultImage;
}

// The url from the drop view.
@property NSURL* theURL;

@property TGSongPool *currentSongPool;
@property NSObjectController *myObjectController;

// The three parts of the split view
//TODO: see if we can do this with protocols, once it works.
//@property id<CoverDisplayViewController> coverDisplayController;
@property TGCoverDisplayViewController *coverDisplayController;
@property TGPlaylistViewController *playlistController;
@property TGSongGridViewController *songGridController;
@property TGSongInfoViewController *songInfoController;
@property TGSongUIPopupController *songUIController;

//@property TGSongUIViewController *songUIController;

@property DebugDisplay* debugDisplay;

@property NSDictionary *genreToColourDictionary;

@property TGIdleTimer *idleTimer;

- (id)initWithFrame:(NSRect)theFrame;

- (void)setSongPool:(TGSongPool *)theSongPool;
//- (void)setDebugCachedFlagsForSongIDArray:(NSArray*)songIDs toValue:(BOOL)value;
//- (void)refreshCoverForSongId:(id<SongIDProtocol>)songId;

@end