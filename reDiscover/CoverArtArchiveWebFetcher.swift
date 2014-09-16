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

    var delegate: SongPoolAccessProtocol?
    
//    func requestAlbumArtFromWebForSong(songID: AnyObject, imageHandler: (NSImage?) -> Void) {
    func requestAlbumArtFromWebForSong(songID: SongIDProtocol, imageHandler: (NSImage?) -> Void) {        var theImage: NSImage?
        var lenient         = 0
        var foundAlbumArt   = false
        var leniencyLevel   = 0
        let data            = delegate?.releasesForSongID(songID)

        if data == nil {
            println("the song \(songID) returned no releases")
            imageHandler(nil)
            return
        }
        
        var releases        = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [NSDictionary]
        if releases == nil {
            println("releases could not be unarchived?! from this data: \(data)")
            return
        }

        let songAlbum       = delegate?.albumForSongID(songID)
        
        do {
            
            for release in releases! {
                // TODO use regex for fuzzier matching of album name.
                // also look at adding more leniency levels with better secondary choices.
                if leniencyLevel == 1 || release["title"] as? String == songAlbum {
                    
                    let releaseMBID = release["id"] as NSString
                    let coverArtArchiveURL = NSURL(string:"http://coverartarchive.org/release/\(releaseMBID)")
                    // blocks (presumably) until the url returns the data. This means this function should be called on a non-main thread.
                    if coverArtArchiveURL == nil { continue }
                    let result = NSData(contentsOfURL: coverArtArchiveURL!)
                    
                    // skip if this did not return any data
                    if result == nil || result!.length == 0 {
                        //println("Data returned from url \(coverArtArchiveURL) was empty");
                        continue
                    }
                    
                    // coverartarchive.org returns a dictionary at the top level.
                    let resultJSON = NSJSONSerialization.JSONObjectWithData(result!, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    
                    let images = resultJSON["images"] as NSArray
                    
                    if images.count == 0 {
                        continue
                    }
                    
                    let imageEntry = images[0] as NSDictionary
                    
                    let imageURL = NSURL(string: imageEntry["image"] as String)
                    if imageURL == nil { continue }
                    
                    let coverArtData = NSData(contentsOfURL: imageURL!)
                    
                    if coverArtData == nil || coverArtData!.length == 0 {
                        println("No cover art data!");
                        continue
                    }
                    
                    let theImage = NSImage(data: coverArtData)
                    imageHandler(theImage)
                    
                    // We're done here.
                    return
                }
            }
        } while leniencyLevel++ == 0
        
        // No luck finding cover art from coverartwebarchive.org
        imageHandler(nil)
    }
}
