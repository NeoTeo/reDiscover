//
//  TGSongUIViewController.h
//  Proto3
//
//  Created by Teo Sartori on 05/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TGSongUIViewControllerDelegate;

@interface TGSongUIViewController : NSViewController
{
    NSButton *sweetSpotButton;
    NSButton *plusButton;
    NSButton *infoButton;
    NSButton *gearButton;
    
    NSInteger cellSize;
}

@property id<TGSongUIViewControllerDelegate> delegate;

//-(void)setUIPosition:(NSPoint)pos;
- (void)setUIPosition:(NSPoint)pos withPopAnimation:(BOOL)animate;

@end

@protocol TGSongUIViewControllerDelegate <NSObject>

- (void)songUIPlusButtonWasPressed;
- (void)songUISweetSpotButtonWasPressed;
- (void)songUIInfoButtonWasPressed;
- (void)songUIGearButtonWasPressed;

@end