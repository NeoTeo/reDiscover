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

@interface TGPlaylistViewController () <TGPlaylistDelegate>
@end

@implementation TGPlaylistViewController

//@synthesize delegate;

-(void)awakeFromNib {
    if (playlist == NULL) {
        playlist = [[TGPlaylist alloc] init];
        [playlist setDelegate:self];
        
        // Set this controller as the playlist table view's delegate and data source.
        [_playlistTableView setDelegate:self];
        [_playlistTableView setDataSource:self];
       
    }
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//    self = [super init];
//    if (self) {
//       playlist = [[TGPlaylist alloc] init];
//    }
//    return self;
//}
//

//- (id)initWithDelegate:(id)delegate {
//    self = [super initWithNibName:@"TGPlaylistView" bundle:nil];
//    if (self) {
//        NSLog(@"playlist view controller init");
//        playlist = [[TGPlaylist alloc] init];
//        _delegate = delegate;
//        // Set the playlist's delegate as well.
//        [playlist setDelegate:delegate];
//    }
//    return self;
//}


/*
 */

//- (void)setDelegate:(id)newDelegate {
//    delegate = newDelegate;
//    playlist = [[TGPlaylist alloc] init];
//    [playlist setDelegate:newDelegate];
//    [_playlistTableView setDelegate:self];
//    [_playlistTableView setDataSource:self];
//}
//
//- (id)delegate {
//    return delegate;
//}

//- (void)setUpPlaylistView {
//    NSRect mainFrame = NSMakeRect(0, 0, 170, 600);
//    NSView *playlistView = [[NSView alloc] initWithFrame:mainFrame];
//
//    [self setView:playlistView];
//}

-(void)addSongToPlaylist:(NSInteger)aSongID {
    [playlist addSong:aSongID atIndex:0];
    [_playlistTableView reloadData];
}


-(void)removeSongFromPlaylist:(NSInteger)aSong {
    [playlist removeSong:aSong];
    [_playlistTableView reloadData];
}

- (NSInteger)getNextSongIDToPlay {
    return [playlist getNextSongIDToPlay];
}

- (void)storePlaylistWithName:(NSString *)theName {
    [playlist storeWithName:theName];
}

// TGPlaylistDelegate method
- (NSDictionary *)songDataForSongID:(NSInteger)songID {
    
    NSMutableDictionary *songData = [[_delegate songDataForSongID:songID] mutableCopy];
   
    [songData addEntriesFromDictionary:@{@"Duration": [NSNumber numberWithInteger:[_delegate songDurationForSongID:songID]],
                                         @"SongURL": [_delegate songURLForSongID:songID],
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
    
    NSDictionary *songData = [_delegate songDataForSongID:[[playlist songIDAtIndex:row] integerValue]];
    
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
        NSInteger newSongID = [[playlist songIDAtIndex:selectedRow] integerValue];
        [_delegate requestSongPlayback:newSongID withStartTimeInSeconds:0];
    }

    [_playlistTableView deselectRow:selectedRow];
    // Make the main view controller the first responder.
    [[[self view] window] makeFirstResponder:_mainController];
}

@end
