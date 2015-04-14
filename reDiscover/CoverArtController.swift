//
//  CoverArtController.swift
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
            fetchingCoverImage = NSImage(named: "songImage")
        }
        return fetchingCoverImage
    }
    
    // Should this method even be here? artForSong adds any found art to the cache anyway.
    static func addImage(image: NSImage) -> SongArtId {
        // Is there any point to this when SongArt is the only class to have access to the artCache?
        // Why not just mutate the artCache?
        artCache = artCache.addImage(image)
        return image.hashId
    }
    
    // For now it's just the hashId, but may change.
    static func idForImage(image: NSImage) -> SongArtId {
        return image.hashId
    }
    
    static func artForSong(song: TGSong) -> NSImage {
        
        // Check if the song already has art in the artCache.
        // Return it if it does.
        if let art = artCache.artForSong(song) {
            return art
        }
        // Ask the SongArtFinder to find it and if it succeeds, 
        // add the found art to the artCache.
        if let art = SongArtFinder.findArtForSong(song) {
            artCache = artCache.addImage(art)
            return art
        }
        
        return getNoCoverImage()!
    }
}
