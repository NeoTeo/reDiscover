//
//  TGStack.m
//  reDiscover
//
//  Created by teo on 16/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TGStack.h"

@implementation TGStack : NSObject 

- (id)init {
    if (self = [super init]) {
        _maxSize = 64;
        _items = [[NSMutableArray alloc] initWithCapacity:_maxSize];
    }
    return self;
}

- (id)initWithSize:(NSInteger)size {
    if (self = [super init]) {
        _maxSize = size;
        _items = [[NSMutableArray alloc] initWithCapacity:_maxSize];
    }
    return self;
}

- (void)setSize:(NSInteger)size {
    if (size > 0) {
        _maxSize = size;
    }
}

- (void)push:(id)anObject {
    if (_items.count == _maxSize) {
        [_items removeObjectAtIndex:0];
    }
    [_items addObject:anObject];
}

- (id)pop {
    if (_items.count > 0) {
        return [_items lastObject];
    }
    return nil;
}

@end