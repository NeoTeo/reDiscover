//
//  CoverArtArchiveWebFetcher.swift
//  reDiscover
//
//  Created by Matteo Sartori on 05/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit


@objc
class CoverArtArchiveWebFetcher : NSObject {

    static var delegate: SongPoolAccessProtocol?
    class func artForSong(song: TGSong) -> NSImage? {
        println("Requesting cover art from coverartarchive with id \(song.RelId!)")
        if let releaseMBID = song.RelId {
            println("1 \(releaseMBID)")
        
            if let coverArtArchiveURL = NSURL(string:"http://coverartarchive.org/release/\(releaseMBID)") {
//            if let coverArtArchiveURL = NSURL(string:"http://musicbrainz.org/release/\(releaseMBID)") {
                            println("2 \(coverArtArchiveURL)")
            if let result = NSData(contentsOfURL: coverArtArchiveURL) where result.length > 0 {
            // coverartarchive.org returns a dictionary at the top level.
                println("3!")
            let resultJSON = NSJSONSerialization.JSONObjectWithData(result, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
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
            }
            }
        }
        
        return nil
    }
    
//    class func requestAlbumArtFromWebForSong(songID: SongIDProtocol, imageHandler: (NSImage?) -> Void) {
//    class func artForSong(songID: SongIDProtocol) -> NSImage? {
//        var theImage: NSImage?
//        var lenient         = 0
//        var foundAlbumArt   = false
//        var leniencyLevel   = 0
//        let data            = delegate?.releasesForSongID(songID)
//
//        if data == nil { return nil }
//        
//        if let releases = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [NSDictionary] {
//
//            let songAlbum = delegate?.albumForSongID(songID)
//            
//            do {
//                
//                for release in releases {
//                    // TODO use regex for fuzzier matching of album name.
//                    // also look at adding more leniency levels with better secondary choices.
//                    if leniencyLevel == 1 || release["title"] as? String == songAlbum {
//                        
//                        let releaseMBID = release["id"] as! NSString
//                        let coverArtArchiveURL = NSURL(string:"http://coverartarchive.org/release/\(releaseMBID)")
//                        // blocks (presumably) until the url returns the data. This means this function should be called on a non-main thread.
//                        if coverArtArchiveURL == nil { continue }
//                        let result = NSData(contentsOfURL: coverArtArchiveURL!)
//                        
//                        // skip if this did not return any data
//                        if result == nil || result!.length == 0 {
//                            //println("Data returned from url \(coverArtArchiveURL) was empty");
//                            continue
//                        }
//                        
//                        // coverartarchive.org returns a dictionary at the top level.
//                        let resultJSON = NSJSONSerialization.JSONObjectWithData(result!, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
//                        
//                        let images = resultJSON["images"] as! NSArray
//                        
//                        if images.count == 0 {
//                            continue
//                        }
//                        
//                        let imageEntry = images[0] as! NSDictionary
//                        
//                        let imageURL = NSURL(string: imageEntry["image"] as! String)
//                        if imageURL == nil { continue }
//                        
//                        let coverArtData = NSData(contentsOfURL: imageURL!)
//                        
//                        if coverArtData == nil || coverArtData!.length == 0 {
//                            println("No cover art data!");
//                            continue
//                        }
//                        
//                        let theImage = NSImage(data: coverArtData!)
//                        
//                        // We're done here.
//                        return theImage
//                    }
//                }
//            } while leniencyLevel++ == 0
//        }
//        
//        // No luck finding cover art from coverartwebarchive.org
//        return nil
//    }
}
