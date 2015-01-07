//
//  TGTest.m
//  reDiscover
//
//  Created by Teo on 08/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import "TGTest.h"

@implementation TGTest

- (instancetype)initWithHandler:(void (^)(NSMutableSet*))completionHandler {
    self = [super init];
    if (self) {
        _completionHandler = completionHandler;
    }
    return self;
}

- (void)notificationMethod:(NSNotification*)notification {
    if (_completionHandler != nil) {
        NSMutableSet* theSet = (NSMutableSet*)notification.object;
        _completionHandler(theSet);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
