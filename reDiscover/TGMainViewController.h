//
//  TGViewController.h
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

@interface songPositionClass: NSObject {
    double songTimePos;
}
@end

@protocol TGMainViewControllerDelegate <NSObject>

@end

@interface TGMainViewController : NSViewController <TGMainViewControllerDelegate>
{
    CGFloat playlistExpandedWidth;
    CGFloat infoExpandedWidth;
    
    NSString *infoLabel;
    NSString *playlistLabel;
    
    NSNumber *numnum;
}

@property TGSongPool *currentSongPool;
@property songPositionClass *songPosGlue;
@property NSObjectController *myObjectController;

// The three parts of the split view
@property TGPlaylistViewController *playlistController;
@property TGSongGridViewController *songGridController;
@property TGSongInfoViewController *songInfoController;

@property TGSongUIViewController *songUIController;

@property NSDictionary *genreToColourDictionary;

@property TGIdleTimer *idleTimer;

- (id)initWithFrame:(NSRect)theFrame;

// Delegate methods
- (void)setSongPool:(TGSongPool *)theSongPool;
- (id)lastRequestedSongID;

@end