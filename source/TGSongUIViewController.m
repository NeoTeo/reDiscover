//
//  TGSongUIViewController.m
//  Proto3
//
//  Created by Teo Sartori on 05/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "TGSongUIViewController.h"

@interface TGSongUIViewController ()

@end

@implementation TGSongUIViewController

-(id)init {
    self = [super init];
    if (self) {
        cellSize = 150;
        CGRect frameRect = CGRectMake(0, 0, cellSize, cellSize);
        NSInteger buttonOffsetFromEdge = 11;
        NSInteger buttonWidth = 33;
        
        [self setView:[[NSView alloc] initWithFrame:frameRect]];
        sweetSpotButton = [[NSButton alloc] initWithFrame:NSMakeRect(frameRect.size.width-(buttonWidth+buttonOffsetFromEdge),
                                                                     frameRect.size.height-(buttonWidth+buttonOffsetFromEdge),
                                                                     buttonWidth,
                                                                     buttonWidth)];
        [sweetSpotButton setImage:[NSImage imageNamed:@"ssButton"]];
        [sweetSpotButton setBordered:NO];
        [sweetSpotButton setAction:@selector(sweetSpotButtonWasPressed:)];
        [sweetSpotButton setTarget:self];


        plusButton = [[NSButton alloc] initWithFrame:NSMakeRect(buttonOffsetFromEdge,
                                                                frameRect.size.height-(buttonWidth+buttonOffsetFromEdge),
                                                                buttonWidth,
                                                                buttonWidth)];
        [plusButton setImage:[NSImage imageNamed:@"plusButton"]];
        [plusButton setBordered:NO];
        [plusButton setAcceptsTouchEvents:YES];
        [plusButton setAction:@selector(plusButtonWasPressed:)];
        [plusButton setTarget:self];

        infoButton = [[NSButton alloc] initWithFrame:NSMakeRect(frameRect.size.width-(buttonWidth+buttonOffsetFromEdge),
                                                                buttonOffsetFromEdge,
                                                                buttonWidth,
                                                                buttonWidth)];
        [infoButton setImage:[NSImage imageNamed:@"infoButton"]];
        [infoButton setBordered:NO];
        [infoButton setAcceptsTouchEvents:YES];
        [infoButton setAction:@selector(infoButtonWasPressed:)];
        [infoButton setTarget:self];
        
        
        [plusButton setHidden:YES];
        [sweetSpotButton setHidden:YES];
        [infoButton setHidden:YES];

        // Finally add the button to the view.
        [[self view] addSubview:sweetSpotButton];
        [[self view] addSubview:plusButton];
        [[self view] addSubview:infoButton];
    }
    
    return self;
}

-(void)plusButtonWasPressed:(id)sender {
    if ([_delegate respondsToSelector:@selector(songUIPlusButtonWasPressed)]) {
        [_delegate songUIPlusButtonWasPressed];
    }
}

-(void)sweetSpotButtonWasPressed:(id)sender {
    if ([_delegate respondsToSelector:@selector(songUISweetSpotButtonWasPressed)]) {
        [_delegate songUISweetSpotButtonWasPressed];
    }
    NSLog(@"sweet!");
}

- (void)infoButtonWasPressed:(id)sender {
    NSLog(@"Shoot me some info!");
}

- (void)setUIPosition:(NSPoint)pos withPopAnimation:(BOOL)animate {
//    [plusButton setHidden:YES];
//    [sweetSpotButton setHidden:YES];
    [[self view] setFrame:CGRectMake(pos.x, pos.y, cellSize, cellSize)];
    
    if (animate) {
        [self bouncyPopAnimation:sweetSpotButton withDelay:[NSNumber numberWithFloat:1.0]];
        [self bouncyPopAnimation:plusButton withDelay:[NSNumber numberWithFloat:1.05]];
        [self bouncyPopAnimation:infoButton withDelay:[NSNumber numberWithFloat:1.1]];
    }
}

- (void)bouncyPopAnimation:(NSView *)theView withDelay:(NSNumber *)initialDelay {
    if (theView.layer != nil) {
        
        CGPoint center = CGPointMake(CGRectGetMidX(theView.frame), CGRectGetMidY(theView.frame));
        [theView.layer setPosition:center];
        [theView.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
        
        if (theView.isHidden) {
            theView.layer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0);
            [theView setHidden:NO];
        }
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = @[[NSNumber numberWithFloat:0.1],
                                  [NSNumber numberWithFloat:1.1],
                                  [NSNumber numberWithFloat:0.95],
                                  [NSNumber numberWithFloat:1.0]];
        bounceAnimation.beginTime = CACurrentMediaTime()+[initialDelay floatValue];
        bounceAnimation.duration = 0.20;
        // Persist the animation after finishing.
        bounceAnimation.fillMode = kCAFillModeForwards;
        bounceAnimation.removedOnCompletion = NO;

        [theView.layer addAnimation:bounceAnimation forKey:@"bounce"];
        
    }
}

@end
