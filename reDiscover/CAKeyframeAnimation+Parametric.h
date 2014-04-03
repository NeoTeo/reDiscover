//
//  CAKeyframeAnimation+Parametric.h
//  reDiscover
//
//  Created by Teo Sartori on 02/04/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


// A function passed to the animation that takes a time value between
//  0.0 and 1.0 (where 0.0 is the beginning of the animation
//  and 1.0 is the end) and returns a scale factor where 0.0
//  would produce the starting value and 1.0 would produce the
//  ending value
typedef double (^KeyframeParametricBlock)(double);

@interface CAKeyframeAnimation (Parametric)

+ (id)animationWithKeyPath:(NSString *)path
                  function:(KeyframeParametricBlock)block
                 fromValue:(double)fromValue
                   toValue:(double)toValue;

@end
