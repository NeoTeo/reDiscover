//
//  TGSongInfoPanel.h
//  Proto3
//
//  Created by Teo Sartori on 12/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//@protocol TGSongInfoPanelDelegate;
@class ScrollingTextView;

@interface TGSongInfoViewController : NSViewController
{
    NSView *labelsView;
    IBOutlet NSTextField *titleLabel;
    IBOutlet NSTextField *artistLabel;
    IBOutlet NSTextField *albumLabel;
    IBOutlet NSImageView *albumCover;
    NSImage *noCoverImage;
    
    IBOutlet ScrollingTextView *scrollTitleView;
}

@property NSNumber *flibble;

- (id)initWithFrame:(NSRect)frame;
- (void)setSong:(NSDictionary *)songDataDisplayStrings;
- (void)setSongCoverImage:(NSImage *)coverImage;
- (void)crossFadeToImage:(NSImage *)newCoverImage;

@end
