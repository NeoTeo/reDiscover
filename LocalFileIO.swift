//
//  LocalFileIO.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

class LocalFileIO: NSObject {

    class func imageURLsAtPath(dirURL: NSURL) -> [NSURL]? {
        println("LocalFileIO \(dirURL.filePathURL?.absoluteString)")
        let fileManager = NSFileManager.defaultManager()
        if let dirContents = fileManager.contentsOfDirectoryAtURL(dirURL, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles, error: nil) {
         
            println("The dir contents \(dirContents)")
        }
        
        return nil
    }
}
