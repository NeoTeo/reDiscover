//
//  TGSongInfoPanel.m
//  Proto3
//
//  Created by Teo Sartori on 12/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGSongInfoViewController.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>

@implementation TGSongInfoViewController

- (void)awakeFromNib {
    
    noCoverImage =[NSImage imageNamed:@"noCover"];
    [albumCover setImage:noCoverImage];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super init];
    if (self) {
    }
    
    return self;
}

- (void)setSong:(NSDictionary *)songDataDisplayStrings {

    if (songDataDisplayStrings != NULL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [titleLabel setStringValue:[songDataDisplayStrings objectForKey:@"Title"]];
            [artistLabel setStringValue:[songDataDisplayStrings objectForKey:@"Artist"]];
            [albumLabel setStringValue:[songDataDisplayStrings objectForKey:@"Album"]];
        });
        
//        NSLog(@"The genre? Why, %@",[songDataDisplayStrings objectForKey:@"Genre"]);
    }else
        NSLog(@"The songdatadisplaystrings was null.");

}

- (void)crossFadeToImage:(NSImage *)newCoverImage {
    if (albumCover.layer != nil) {
        
        NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
        
        NSImageView *newCoverImageView = [[NSImageView alloc] initWithFrame:[albumCover frame]];
        
        [newCoverImageView setWantsLayer:YES];
        [newCoverImageView setImage:newCoverImage];
        [newCoverImageView setAlphaValue:0];
        
        [[self view] addSubview:newCoverImageView];
        
        newCoverImageView.layer.opacity = 1;
        albumCover.layer.opacity = 0;
        
        albumCover = newCoverImageView;
    }
}


// This method sets the album cover that is passed in, for the displayed song.
- (void)setSongCoverImage:(NSImage *)coverImage {
    
    // Since this might get called by a separate thread and Core Anim doesn't like working on non-main treads, we need to ensure that
    // setImage is called on the main thread.
    if (coverImage != nil) {
        [self performSelectorOnMainThread:@selector(crossFadeToImage:) withObject:coverImage waitUntilDone:NO];
    } else
    {
        [self performSelectorOnMainThread:@selector(crossFadeToImage:) withObject:noCoverImage waitUntilDone:NO];
    }
}

@end
