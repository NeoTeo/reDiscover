//
//  TGViewController.m
//  Proto3
//
//  Created by Teo Sartori on 13/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGIdleTimer.h"
#import "TGMainViewController.h"
#import "TGGridCell.h"
#import "TGSongGridViewController.h"
//#import "TGDropView.h"
#import "TGSongPool.h"
#import "TGPlaylistViewController.h"
#import "TGSongInfoViewController.h"
#import "TGSongTimelineViewController.h"
#import "TGTimelineTransformer.h"


// Magic numbers
#define kNewWindowWidth       800
#define kNewWindowHeight      800

@implementation songPositionClass

- (double)songTimePos {
    NSLog(@"songtimepos %f",songTimePos);
    return songTimePos;
}

- (void)setSongTimePos:(double)newPos {
    NSLog(@"set songtimepos %f",newPos);
    songTimePos = newPos;
}
@end

@interface TGMainViewController () <TGSongPoolDelegate, TGSongUIViewControllerDelegate, NSSplitViewDelegate,TGSongGridViewControllerDelegate>

@end

// Main coordinating controller.
@implementation TGMainViewController

-(void)viewWillAppear {
    NSLog(@"Appearing");
    NSAssert(_theURL != nil, @"There is no URL to load from.");
    [self setSongPool:[[TGSongPool alloc] init]];
    [_currentSongPool loadFromURL:_theURL];
}


-(void)awakeFromNib{
    
    // The idle timer produces system wide notifications of entering and exiting idle time.
    _idleTimer = [[TGIdleTimer alloc] init];
    
       // Insert code here to initialize your application
    infoLabel = @"infoView";
    playlistLabel = @"playlistView";
    
   // register the timeline transformer.
    id transformer = [[TGTimelineTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"TimelineTransformer"];
    
}


- (id)initWithFrame:(NSRect)theFrame {
    self = [super init];
    if (self) {
       // init stuff here
    }
    
    return self;
}

- (void)layOutMainView {
    
    NSView *mainView = [self view];
    
    // The main view consists of a three-part split view.
    // It starts off with both the middle song view and the right-hand info panel visible.
    NSSplitView *theSplitView = [[NSSplitView alloc] initWithFrame:mainView.frame];
    
    [mainView addSubview:theSplitView];
    
    [theSplitView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [theSplitView setVertical:YES];
    [theSplitView setDividerStyle:NSSplitViewDividerStyleThin];
//    [theSplitView setDividerStyle:NSSplitViewDividerStylePaneSplitter];
    [theSplitView setDelegate:self];
    
    _songGridController = [[TGSongGridViewController alloc] initWithNibName:@"TGSongGridView" bundle:nil];
    _playlistController = [[TGPlaylistViewController alloc] initWithNibName:@"TGPlaylistView" bundle:nil];
    _songInfoController = [[TGSongInfoViewController alloc] initWithNibName:@"TGSongInfoView" bundle:nil];
    
   
    [_playlistController setDelegate:_currentSongPool];
    [_playlistController setMainController:self];
    
    
    // Add the views to the splitview.
    [theSplitView addSubview:[_playlistController view]];
    [theSplitView addSubview:[_songGridController view]];
    [theSplitView addSubview:[_songInfoController view]];

    // Add constraints to the split view.
    [self addConstraintsTo:theSplitView];
    
    [theSplitView setHoldingPriority:498 forSubviewAtIndex:0];
    [theSplitView setHoldingPriority:499 forSubviewAtIndex:1];
    [theSplitView setHoldingPriority:498 forSubviewAtIndex:2];

    // Make sure the splitview's subviews are resized according to the newly added constraints.
    [theSplitView adjustSubviews];
}


- (void)addConstraintsTo:(NSSplitView *)theSplitView {
    
    NSView *mainView = [self view];
    NSView *songView = [_songGridController view];
    
    NSDictionary *viewDictionary = @{ @"mainView":mainView,
                                      @"splitView":theSplitView,
                                      @"playlistView":[_playlistController view],
                                      @"songView":songView,
                                      @"infoView":[_songInfoController view]};
    
    // First we set the content view constraints.
    [mainView addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"H:|[splitView]|"
                                  options:0
                                  metrics:nil
                                  views:viewDictionary]];

    [mainView addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[splitView]|"
                                    options:0
                                    metrics:nil
                                    views:viewDictionary]];

    
    // Needed to keep the shape of the song view.
    [songView addConstraints:[NSLayoutConstraint
                              constraintsWithVisualFormat:@"H:[songView(600@750)]"
                              options:0
                              metrics:nil
                              views:viewDictionary]];
    
    
    [theSplitView addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|-(0)-[playlistView]"
                                  options:0
                                  metrics:nil
                                  views:viewDictionary]];

    [theSplitView addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|-(0)-[songView]"
                                  options:0
                                  metrics:nil
                                  views:viewDictionary]];
    
    [theSplitView addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|-(0)-[infoView]"
                                  options:0
                                  metrics:nil
                                  views:viewDictionary]];

}


