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
    let title:              String
    let album:              String
    let artist:             String
    let year:               UInt
    let genre:              String
    let songReleases:       NSData?
    

    init(title: String?, album: String?,artist: String?, year: UInt, genre: String?, songReleases: NSData?) {
        self.title          = title == nil ? "No title" : title!
        self.album          = album == nil ? "No album" : album!
        self.artist         = artist == nil ? "No artist" : artist!
        self.year           = year
        self.genre          = genre == nil ? "No genre" : genre!
        self.songReleases   = songReleases?.copy() as? NSData
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return SongMetaData(title: title, album: album, artist: artist, year: year, genre: genre, songReleases: songReleases!)
    }
}

extension SongMetaData {

    /** 
    This class method will *synchronously* fetch the cover art it finds in the songAsset's
    metadata.
    
    :param: song A song or nil
    :returns: An array of NSImages or an array of nil if nothing was found.
    */
    static func getCoverArtForSong(song: TGSong?) -> [NSImage?] {
//        if  let sng = song,
//            let songAsset = AVURLAsset(URL: NSURL(string: sng.urlString!) , options: nil) {
//            
//                let sema = dispatch_semaphore_create(0)
//                
//                songAsset.loadValuesAsynchronouslyForKeys(["commonMetadata"]){
//
//                    // Now that the metadata is loaded, signal to continue below.
//                    dispatch_semaphore_signal(sema)
//                }
//
//                // Wait for the load to complete.
//                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
        
        if let metadata = SongMetaData.commonMetadataForSong(song) {
        
                let artworks = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon) as! [AVMetadataItem]

                var retArt = [NSImage?]()
                for aw: AVMetadataItem in artworks {
//                    if aw.keySpace == AVMetadataKeySpaceID3 {
//                        
//                    }

                    let ima = NSImage(data: aw.dataValue)
                    retArt.append(ima)
                }
                return retArt
        }
//        }
        
        return [nil]
    }
    
    private class func commonMetadataForSong(song: TGSong?) -> [AnyObject]? {
        if  let sng = song,
            let songAsset = AVURLAsset(URL: NSURL(string: sng.urlString!) , options: nil) {
                
//                let sema = dispatch_semaphore_create(0)
//                
//                songAsset.loadValuesAsynchronouslyForKeys(["commonMetadata"]){
//                    
//                    // Now that the metadata is loaded, signal to continue below.
//                    dispatch_semaphore_signal(sema)
//                }
//                
//                // Wait for the load to complete.
//                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
                
                return songAsset.commonMetadata
        }
        return nil
    }
    
    static func songWithLoadedMetaData(song: TGSong) -> TGSong {
        if let rawMetadata = SongMetaData.commonMetadataForSong(song) {
            
//            let arts = SongMetaData.extractCoverArt(fromRawMetadata: rawMetadata)
//            var artId = song.artID as String?
//            if let art = arts[0] { artId = SongArt.idForImage(art) as String }
            
                return Song(songId: song.songID,
                    //            metadata: SongMetaData.loadMetaData(fromURLString: song.urlString!),
                    metadata: SongMetaData.extractMetaData(fromRawMetadata: rawMetadata),
                    urlString: song.urlString,
                    sweetSpots: song.sweetSpots,
                    fingerPrint: song.fingerPrint,
                    selectedSS: song.selectedSweetSpot,
                    releases: song.songReleases,
                    artId: song.artID,
                    UUId: song.UUId)
        }
        return song
    }

    static func extractMetaData(fromRawMetadata metadata: [AnyObject]) -> SongMetaData {
        var title: String = "No title"
        var album: String = "No album"
        var genre: String = "No genre"
        var artist: String = "No artist"
        var year: UInt = 0

        let titles = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyTitle, keySpace:AVMetadataKeySpaceCommon) as [AnyObject]!
        let albums = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyAlbumName, keySpace:AVMetadataKeySpaceCommon) as [AnyObject]!
        let artists = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyArtist, keySpace:AVMetadataKeySpaceCommon) as [AnyObject]!


        if titles.count > 0 { title = (titles[0] as! AVMetadataItem).value() as! String }
        if albums.count > 0 { album = (albums[0] as! AVMetadataItem).value() as! String }
        if artists.count > 0 { artist = (artists[0] as! AVMetadataItem).value() as! String }
        
        return SongMetaData(title: title, album: album, artist: artist, year: year, genre: genre, songReleases: nil)
    }
    
    static func extractCoverArt(fromRawMetadata metadata: [AnyObject]) -> [NSImage?] {
        let artworks = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon) as! [AVMetadataItem]
        var retArt = [NSImage?]()
        let aw = artworks[0]
        
        if let art = NSImage(data: aw.dataValue) {
                retArt.append(art)
        }
        return retArt
    }
    /**
    Loads the metadata from the file at the given url.

    :params: urlString The song url string.
    :returns: the metadata.
    */
    static func loadMetaData(fromURLString urlString: String) -> SongMetaData {
        
        var title: String = "No title"
        var album: String = "No album"
        var genre: String = "No genre"
        var artist: String = "No artist"
        var year: UInt = 0
        
        if let songURL = NSURL(string: urlString) {
            let pathString = songURL.path
            
            if let metadata = MDItemCreateWithURL(kCFAllocatorDefault, songURL) {
                if let artists = MDItemCopyAttribute(metadata,kMDItemAuthors) as? NSArray {
                    artist = artists[0] as! String
                }
                if let ti = MDItemCopyAttribute(metadata,kMDItemTitle) as? String { title = ti }
                if let al = MDItemCopyAttribute(metadata,kMDItemAlbum) as? String { album = al }
                if let ge = MDItemCopyAttribute(metadata,kMDItemMusicalGenre) as? String { genre = ge }
                if let ye = MDItemCopyAttribute(metadata,kMDItemRecordingYear) as? UInt { year = ye }
            }
        }

        return SongMetaData(title: title, album: album, artist: artist, year: year, genre: genre, songReleases: nil)
    }
    
    // replaces SongPool requestEmbeddedMetadataForSongID:
    static func metaDataForSong(song: TGSong) -> SongMetaData {
        return song.metadata!
    }
}