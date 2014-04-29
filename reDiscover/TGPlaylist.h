//
//  TGPlaylist.h
//  Proto3
//
//  Created by Teo Sartori on 01/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TGPlaylistDelegate;

@interface TGPlaylist : NSObject <NSTableViewDataSource> {
    NSMutableArray *songList;
//    NSUInteger posInPlaylist;
}

@property NSUInteger posInPlaylist;
@property id<TGPlaylistDelegate> delegate;

//- (void)addSong:(NSInteger)aSongID atIndex:(NSUInteger)index;
- (void)addSong:(id)aSongID atIndex:(NSUInteger)index;
- (void)removeSongAtIndex:(NSUInteger)index;
//- (void)removeSong:(NSInteger)aSong;
- (void)removeSong:(id)aSong;
- (id)getNextSongIDToPlay;
//- (NSInteger)getNextSongIDToPlay;
- (void)storeWithName:(NSString *)theName;
- (NSUInteger)songsInPlaylist;
- (id)songIDAtIndex:(NSUInteger)index;
//- (NSNumber *)songIDAtIndex:(NSUInteger)index;
@end


// Delegate method declarations.
@protocol TGPlaylistDelegate <NSObject>

- (NSDictionary *)songDataForSongID:(id)songID;
//- (NSDictionary *)songDataForSongID:(NSInteger)songID;
//- (NSURL *)songURLForSongID:(NSInteger)songID;
//- (NSInteger)songDurationForSongID:(NSInteger)songID;

@end