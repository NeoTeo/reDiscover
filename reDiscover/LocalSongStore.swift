//
//  LocalSongStore.swift
//  reDiscover
//
//  Created by Teo on 11/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

// Local file system song store.
class LocalSongStore : NSObject, SongStore {
    
}

/**
Given an URL the function will return an array with all the urls
it can find that represent a song.
*/
extension LocalSongStore {
    
    static func songURLsFromURL(theURL: NSURL) -> [NSURL]? {
        
        let fileManager = NSFileManager.defaultManager()
        if let enumerator = fileManager.enumeratorAtURL(theURL,
            includingPropertiesForKeys: [NSURLIsDirectoryKey],
            options: NSDirectoryEnumerationOptions(),
            errorHandler: { (url: NSURL!, error: NSError!) -> Bool in
                println("Error reading URL")
                return true
        }) {
            
            var songURLs = [NSURL]()
            for url in enumerator.allObjects as! [NSURL] {
                var error: NSError?
                var isDirectory: AnyObject?
                let value = url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey, error: &error)
                if isDirectory?.boolValue == false {
                    if LocalFileIO.getURLContentType(url) == .Audio {
                        songURLs.append(url)
                    }
                }
            }
            return songURLs
        }
        
        return nil
    }
}