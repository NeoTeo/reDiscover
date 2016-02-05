//
//  TGTimelineTransformer.swift
//  reDiscover
//
//  Created by Teo on 10/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

public final class TGTimelineTransformer: NSValueTransformer {

    dynamic var maxDuration: Double = 0.0
    
    public override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    public override func transformedValue(value: AnyObject?) -> AnyObject {
        
        guard maxDuration != 0,
            let numberValue = value as? NSNumber else {
                
            return NSNumber(double: 0.0)
        }
        
        let unit = 100.0 / maxDuration
        return NSNumber(double: unit * numberValue.doubleValue )
    }
    
    public override func reverseTransformedValue(value: AnyObject?) -> AnyObject {
        guard let numberValue = value as? NSNumber else { return NSNumber(double: 0.0) }
        return NSNumber(double: maxDuration / 100.0 * numberValue.doubleValue)
    }
}
