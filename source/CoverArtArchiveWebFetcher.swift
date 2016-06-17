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
    
    class func artForSong(_ song: TGSong) -> NSImage? {

        if let releaseMBID = song.RelId,
            let coverArtArchiveURL = URL(string:"http://coverartarchive.org/release/\(releaseMBID)"),
            let result = try? Data(contentsOf: coverArtArchiveURL) where result.count > 0 {
            // coverartarchive.org returns a dictionary at the top level.
            do {
                let resultJSON = try JSONSerialization.jsonObject(with: result, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                let images = resultJSON["images"] as! NSArray
                
                if images.count == 0 { return nil }
                
                let imageEntry = images[0] as! NSDictionary
                
                let imageURL = URL(string: imageEntry["image"] as! String)
                if imageURL == nil { return nil }
                
                let coverArtData = try? Data(contentsOf: imageURL!)
                
                if coverArtData == nil || coverArtData!.count == 0 { return nil }
                
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
