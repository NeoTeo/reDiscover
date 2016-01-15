//
//  TGIdleTimer.h
//  Proto3
//
//  Created by Teo Sartori on 19/10/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGIdleTimer : NSObject

@property NSTimer *theIdleTimer;

- (void)startIdleTimer;
- (void)idleTimeBegins:(NSTimer *)theTimer;
- (void)idleTimeEnds;

@end
