//
//  TGTimelineTransformer.swift
//  reDiscover
//
//  Created by Teo on 10/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

public final class TGTimelineTransformer: NSValueTransformer {

    var maxDuration: Double?
    
    public override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    public override func transformedValue(value: AnyObject?) -> AnyObject? {
        guard let maxD = maxDuration else { return nil }
        let numberValue = value as! NSNumber
        let unit = 100.0 / maxD
        return NSNumber(double: unit * numberValue.doubleValue )
    }
    
    public override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        guard let maxD = maxDuration else { return nil }
        let numberValue = value as! NSNumber
        return NSNumber(double: maxD / 100.0 * numberValue.doubleValue)
    }
}