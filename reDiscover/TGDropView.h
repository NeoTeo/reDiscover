//
//  TGDropView.h
//  Proto3
//
//  Created by teo on 25/03/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "TGViewController.h"

@protocol TGDropViewDelegate;

@interface TGDropView : NSView
{
    IBOutlet NSImageView *dropArrowImageView;
}


@property id<TGDropViewDelegate> delegate;

@end

@protocol TGDropViewDelegate <NSObject>

- (void)dropViewDidReceiveURL:(NSURL *)theURL;

@end