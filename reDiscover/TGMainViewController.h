////
////  TGMainViewController.h
////  Proto3
////
////  Created by Teo Sartori on 13/03/2013.
////  Copyright (c) 2013 Teo Sartori. All rights reserved.
////
//
//#import <Cocoa/Cocoa.h>
//
//// Forward declarations:
//@class TGSongGridViewController;
//@class TGSongPool;
//@class TGSongCellMatrix;
//@class TGPlaylistViewController;
//@class TGSongInfoViewController;
//@class TGSongUIPopupController;
//@class TGCoverDisplayViewController;
//@class TGIdleTimer;
//@class DebugDisplay;
//
//@protocol SongIDProtocol;
//@protocol CoverDisplayViewController;
//
//@protocol TGMainViewControllerDelegate
//- (id)songIdFromGridPos:(NSPoint) pos;
//@end
//
//@interface TGMainViewController : NSViewController //<TGMainViewControllerDelegate>
//{
//    CGFloat playlistExpandedWidth;
//    CGFloat infoExpandedWidth;
//    
//    NSString *infoLabel;
//    NSString *playlistLabel;
//    
//    NSNumber *numnum;
// 
//    NSImage* fetchingImage;
//    NSImage* defaultImage;
//}
//
//// The url from the drop view.
//@property NSURL* theURL;
//
//@property TGSongPool *currentSongPool;
//@property NSObjectController *myObjectController;
//
//// The three parts of the split view
//// TODO     see if we can do this with protocols, once it works.
//@property TGCoverDisplayViewController *coverDisplayController;
//@property TGPlaylistViewController *playlistController;
//@property TGSongGridViewController *songGridController;
//@property TGSongInfoViewController *songInfoController;
//@property TGSongUIPopupController *songUIController;
//@property DebugDisplay* debugDisplay;
//@property NSDictionary *genreToColourDictionary;
//@property TGIdleTimer *idleTimer;
//
//- (id)initWithFrame:(NSRect)theFrame;
//- (void)setSongPool:(TGSongPool *)theSongPool;
//
//@end