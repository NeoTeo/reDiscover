//
//  NSMutableArray+QueueAdditions.m
//  reDiscover
//
//  Created by Teo on 08/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

/** Queues are first-in-first-out, so we remove objects from the head */
-(id) dequeue {
    // Set aside a reference to the object to pass back
    id queueObject = nil;
    
    // Do we have any items?
    if ([self lastObject]) {
        // Pick out the first one
        queueObject = [self objectAtIndex: 0];

        // Remove it from the queue
        [self removeObjectAtIndex: 0];
    }
    
    // Pass back the dequeued object, if any
    return queueObject;
}


/** Add to the tail of the queue (no one likes it when people cut in line!) */
- (void) enqueue:(id)anObject {
    [self addObject:anObject];
    //this method automatically adds to the end of the array
}
@end