- (void)setSongPool:(TGSongPool *)theSongPool {
    
    [self setCurrentSongPool:theSongPool];
    [_currentSongPool setDelegate:self];
    
    [self layOutMainView];
    
    if (_myObjectController == nil) {
        _myObjectController = [[NSObjectController alloc] initWithContent:_currentSongPool];
    } else {
        [_myObjectController setContent:_currentSongPool];
    }
    // Bind the timeline value transformer's maxDuration with the song pool's currentSongDuration.
    NSValueTransformer * transformer = [NSValueTransformer valueTransformerForName:@"TimelineTransformer"];
    [transformer bind:@"maxDuration" toObject:_currentSongPool withKeyPath:@"currentSongDuration" options:nil];
   
    // Bind the playlist controller's progress indicator value parameter with the song pool's playheadPos via the timeline value transformer.
    [[_playlistController playlistProgress] bind:@"value" toObject:_currentSongPool withKeyPath:@"playheadPos" options:@{NSValueTransformerNameBindingOption: @"TimelineTransformer"}];
    
    // Bind the timeline nsslider to observe the requestedPlayheadPosition of the currently playing song via the objectcontroller using the TimelineTransformer.
    [_songGridController.songTimelineController.timelineBar bind:@"value"
                                                        toObject:_myObjectController
                                                     withKeyPath:@"selection.requestedPlayheadPosition"
                                                         options:@{NSValueTransformerNameBindingOption: @"TimelineTransformer"}];

    // Bind the selection's (the songpool) playheadPos with the timeline bar cell's currentPlayheadPositionInPercent so we can animate the bar.
    [_songGridController.songTimelineController.timelineBar.cell bind:@"currentPlayheadPositionInPercent"
                                                             toObject:_myObjectController withKeyPath:@"selection.playheadPos"
                                                              options:@{NSValueTransformerNameBindingOption: @"TimelineTransformer"}];
    
    // Get the sizes of the playlist and info views before they are resized by the layoutSubtree call.
    NSSplitView *theSplitView = [[[self view] subviews] objectAtIndex:0];
    playlistExpandedWidth = NSWidth([theSplitView.subviews[0] frame]);
    infoExpandedWidth = NSWidth([theSplitView.subviews[2] frame]);
    
    // This ensures everything is resized according to the various constraints from the main view and down.
    [[self view] layoutSubtreeIfNeeded];
    
    // Make sure the grid controller has a way of communicating back to the main controller.
    [_songGridController setDelegate:self];
    
    // Start the view off with both panels collapsed.
    [self togglePlaylist:nil];
    [self toggleInfo:nil];
}


- (id)lastRequestedSongID {
    return [_currentSongPool lastRequestedSongID];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"Yep, key down in the view controller.");
    id lastRequestedSongID = [_currentSongPool lastRequestedSongID];
    
    NSString *chars = [theEvent characters];
    if ([chars isEqualToString:@"["]) {
        [self togglePlaylist:nil];
    } else if ([chars isEqualToString:@"]"]) {
        [self toggleInfo:nil];
    } else if ([chars isEqualToString:@"\\"]) {
//        TGSong *theSong = [_currentSongPool songForID:[_currentSongPool lastRequestedSongID]];
//        [_currentSongPool sweetSpotFromServerForSong:theSong];
        NSLog(@"got it");
    } else if ([chars isEqualToString:@"g"]) {
        NSLog(@"song added to playlist.");
        [self songUIPlusButtonWasPressed];
//        [self togglePlaylistPanel];
    } else if ([chars isEqualToString:@"s"]) {
        
        NSLog(@"Save!");
        [_currentSongPool storeSongData];
    } else if ([chars isEqualToString:@" "]){
        
        NSLog(@"space!");
        [self songUISweetSpotButtonWasPressed];
    } else if ([chars isEqualToString:@"l"]){
        
        NSLog(@"list sweetspots");
//        TGSong *actionSong = [_currentSongPool songForID:lastRequestedSongID];
        NSLog(@"The UUID is %@",[_currentSongPool UUIDStringForSongID:lastRequestedSongID]);
        
        NSLog(@"The sweetspots are %@",[_currentSongPool sweetSpotsForSongID:lastRequestedSongID]);
    } else if ([chars isEqualToString:@"p"]){
        
        NSLog(@"Playlist generation.");
        [_playlistController storePlaylistWithName:@"ProjectXPlaylist"];
    } else if ([chars isEqualToString:@"t"]){
        NSLog(@"testicle");
        [_songGridController runTest];
//        [_currentSongPool findUUIDOfSongWithURL:[_currentSongPool URLForSongID:lastRequestedSongID]];
    } else {
        
        NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:chars];
        
        if ([alphaNums isSupersetOfSet:inStringSet]) {
            NSLog(@"key is number %@",chars);
            [_songGridController animateMatrixZoom:[chars integerValue]];
        }
    }
}


