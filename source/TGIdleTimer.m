//
//  TGIdleTimer.m
//  Proto3
//
//  Created by Teo Sartori on 19/10/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGIdleTimer.h"

@implementation TGIdleTimer

// This method will start off the idle timer countdown, interrupting any previously set timer.
// The method idleTimeBegins method is called on timer firing.
- (void)startIdleTimer {
    
    if (_theIdleTimer != nil) {
        [_theIdleTimer invalidate];
    }
    
    // If we were previously in an idle state, make sure it is signalled as ending.
    [self idleTimeEnds];
    
    // Instantiate a timer that fires after 30 seconds and calls the method idleTimeBegins.
    _theIdleTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                  target:self
                                                selector:@selector(idleTimeBegins:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)idleTimeBegins:(NSTimer *)theTimer {
    
    // Turn off the idle timer
    [_theIdleTimer invalidate];
    
    // Notify observers of idle time beginning.
    NSNotification *myNotification = [NSNotification notificationWithName:@"TGIdleTimeBegins" object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:myNotification postingStyle:NSPostNow];
}

- (void)idleTimeEnds {
    // Notify observers of idle time ending.
    NSNotification *myNotification = [NSNotification notificationWithName:@"TGIdleTimeEnds" object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:myNotification postingStyle:NSPostNow];

}

@end
