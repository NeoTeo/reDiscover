//
//  NSImage+HashId.swift
//  reDiscover
//
//  Created by Teo on 15/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    func hashId() -> String {

        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        if let imageData = self.tiffRepresentation {
            let dataLen = CUnsignedInt(imageData.count)
            let result = UnsafeMutablePointer<CUnsignedChar>(allocatingCapacity: digestLen)
            
            CC_MD5((imageData as NSData).bytes, dataLen, result)
            
            let hash = NSMutableString()
            for i in 0..<digestLen {
                hash.appendFormat("%02x", result[i])
            }
            
            result.deinitialize()
            return hash as String
        }
        //FIXME: We want to catch this - needs to propagate the error back up the chain.
        fatalError("ERROR: Image has no TIFFRepresentation!")
        
        
    }
}
