//
//  SongMetadata.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation
// The problem I'm having with this massive initializer is probably symptomatic of
// a design problem. It seems to suggest that I have too many disparate concepts
// globbed together in one class and I should try to reduce and/or split
// the properties into sub structures that are logically grouped.
// Eg. is selectedSweetSpot really metadata on the song?
// Does songReleases belong inside the song?
// is the fingerPrintStatus not metadata on the fingerprint?
// We should distinguish between metadata on the song and data that is effectively
// housekeeping/state of the song instance?
class SongMetaData : NSObject, NSCopying {
    let title:              String?
    let album:              String?
    let artist:             String?
    let year:               UInt?
    let genre:              String?
    let songReleases:       NSData?
    
    init(title: String?, album: String?,artist: String?,year: UInt?,genre: String?,songReleases: NSData?) {
            self.title          = title
            self.album          = album
            self.artist         = artist
            self.year           = year
            self.genre          = genre
            self.songReleases   = songReleases?.copy() as? NSData
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return SongMetaData(title: title, album: album, artist: artist, year: year, genre: genre, songReleases: songReleases)
    }
}

extension SongMetaData {

    /** 
    This class method will *synchronously* fetch the cover art it finds in the songAsset's
    metadata.
    
    :param: song A song or nil
    :returns: An array of NSImages or an array of nil if nothing was found.
    */
    static func getCoverArtForSong(song: TGSongProtocol?) -> [NSImage?] {
        if  let sng = song,
            let songAsset = AVURLAsset(URL: NSURL(string: sng.urlString) , options: nil) {
            
                let sema = dispatch_semaphore_create(0)
                
                songAsset.loadValuesAsynchronouslyForKeys(["commonMetadata"]){

                    // Now that the metadata is loaded, signal to continue below.
                    dispatch_semaphore_signal(sema)
                }

                // Wait for the load to complete.
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)

                let artworks = AVMetadataItem.metadataItemsFromArray(songAsset.commonMetadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon)

                var retArt = [NSImage?]()
                for aw in artworks {
                    retArt.append(aw as? NSImage)
                }
                return retArt
        }
        
        return [nil]
    }
    
    func loadForSongId(songId: SongIDProtocol) -> Bool {
        return true
    }
    
    // replaces SongPool requestEmbeddedMetadataForSongID:
    static func metaDataForSong(song: TGSongProtocol) -> SongMetaData {
        return song.metadata
    }
}