- (void)songUIInfoButtonWasPressed {
    
}


- (void)songUIGearButtonWasPressed {
    
}


- (void)songUIPlusButtonWasPressed {
    [_playlistController addSongToPlaylist:[_currentSongPool lastRequestedSongID]];
}


- (void)songUISweetSpotButtonWasPressed {
    [_currentSongPool offsetSweetSpotForSongID:[_currentSongPool lastRequestedSongID] bySeconds:-0.25];
}


- (void)shrinkWindow {
    NSRect windowFrame = [self view].window.frame;
    windowFrame.size.width = 600;
    [[self view].window setFrame:windowFrame display:YES animate:NO];
}

- (void)togglePlaylist:(NSButton *)sender {

    NSRect windowFrame = [self view].window.frame;
    NSView * theView = [self view];
    NSAssert([[[theView subviews] objectAtIndex:0] isKindOfClass:[NSSplitView class]], @"Did not find the expected split view");
    NSSplitView *theSplitView = [[theView subviews] objectAtIndex:0];
    NSView *playlistSubview = theSplitView.subviews[0];
    
    BOOL isCollapsed = [theSplitView isSubviewCollapsed:playlistSubview];
    
    NSLayoutPriority priorityPlaylistSubview = [theSplitView holdingPriorityForSubviewAtIndex:0];
    NSLayoutPriority prioritySongGridSubview = [theSplitView holdingPriorityForSubviewAtIndex:1];
    
    [theSplitView setHoldingPriority:1 forSubviewAtIndex:0];
    [theSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:1];
    
    CGFloat dividerThickness = [theSplitView dividerThickness];
    
    if (isCollapsed) {
        // First uncollapse the view by setting the divider position to the its thickness.
        [theSplitView setPosition:1 ofDividerAtIndex:0];
        
        // Then make room for it to get pushed by the width constraint of the middle view.
        windowFrame.size.width += dividerThickness;
        windowFrame.origin.x -= dividerThickness;
        [[self view].window setFrame:windowFrame display:YES animate:NO];

        // ...then grow the window and let the playlist view expand into the space as per splitview holding priorities.
        windowFrame.size.width += playlistExpandedWidth;
        windowFrame.origin.x -= playlistExpandedWidth;
        [[self view].window setFrame:windowFrame display:YES animate:YES];
        
    } else {
        // First shrink the window by the width of the playlist panel.
        windowFrame.size.width -= NSWidth(playlistSubview.frame);
        windowFrame.origin.x += NSWidth(playlistSubview.frame);
        [[self view].window setFrame:windowFrame display:YES animate:YES];

        // ...then collapse the adjoining view by setting the divider to the view's minimum possible position,
        // which will necessarily be past half its width and in turn will trigger the view's collapse (as long as splitview:canCollapseSubview returns YES).
        [theSplitView setPosition:[theSplitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];

        // and reduce frame the last bit of the thickness of the divider.
        windowFrame.size.width -= dividerThickness;
        windowFrame.origin.x += dividerThickness;
        [[self view].window setFrame:windowFrame display:YES animate:NO];
    }

    // Restore the holding priorites to what they were before the toggle.
    [theSplitView setHoldingPriority:priorityPlaylistSubview forSubviewAtIndex:0];
    [theSplitView setHoldingPriority:prioritySongGridSubview forSubviewAtIndex:1];
    
}


- (void)toggleInfo:(NSButton *)sender {
    
    NSRect windowFrame = [self view].window.frame;
    NSView * theView = [self view];
    NSSplitView *theSplitView = [[theView subviews] objectAtIndex:0] ;
    
    NSAssert([[theSplitView subviews] count] == 3, @"The splitview does not have the expected number of subviews.");
    
    NSView *infoSubview = theSplitView.subviews[2];
    [infoSubview setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    BOOL isCollapsed = [theSplitView isSubviewCollapsed:infoSubview];
    
    NSLayoutPriority priorityPlaylistSubview = [theSplitView holdingPriorityForSubviewAtIndex:0];
    NSLayoutPriority prioritySongGridSubview = [theSplitView holdingPriorityForSubviewAtIndex:1];
    NSLayoutPriority priorityInfoSubview = [theSplitView holdingPriorityForSubviewAtIndex:2];
    
    // Temporarily weaken the holding priority for the info view and strengthen the song view.
    [theSplitView setHoldingPriority:1 forSubviewAtIndex:2];
    [theSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:1];
    [theSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:0];
    
    CGFloat dividerThickness = [theSplitView dividerThickness];
    
    if (isCollapsed) {
        // First uncollapse the view...
        [theSplitView setPosition:NSWidth(windowFrame)-dividerThickness ofDividerAtIndex:1];
        windowFrame.size.width += dividerThickness;
        
        [[self view].window setFrame:windowFrame display:YES animate:NO];

        // ...then grow the window.
        CGFloat expandedWidth = infoExpandedWidth;
        windowFrame.size.width += expandedWidth;
        [[self view].window setFrame:windowFrame display:YES animate:YES];
        
    } else {
        // First shrink the window by the width of the info panel.
        windowFrame.size.width -= NSWidth(infoSubview.frame);

        [[self view].window setFrame:windowFrame display:YES animate:YES];
        
        // ...then collapse the view.
        [theSplitView setPosition:NSWidth(windowFrame) ofDividerAtIndex:1];
        windowFrame.size.width -= dividerThickness;
        
        [[self view].window setFrame:windowFrame display:YES animate:NO];
    }
    
    [theSplitView setHoldingPriority:priorityPlaylistSubview forSubviewAtIndex:0];
    [theSplitView setHoldingPriority:prioritySongGridSubview forSubviewAtIndex:1];
    [theSplitView setHoldingPriority:priorityInfoSubview forSubviewAtIndex:2];
    
}


// This disables dragging of dividers in such a way that not even the drag cursors appear.
-(NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    return NSZeroRect;
}

-(BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return [[subview identifier] isEqualToString:playlistLabel] || [[subview identifier] isEqualToString:infoLabel];
}

-(BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

#pragma mark -
#pragma mark SongPoolDelegate methods
// SongPoolDelegate methods

// TGSongPoolDelegate methods
- (void)songPoolDidLoadAllURLs:(NSUInteger)numberOfURLs {
    NSLog(@"songPooFinished with %ld songs",(long)numberOfURLs);
    //[_songGridController initSongGrid:numberOfURLs];
}

// Called by the song pool for every song whose metadata has fully loaded.
//- (void)songPoolDidLoadDataForSongID:(NSUInteger)songID {
- (void)songPoolDidLoadDataForSongID:(id)songID {
    // Not really doing anything so return.
    return;
    NSDictionary *songData = [_currentSongPool songDataForSongID:songID];
    // Get the song's genre.
    NSString * songGenre = [songData objectForKey:@"Genre"];
//    NSString * songGenre = [_currentSongPool getSongGenreStringForSongID:songID];

    if (songGenre == NULL)
        return;
        
    // Look up the colour that the genre is mapped to.
    NSString *genreCols = [_genreToColourDictionary objectForKey:songGenre];
        
    if (genreCols == NULL)
        return;
    
//    unsigned int colourCode;
//    NSScanner *scanner = [NSScanner scannerWithString:genreCols];
//
//    // Extract the colour code in from hex into an unsigned integer.
//    [scanner setScanLocation:0];
//    [scanner scanHexInt:&colourCode];
    
    // Shift it down, mask lower two bytes and make into a float value between 0 and 1.
//    CGFloat redComponent = ((colourCode >> 16) & 0xFF) / 255.0;
//    CGFloat greenComponent = ((colourCode >> 8) & 0xFF) / 255.0;
//    CGFloat blueComponent = (colourCode & 0xFF) / 255.0;
//    CGFloat alphaComponent = 0.25;
    
//
//    
//    [existingCell setTintColour:[NSColor colorWithDeviceRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent]];
}


// Called by the song pool for every song what with an URL.
// This does not guarantee that any of its data is loaded yet, in fact it's very unlikely.
- (void)songPoolDidLoadSongURLWithID:(id)songID {
    
    // We have to make sure we execute on the main thread since much of the AppKit stuff isn't thread safe.
    // addMatrixCell2 has many classes that need to run on the main thread or are otherwise thread-unsafe;
    // (see the "Thread Safety Summary" chapter of Apple's "Threading Programming Guide", in particular on NSCell, NSResponder, NSImage and NSView).
    NSAssert(songID != nil, @"song pool passing us song id nil.");
    if ([NSThread isMainThread] == NO) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            
            // Add a cell for the song.
            [_songGridController addMatrixCell2:songID];

        }];
    }
}


