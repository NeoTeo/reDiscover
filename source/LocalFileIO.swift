//
//  LocalFileIO.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa


class LocalFileIO: NSObject {

    class func imageURLsAtPath(_ dirURL: URL) -> [URL]? {

        let fileManager = FileManager.default
        do {
            let dirContents = try fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            var imageURLs = [URL]()
            
            for item in dirContents as [URL] {
                
                if getURLContentType(item) == .image {
                    imageURLs.append(item)
                }
            }
            
            // return the array if we put anyting in it.
            if imageURLs.count > 0 {
                return imageURLs
            }
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
    
    // Change this to return an enum type instead
    static func getURLContentType(_ theURL: URL) -> URLContentType {
        
        if let ext = theURL.pathExtension,
            let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil) {
                
            let fileUTI = unmanagedFileUTI.takeRetainedValue()
            // Only add image files.
            if UTTypeConformsTo(fileUTI, kUTTypeImage) {
                return .image
            }
            if UTTypeConformsTo(fileUTI, kUTTypeAudio) {
                return .audio
            }
        }
        return .unknown
    }
}
