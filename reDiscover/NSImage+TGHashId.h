//
//  NSImage+TGHashId.h
//  reDiscover
//
//  Created by Teo on 28/10/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (TGHashId)

@property (nonatomic, strong) NSString* hashId;

- (void)hashIdWithHandler:(void (^)(NSString *))hashHandler;

@end
