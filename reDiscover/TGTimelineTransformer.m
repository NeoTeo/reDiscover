//
//  TGTimelineTransformer.m
//  Proto3
//
//  Created by Teo Sartori on 12/11/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGTimelineTransformer.h"

@implementation TGTimelineTransformer

+ (Class)transformedValueClass {
    return [NSNumber self];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

// Turns the song position value into a percentage.
- (id)transformedValue:(id)value {
    NSNumber *numberValue = (NSNumber *)value;
    double unit = 100.0/_maxDuration;
    return [NSNumber numberWithDouble:unit*[numberValue doubleValue]];
}

// Turns a percentage into a song position value.
- (id)reverseTransformedValue:(id)value {
    NSNumber *numberValue = (NSNumber *)value;
    NSNumber *reverseNumber = [NSNumber numberWithDouble:_maxDuration/100.0*[numberValue doubleValue]];
//    NSLog(@"%@ reverse transform from %@ to %@",self,numberValue,reverseNumber);
    return reverseNumber;
}

@end
