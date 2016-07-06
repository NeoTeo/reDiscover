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
    static func applyAudioURLsToClosure(_ topURL: URL, closure: (URL) -> () ) {
        
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: topURL,
            includingPropertiesForKeys: [URLResourceKey.isDirectoryKey.rawValue],
            options: FileManager.DirectoryEnumerationOptions(),
            errorHandler: { (url: URL!, error: NSError!) -> Bool in
                print("Error reading URL")
                return true
        }) {
            
            for url in enumerator.allObjects as! [URL] {

                var isDirectory: AnyObject?
                do {
                    try (url as NSURL).getResourceValue(&isDirectory, forKey: URLResourceKey.isDirectoryKey)
                    
                    if isDirectory?.boolValue == false {
                        if LocalFileIO.getURLContentType(url) == .audio {
                            closure(url)
                        }
                    }

                } catch {
                    print("Error! \(error)")
                }
            }
        }
    }
    
    static func songURLsFromURL(_ theURL: URL) -> [URL]? {
        
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: theURL,
            includingPropertiesForKeys: [URLResourceKey.isDirectoryKey.rawValue],
            options: FileManager.DirectoryEnumerationOptions(),
            errorHandler: { (url: URL!, error: NSError!) -> Bool in
                print("Error reading URL")
                return true
        }) {
            
            var songURLs = [URL]()
            for url in enumerator.allObjects as! [URL] {
                var isDirectory: AnyObject?

                do {
                    try (url as NSURL).getResourceValue(&isDirectory, forKey: URLResourceKey.isDirectoryKey)
                    if isDirectory?.boolValue == false {
                        if LocalFileIO.getURLContentType(url) == .audio {
                            songURLs.append(url)
                        }
                    }

                } catch {
                    print("Error! \(error)")
                }
            }
            print("songURLs size is \(songURLs.count)")
            return songURLs
        }
        
        return nil
    }
}
