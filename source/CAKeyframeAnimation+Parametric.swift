//
//  CAKeyframeAnimation+Parametric.swift
//  reDiscover
//
//  Created by Teo on 21/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

typealias KeyframeParametricBlock = (time: Double) -> Double

extension CAKeyframeAnimation {
    
    /// Directly translated from my objc version CAKeyframeAnimation+Parametric.m/h so
    /// check that if something doesn't work.
    
    class func animation(keyPath path: String, function block: KeyframeParametricBlock,
        fromValue fromVal: Double, toValue toVal: Double) -> AnyObject {
        
        /// Get a keyframe animation set up.
        let animation = CAKeyframeAnimation(keyPath: path)
            
        /// Break the time into steps. The more stes the smoother the anim.
        let steps    = 100
        var time     = 0.0
        let timeStep = 1.0 / Double(steps-1)
        var values   = [Double]()
            
        for _ in 0 ..< steps {
            let value = fromVal + (block(time: time) * (toVal - fromVal))
            values.append(value)
            time += timeStep
        }
        
        animation.calculationMode   = kCAAnimationLinear
        animation.values            = values
            
        return animation
    }
    
}