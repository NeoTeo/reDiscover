//
//  TGTest.h
//  reDiscover
//
//  Created by Teo on 08/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TGTest : NSObject

@property (nonatomic, copy) void (^completionHandler)(NSMutableSet*);

- (instancetype)initWithHandler:(void (^)(NSMutableSet*))completionHandler;

- (void)notificationMethod:(NSNotification*)notification;
@end
