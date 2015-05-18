//
//  LocalAudioFileStore.swift
//  reDiscover
//
//  Created by Teo on 11/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

// Local file system song store.
class LocalAudioFileStore : NSObject, AudioFileStore {
    
}

/**
Given an URL the function will return an array with all the urls
it can find that represent a song.
*/
extension LocalAudioFileStore {
    
    /**
        Apply each audio URL found below the given topURL to the given closure.
    
        Because the fetching of each url can take a non-trivial amount of time we
        want to perform the closure as soon as we have anything to work with. This
        means calling it with each url rather than collecting all the urls first and 
        then passing them back for something else to apply them to. 
    (This was tested empirically (times in seconds) on a remote dir with 22977 urls:
        executionTime for finding urls and calling closure on each = 24.0814030170441
        executionTime for just finding urls and returning them as array  = 21.6866909861565
    )
    */
    static func applyAudioURLsToClosure(topURL: NSURL, closure: (NSURL) -> () ) {
        
        let fileManager = NSFileManager.defaultManager()
        if let enumerator = fileManager.enumeratorAtURL(topURL,
            includingPropertiesForKeys: [NSURLIsDirectoryKey],
            options: NSDirectoryEnumerationOptions(),
            errorHandler: { (url: NSURL!, error: NSError!) -> Bool in
                println("Error reading URL")
                return true
        }) {
            
            for url in enumerator.allObjects as! [NSURL] {
                var error: NSError?
                var isDirectory: AnyObject?
                let value = url.getResourceValue(&isDirectory, forKey: NSURLIsDirectoryKey, error: &error)
                if isDirectory?.boolValue == false {
                    if LocalFileIO.getURLContentType(url) == .Audio {
                        closure(url)
                    }
                }
            }
        }
    }
    
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
            println("songURLs size is \(songURLs.count)")
            return songURLs
        }
        
        return nil
    }
}