//
//  NSMutableArray+QueueAdditions.h
//  reDiscover
//
//  Created by Teo on 08/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end
