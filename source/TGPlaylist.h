//
//  TGPlaylist.h
//  Proto3
//
//  Created by Teo Sartori on 01/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

// Protocol forward declarations
//@protocol TGPlaylistDelegate;
@protocol TGSongPoolDelegate;
@protocol SongIDProtocol;

@interface TGPlaylist : NSObject <NSTableViewDataSource> {
    NSMutableArray *songList;
//    NSUInteger posInPlaylist;
}

@property NSUInteger posInPlaylist;
//@property id<TGPlaylistDelegate> delegate;
@property id<TGSongPoolDelegate> delegate;


- (void)addSong:(id<SongIDProtocol>)aSongID atIndex:(NSUInteger)index;
- (void)removeSongAtIndex:(NSUInteger)index;
- (void)removeSong:(id<SongIDProtocol>)aSong;
- (id<SongIDProtocol>)getNextSongIDToPlay;
- (void)storeWithName:(NSString *)theName;
- (NSUInteger)songsInPlaylist;
- (id<SongIDProtocol>)songIDAtIndex:(NSUInteger)index;
@end


// Delegate method declarations.
//@protocol TGPlaylistDelegate <NSObject>
//
//- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID;
//
//@end