- (void)songPoolDidStartPlayingSong:(id)songID {

    // Request metadata for the song and pass in the block to be called when done.
    [_currentSongPool requestEmbeddedMetadataForSongID:songID withHandler:^(NSDictionary* theData){
        // Tell the info panel to change to display the new song's data.
        [_songInfoController setSong:theData];
    }];
    
    // Let the timelinecontroller know that we've changed song.
    // (would a song change be better signalled as a global notification?)
    [_songGridController.songTimelineController setCurrentSongID:songID fromSongPool:_currentSongPool];
    
//    NSLog(@"songPoolDidStartPlayingSong");
    // Don't wait for a result. Set to the "fetching artwork..." whilst waiting.
    NSImage* fetchingImage = [NSImage imageNamed:@"fetchingArt"];
    [_songGridController setCoverImage:fetchingImage forSongWithID:songID];
    [_songInfoController setSongCoverImage:fetchingImage];
//#pragma warning disabled call to requestImageForSongID
//    return;
    // Then async'ly request an album image for the song and pass it a block callback.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_currentSongPool requestImageForSongID:songID withHandler:^(NSImage *tmpImage) {
            
            // none of the attempts returned an image so just show the no cover cover.
            if (tmpImage == nil) {
                tmpImage = [NSImage imageNamed:@"noCover"];
                //NSBeep();
            }
            
            // Set the scroll view controller cover image.
            [_songGridController setCoverImage:tmpImage forSongWithID:songID];
            
            // Only update the info window for the currently playing song.
            if ([songID isEqualTo:[_currentSongPool currentlyPlayingSongID]])
            {
                [_songInfoController setSongCoverImage:tmpImage];
            }
            
            
        }];
    });
    
}

