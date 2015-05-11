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

        let fileManager = NSFileManager.defaultManager()
        if let dirContents = fileManager.contentsOfDirectoryAtURL(dirURL, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles, error: nil) {
            
            var imageURLs = [NSURL]()
            
            for item in dirContents as! [NSURL] {
                
                if getURLContentType(item) == .Image {
                    imageURLs.append(item)
                }
            }
            
            // return the array if we put anyting in it.
            if imageURLs.count > 0 {
                return imageURLs
            }
        }
        
        return nil
    }
    
    // Change this to return an enum type instead
    static func getURLContentType(theURL: NSURL) -> URLContentType {
        
        let ext = theURL.pathExtension
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil)
        let fileUTI = unmanagedFileUTI.takeRetainedValue()
        
        // Only add image files.
        if UTTypeConformsTo(fileUTI, kUTTypeImage) != 0 {
            return .Image
        }
        if UTTypeConformsTo(fileUTI, kUTTypeAudio) != 0 {
            return .Audio
        }
        return .Unknown
    }
}
