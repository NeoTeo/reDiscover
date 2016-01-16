//
//  TGPlaylistViewController.h
//  Proto3
//
//  Created by Teo Sartori on 01/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Forward declarations
@class TGPlaylist;

@protocol TGPlaylistViewControllerDelegate;
@protocol TGMainViewControllerDelegate;
@protocol SongPoolAccessProtocol;
@protocol SongIDProtocol;

@interface TGPlaylistViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    TGPlaylist *playlist;
}

@property IBOutlet NSTableView *playlistTableView;
@property (weak) IBOutlet NSProgressIndicator *playlistProgress;

@property id<SongPoolAccessProtocol>songPoolAPI;
@property id<TGMainViewControllerDelegate> delegate;

- (void)storePlaylistWithName:(NSString *)theName;
- (void)addSongToPlaylist:(id<SongIDProtocol>)aSongID;
- (void)removeSongFromPlaylist:(id<SongIDProtocol>)aSongID;
- (id<SongIDProtocol>)getNextSongIDToPlay;

@end