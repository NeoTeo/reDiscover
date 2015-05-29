//
//  NSImage+HashId.swift
//  reDiscover
//
//  Created by Teo on 15/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

extension NSImage {
    func hashId() -> String {

        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        if let imageData = self.TIFFRepresentation {
            let dataLen = CUnsignedInt(imageData.length)
            let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
            
            CC_MD5(imageData.bytes, dataLen, result)
            
            var hash = NSMutableString()
            for i in 0..<digestLen {
                hash.appendFormat("%02x", result[i])
            }
            
            result.destroy()
            return hash as String
        }
        //FIXME: We want to catch this - needs to propagate the error back up the chain.
        fatalError("ERROR: Image has no TIFFRepresentation!")
        
        
    }
}