- (void)songPoolDidFinishPlayingSong:(id)songID {
    // If the currently selected song is the same as the one that just finished, see if there is more on the playlist.
    NSLog(@"song grid controller. Song %@ finished playing.",(NSString*)songID);
    if (songID == [_currentSongPool lastRequestedSongID]) {
        id newSongID = [_playlistController getNextSongIDToPlay];
        if (newSongID == nil) {
            NSLog(@"No more songs in playlist.");
            return;
        }
        
        [_currentSongPool requestSongPlayback:newSongID withStartTimeInSeconds:0];
    }
}
//- (void)songPoolDidFinishPlayingSong:(NSUInteger)songID {
//    // If the currently selected song is the same as the one that just finished, see if there is more on the playlist.
//    NSLog(@"song grid controller. Song %lu finished playing.",(unsigned long)songID);
//    if (songID == [_currentSongPool lastRequestedSongID]) {
//        NSInteger newSongID = [_playlistController getNextSongIDToPlay];
//        if (newSongID != -1) {
//            [_currentSongPool requestSongPlayback:newSongID withStartTimeInSeconds:0];
//        } else
//            NSLog(@"No more songs in playlist.");
//    }
//}

// TGSongGridViewControllerDelegate methods
- (void)requestSongArrayPreload:(NSArray *)theArray {
    
    [_currentSongPool preloadSongArray:theArray];
}


- (void)userSelectedSweetSpot:(NSUInteger)ssIndex {
//    TGSong * theSong = [_currentSongPool currentlyPlayingSong];
//    [_currentSongPool setRequestedPlayheadPosition:[[theSong songSweetSpots] objectAtIndex:ssIndex]];
    [_currentSongPool setRequestedPlayheadPosition:[[_currentSongPool sweetSpotsForSongID:[_currentSongPool currentlyPlayingSongID]] objectAtIndex:ssIndex]];
}


- (void)userSelectedSongID:(id)songID {
    [_currentSongPool requestSongPlayback:songID withStartTimeInSeconds:[NSNumber numberWithInt:-1]];
    
    //TEO make sure this works as intended. Moved from songPoolDidLoadSongURLWithID
            // Now that the song has been added as a cell we (async'ly) request the song's metadata which might affect the look of the cell.
            // Successful loading is signaled through the songPoolDidLoadDataForSongID:
            // It would be nice to do this as JIT or during idle time, but we need to know the genre straight away if we are to colorize the cells.
    // TEO TSD
//            [_currentSongPool requestEmbeddedMetadataForSong:songID];
    
    // reset the idle timer
    [_idleTimer startIdleTimer];
}

@end
