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


@interface TGPlaylistViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    TGPlaylist *playlist;
//    id songPool;
    
//    id delegate;
}

@property IBOutlet NSTableView *playlistTableView;
@property (weak) IBOutlet NSProgressIndicator *playlistProgress;

@property id <TGPlaylistViewControllerDelegate>delegate;

@property id mainController;

//- (void)setDelegate:(id)newDelegate;
//- (id)delegate;
//- (id)initWithDelegate:(id)delegate;
- (void)storePlaylistWithName:(NSString *)theName;
- (void)addSongToPlaylist:(id)aSongID;
- (void)removeSongFromPlaylist:(id)aSongID;
- (id)getNextSongIDToPlay;
//- (void)addSongToPlaylist:(NSInteger)aSongID;
//- (void)removeSongFromPlaylist:(NSInteger)aSongID;
//- (NSInteger)getNextSongIDToPlay;

@end

// Delegate method declarations.
@protocol TGPlaylistViewControllerDelegate <NSObject>

// These are all methods defined in the SongPool class.
//- (NSDictionary *)songDataForSongID:(NSInteger)songID;
//- (NSURL *)songURLForSongID:(NSInteger)songID;
//- (NSNumber *)songDurationForSongID:(NSInteger)songID;
//- (void)requestSongPlayback:(NSInteger)songID withStartTimeInSeconds:(NSNumber *)time;
- (NSDictionary *)songDataForSongID:(id)songID;
- (NSURL *)songURLForSongID:(id)songID;
- (NSNumber *)songDurationForSongID:(id)songID;
- (void)requestSongPlayback:(id)songID withStartTimeInSeconds:(NSNumber *)time;

@end