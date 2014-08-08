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
@class TGSongUIViewController;
//@class TGSongTimelineViewController;
@class TGIdleTimer;
@class DebugDisplayController;

@protocol TGSongPoolDelegate;
@protocol SongIDProtocol;

@protocol TGMainViewControllerDelegate <TGSongPoolDelegate>
- (void)userSelectedSongID:(id<SongIDProtocol>)songID;
- (void)setDebugCachedFlagsForSongIDArray:(NSArray*)songIDs toValue:(BOOL)value;
@end

@interface TGMainViewController : NSViewController <TGMainViewControllerDelegate>
{
    CGFloat playlistExpandedWidth;
    CGFloat infoExpandedWidth;
    
    NSString *infoLabel;
    NSString *playlistLabel;
    
    NSNumber *numnum;
    
}

// The url from the drop view.
@property NSURL* theURL;

@property TGSongPool *currentSongPool;
@property NSObjectController *myObjectController;

// The three parts of the split view
@property TGPlaylistViewController *playlistController;
@property TGSongGridViewController *songGridController;
@property TGSongInfoViewController *songInfoController;

@property TGSongUIViewController *songUIController;

@property DebugDisplayController* debugDisplayController;

@property NSDictionary *genreToColourDictionary;

@property TGIdleTimer *idleTimer;

- (id)initWithFrame:(NSRect)theFrame;

- (void)setSongPool:(TGSongPool *)theSongPool;
//- (void)setDebugCachedFlagsForSongIDArray:(NSArray*)songIDs toValue:(BOOL)value;

@end