//
//  TGPlaylist.m
//  Proto3
//
//  Created by Teo Sartori on 01/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGPlaylist.h"

@implementation TGPlaylist

- (id)init {
    self = [super init];
    if (self) {
        songList = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (NSUInteger)songsInPlaylist {
    return [songList count];
}

- (NSNumber *)songIDAtIndex:(NSUInteger)index {
    return [songList objectAtIndex:index];
}

- (void)addSong:(NSInteger)aSongID atIndex:(NSUInteger)index {
    [songList insertObject:[NSNumber numberWithInteger:aSongID] atIndex:index];
    NSLog(@"Added song %ld to playlist which is now %@",(long)aSongID ,songList);
}

- (void)removeSongAtIndex:(NSUInteger)index {
    [songList removeObjectAtIndex:index];
}

- (void)removeSong:(NSInteger)aSong {
    [songList removeObject:[NSNumber numberWithInteger:aSong]];
}

- (NSInteger)getNextSongIDToPlay {
    NSInteger sID = -1;
    NSUInteger songCount = [songList count];
    
    if (songCount) {
        if (_posInPlaylist >= songCount)
            _posInPlaylist = 0;
        
        NSNumber *songID = [songList objectAtIndex:_posInPlaylist++];
        if (songID != nil) {
            sID = [songID integerValue];
        }
    }
    
    return sID;
}

- (void)storeWithName:(NSString *)theName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@/%@.m3u",documentsDirectory,theName];
    NSLog(@"The playlist file url is :\n%@",fileName);
    NSString *m3uHeader = @"#EXTM3U\n";
    NSString *m3uExtInf = @"#EXTINF:";
    
    // Start the content off with the header.
    NSString *content = m3uHeader;
    // TEO: Do some error checking here.
    for (NSNumber *songID in songList) {
        NSInteger sID = [songID integerValue];
        NSDictionary *songData = [_delegate songDataForSongID:sID];
        NSInteger sDuration = [[songData valueForKey:@"Duration"] integerValue];
        NSURL *songURL = [songData valueForKey:@"SongURL"];
//        NSInteger sDuration = [_delegate songDurationForSongID:sID];
//        NSURL *songURL = [_delegate songURLForSongID:sID];
        NSString *info = [NSString stringWithFormat:@"%@%ld,%@ - %@\n",m3uExtInf,sDuration,[songData valueForKey:@"Artist"],[songData valueForKey:@"Title"]];
        NSString *url = [songURL absoluteString];
        
        // Append the new song to the existing content.
        content = [NSString stringWithFormat:@"%@%@%@\n",content,info,url];
    }
    NSLog(@"The playlist content is:\n %@",content);
    
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];

}

@end
