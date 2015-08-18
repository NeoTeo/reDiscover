//
//  TGPlaylistViewController.m
//  Proto3
//
//  Created by Teo Sartori on 01/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGPlaylistViewController.h"
#import "TGPlaylistCellView.h"
#import "TGPlaylist.h"
#import "TGSongPool.h"

@interface TGPlaylistViewController () <TGPlaylistDelegate>
@end

@implementation TGPlaylistViewController

-(void)awakeFromNib {
    if (playlist == NULL) {
        playlist = [[TGPlaylist alloc] init];
        [playlist setDelegate:self];
        
        // Set this controller as the playlist table view's delegate and data source.
        [_playlistTableView setDelegate:self];
        [_playlistTableView setDataSource:self];
       
    }
}

-(void)addSongToPlaylist:(id<SongIDProtocol>)aSongID {
    [playlist addSong:aSongID atIndex:0];
    [_playlistTableView reloadData];
}


-(void)removeSongFromPlaylist:(id)aSong {
    [playlist removeSong:aSong];
    [_playlistTableView reloadData];
}

- (id)getNextSongIDToPlay {
    return [playlist getNextSongIDToPlay];
}

- (void)storePlaylistWithName:(NSString *)theName {
    [playlist storeWithName:theName];
}

// TGPlaylistDelegate method
- (NSDictionary *)songDataForSongID:(id<SongIDProtocol>)songID {
    
    // Get a mutable copy so we can add a few bits of data.
    NSMutableDictionary *songData = [[_songPoolAPI songDataForSongID:songID] mutableCopy];
    
    // Get the song duration and floor it before adding it to the playlist data (it doesn't really use it)
    double durationDoubleSecs =[[_songPoolAPI songDurationForSongID:songID] doubleValue];
    
    [songData addEntriesFromDictionary:@{@"Duration": [NSNumber numberWithInteger:durationDoubleSecs],
                                         @"SongURL": [_songPoolAPI songURLForSongID:songID],
                                         }];
    return songData;
}

// NSTableViewDataSource delegate methods
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [playlist songsInPlaylist];
}


- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    
    // Get an existing cell with the MyView identifier if it exists
    TGPlaylistCellView *resultCell = [tableView makeViewWithIdentifier:@"SongCell" owner:self];
    
    NSDictionary *songData = [_songPoolAPI songDataForSongID:[playlist songIDAtIndex:row]];
    
    // Construct the string for the playlist entry.
//    resultCell.layer.backgroundColor = (__bridge CGColorRef)([NSColor whiteColor]);
    resultCell.TitleLabel.stringValue = [songData valueForKey:@"Title"];
    resultCell.AlbumLabel.stringValue = [songData valueForKey:@"Album"];
    resultCell.ArtistLabel.stringValue = [songData valueForKey:@"Artist"];
    
    return resultCell;
}

// NSTableViewDelegate methods


-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Find out what row was selected.
    NSInteger selectedRow = [_playlistTableView selectedRow];
   
    // Set it if it is a valid position.
    if (selectedRow >=0) {
        [playlist setPosInPlaylist:selectedRow];
        id<SongIDProtocol> newSongID = [playlist songIDAtIndex:selectedRow];
//        [_songPoolAPI requestSongPlayback:newSongID withStartTimeInSeconds:[NSNumber numberWithFloat:0] makeSweetSpot:NO];
        [_songPoolAPI requestSongPlayback:newSongID withStartTimeInSeconds:nil];
    }

    [_playlistTableView deselectRow:selectedRow];
    // Make the main view controller the first responder.
    [[[self view] window] makeFirstResponder:(NSResponder*)_delegate];
}

@end
