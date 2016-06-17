//
//  Hasher.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

class Hasher {
    
    class func hashFromString(_ inString: String) -> String {
        //let str = inString.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CUnsignedInt(inString.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        
        let result = UnsafeMutablePointer<CUnsignedChar>(allocatingCapacity: digestLen)
        
        CC_MD5(inString, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deinitialize()
        
        return hash as String
    }
}
