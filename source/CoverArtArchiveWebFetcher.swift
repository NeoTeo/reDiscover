//
//  CoverArtArchiveWebFetcher.swift
//  reDiscover
//
//  Created by Matteo Sartori on 05/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit


class CoverArtArchiveWebFetcher : NSObject {
    
    class func artForSong(song: TGSong) -> NSImage? {

        if let releaseMBID = song.RelId,
            let coverArtArchiveURL = NSURL(string:"http://coverartarchive.org/release/\(releaseMBID)"),
            let result = NSData(contentsOfURL: coverArtArchiveURL) where result.length > 0 {
            // coverartarchive.org returns a dictionary at the top level.
            do {
                let resultJSON = try NSJSONSerialization.JSONObjectWithData(result, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                let images = resultJSON["images"] as! NSArray
                
                if images.count == 0 { return nil }
                
                let imageEntry = images[0] as! NSDictionary
                
                let imageURL = NSURL(string: imageEntry["image"] as! String)
                if imageURL == nil { return nil }
                
                let coverArtData = NSData(contentsOfURL: imageURL!)
                
                if coverArtData == nil || coverArtData!.length == 0 { return nil }
                
                let theImage = NSImage(data: coverArtData!)
                
                // We're done here.
                return theImage
            } catch {
                print("oh arse")
                return nil
            }

        }
        return nil
    }
}
