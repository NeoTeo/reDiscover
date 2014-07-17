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

@interface TGPlaylistViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    TGPlaylist *playlist;
}

@property IBOutlet NSTableView *playlistTableView;
@property (weak) IBOutlet NSProgressIndicator *playlistProgress;

@property id<SongPoolAccessProtocol>songPoolAPI;
@property id<TGMainViewControllerDelegate> delegate;

- (void)storePlaylistWithName:(NSString *)theName;
- (void)addSongToPlaylist:(id)aSongID;
- (void)removeSongFromPlaylist:(id)aSongID;
- (id)getNextSongIDToPlay;

@end

// Delegate method declarations.
@protocol TGPlaylistViewControllerDelegate <NSObject>

// These are all methods defined in the SongPool class.
- (NSDictionary *)songDataForSongID:(id)songID;
- (NSURL *)songURLForSongID:(id)songID;
- (NSNumber *)songDurationForSongID:(id)songID;
- (void)requestSongPlayback:(id)songID withStartTimeInSeconds:(NSNumber *)time;

@end