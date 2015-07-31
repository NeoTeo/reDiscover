//
//  SongArt.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation

typealias SongArtId = NSString

@objc enum DefaultImage: Int {
    case None
    case Blank
    case Fetching
}

class SongArt : NSObject {
    private static var artCache = SongArtCache()
    
    // Three class variables that always contain the same images.
    private static var noCoverImage: NSImage?
    private static var blankCoverImage: NSImage?
    private static var fetchingCoverImage: NSImage?
    
    // Consider renaming the get functions as they are loaded terms in Cocoa land.
    static func getNoCoverImage() -> NSImage? {
        if noCoverImage == nil {
            noCoverImage = NSImage(named: "noCover")
        }
        return noCoverImage
    }
    
    static func getBlankCoverImage() -> NSImage? {
        if blankCoverImage == nil {
            blankCoverImage = NSImage(named: "songImage")
        }
        return blankCoverImage
    }
    
    static func getFetchingCoverImage() -> NSImage? {
        if fetchingCoverImage == nil {
            fetchingCoverImage = NSImage(named: "fetchingArt")
        }
        return fetchingCoverImage
    }
    
    /**
    Add an image to the art cache
    
    - parameter image: The image to add to the cache.
    - returns: The id of the art.
    */
    static func addImage(image: NSImage) -> SongArtId {
        // Is there any point to this when SongArt is the only class to have access to the artCache?
        // Why not just mutate the artCache?
        artCache = artCache.addImage(image)
        return image.hashId()
    }
    
    // For now it's just the hashId, but may change.
    static func idForImage(image: NSImage) -> SongArtId {
        return image.hashId()
    }
    
//    static func artForSong(song: TGSong) -> NSImage? {
//        
//        // Check if the song already has art in the artCache.
//        // Return it if it does.
//        if  let id = song.artID,
//            let art = artCache.artForArtId(id) {
//            return art
//        }
//        
//        return nil
//    }
    
    static func getArt(forArtId artId: String) -> NSImage? {
        return artCache.artForArtId(artId)
    }
    
    /**
    Associate a song with an art id.
    
    - parameter song: A song we want to associate with an art id.
    - parameter artId: the art id.
    - returns: A new song with the given art id.
    */
//    static func songWithArtId(song: TGSong, artId: SongArtId) -> TGSong {
//        
//        let newSong = Song(songId: song.songID, metadata: song.metadata, urlString: song.urlString, sweetSpots: song.sweetSpots, fingerPrint: song.fingerPrint, selectedSS: song.selectedSweetSpot, releases: song.songReleases, artId: artId as String, UUId: song.UUId, RelId: song.RelId)
//        
//        return newSong
//    }
}
