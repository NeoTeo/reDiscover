//
//  SongCommonMetadata.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation
import AppKit

/**
The SongCommonMetaData holds metadata about a song that is common to all songs such
as title, artist and so on. This is in contrast to SongRediscoverMetaData which holds
metadata specific to the reDicover app such as fingerprints, uuid and sweet spots.
*/
public class SongCommonMetaData : NSObject, NSCopying {
    let title:              String
    let album:              String
    let artist:             String
    let year:               UInt
    let genre:              String
    let duration:           Double

    init(title: String     = "No title",
        album: String      = "No album",
        artist: String     = "No artist",
        year: UInt         = 0,
        genre: String      = "No genre",
        duration: Double   = 0.0) {
            
        self.title          = title// == nil ? "No title" : title!
        self.album          = album// == nil ? "No album" : album!
        self.artist         = artist// == nil ? "No artist" : artist!
        self.year           = year
        self.genre          = genre// == nil ? "No genre" : genre!
        self.duration       = duration
    }
    
    public func copy(with zone: NSZone?) -> Any {
        return SongCommonMetaData(title: title, album: album, artist: artist, year: year, genre: genre, duration: duration)
    }
}

extension SongCommonMetaData {

    /**MARK: REFACTOR - rejigged to take songIds instead of song instances so as
        to be able to get the song at the latest possible moment rather than work
        with a stale copy that might have changed in the time from call to use.
        This approach does not preclude the case of another thread replacing the
        song that corresponds to the id between getting the latest song and adding
        a modified one - this would require a read and write within some
        kind of atomic transaction. Can I do that? That is, when I add a new song
        to the song pool using addSong it would:
        1) Start a locked/atomic transaction
        2) get the song that corresponds to the given songId
        3) make a new song that has the new changes passed to it
        4) write the new song in the place of the old one by using the same songId
        5) end the transaction.
    
        So, instead of passing addSong a new song it would pass the id of the song
        and the data to add.
    */
    /**
    This class method will *synchronously* fetch the cover art it finds in the songAsset's
    metadata.
    
    - parameter songId
    - returns: An array of NSImages or an empty array if nothing was found.
    */
    static func getCoverArtForSong(_ song : TGSong) -> [NSImage?] {
        
        if let metadata = SongCommonMetaData.commonMetadataForSong(song) as? [AVMetadataItem] {
            let artworks = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon) as [AVMetadataItem]
            
            var retArt = [NSImage?]()
            for aw: AVMetadataItem in artworks where aw.dataValue != nil {
                
                let ima = NSImage(data: aw.dataValue!)
                retArt.append(ima)
            }
            return retArt
        }
        return [nil]
    }

    private class func commonMetadataForSong(_ song : TGSong) -> [AnyObject]? {

//        if  let sng = SongPool.songForSongId(songId) where sng.urlString != nil,
        if song.urlString != nil,
            let url = URL(string: song.urlString!) {
//                print("commonMetadataForSong song \(sng.songID) sweeties \(sng.sweetSpots)")
                let songAsset = AVURLAsset(url: url , options: nil)
                return songAsset.commonMetadata
        }
        return nil
    }
    /*
    static func songWithLoadedMetaData(songId: SongId) -> TGSong? {
        if let rawMetadata = SongCommonMetaData.commonMetadataForSong(songId),
            let song = SongPool.songForSongId(songId) {
            return Song(songId: song.songID,
                //            metadata: SongMetaData.loadMetaData(fromURLString: song.urlString!),
                metadata: SongCommonMetaData.extractMetaData(fromRawMetadata: rawMetadata),
                urlString: song.urlString,
                sweetSpots: song.sweetSpots,
                fingerPrint: song.fingerPrint,
                selectedSS: song.selectedSweetSpot,
                releases: song.songReleases,
                artId: song.artID,
                UUId: song.UUId,
                RelId: song.RelId)
        }
        return nil
    }
*/
    static func loadedMetaDataForSongId(_ song: TGSong) -> SongCommonMetaData? {
        
        guard let rawMetadata = SongCommonMetaData.commonMetadataForSong(song) else { return nil }
        
        return SongCommonMetaData.extractMetaData(fromRawMetadata: rawMetadata)
    }

    /* REFACTOR

    /**
    This class method will *synchronously* fetch the cover art it finds in the songAsset's
    metadata.
    
    - parameter song: A song or nil
    - returns: An array of NSImages or an array of nil if nothing was found.
    */
    static func getCoverArtForSong(song: TGSong?) -> [NSImage?] {
        
        if let metadata = SongCommonMetaData.commonMetadataForSong(song) as? [AVMetadataItem] {
            let artworks = AVMetadataItem.metadataItemsFromArray(metadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon) as [AVMetadataItem]
            
            var retArt = [NSImage?]()
            for aw: AVMetadataItem in artworks where aw.dataValue != nil {
                
                let ima = NSImage(data: aw.dataValue!)
                retArt.append(ima)
            }
            return retArt
        }
        return [nil]
    }
    
    private class func commonMetadataForSong(song: TGSong?) -> [AnyObject]? {
        if  let sng = song where sng.urlString != nil,
            let url = NSURL(string: sng.urlString!) {
                print("commonMetadataForSong song \(song?.songID) sweeties \(song?.sweetSpots)")
                let songAsset = AVURLAsset(URL: url , options: nil)
                return songAsset.commonMetadata
        }
        return nil
    }

    static func songWithLoadedMetaData(song: TGSong) -> TGSong {
        if let rawMetadata = SongCommonMetaData.commonMetadataForSong(song) {
                return Song(songId: song.songID,
                    //            metadata: SongMetaData.loadMetaData(fromURLString: song.urlString!),
                    metadata: SongCommonMetaData.extractMetaData(fromRawMetadata: rawMetadata),
                    urlString: song.urlString,
                    sweetSpots: song.sweetSpots,
                    fingerPrint: song.fingerPrint,
                    selectedSS: song.selectedSweetSpot,
                    releases: song.songReleases,
                    artId: song.artID,
                    UUId: song.UUId,
                    RelId: song.RelId)
        }
        return song
    }
    */
    private static func extractMetaData(fromRawMetadata metadata: [AnyObject]) -> SongCommonMetaData {
        
        var title: String   = "No title"
        var album: String   = "No album"
        let genre: String   = "No genre"
        var artist: String  = "No artist"
        var year: UInt      = 0
        let metadata        = metadata as! [AVMetadataItem]

        let titles = AVMetadataItem.metadataItems(from: metadata,
            withKey: AVMetadataCommonKeyTitle,
            keySpace:AVMetadataKeySpaceCommon)
        
        let albums = AVMetadataItem.metadataItems(from: metadata,
            withKey: AVMetadataCommonKeyAlbumName,
            keySpace:AVMetadataKeySpaceCommon)
        
        let artists = AVMetadataItem.metadataItems(from: metadata,
            withKey: AVMetadataCommonKeyArtist,
            keySpace:AVMetadataKeySpaceCommon)
        
        let years = AVMetadataItem.metadataItems(from: metadata, 
            withKey: AVMetadataCommonKeyCreationDate,
            keySpace:AVMetadataKeySpaceCommon)

        if titles.count > 0 { title = titles[0].value as! String }
        if albums.count > 0 { album = albums[0].value as! String }
        if artists.count > 0 { artist = artists[0].value as! String }
        
        //FIXME: Beware, this can also be a string value!
        //print("YEARS: \(years)")
        if years.count > 0 && years[0].key! is NSNumber {
            if let num = years[0].numberValue {
                //year = years[0].numberValue?.unsignedIntegerValue as! UInt
                year = num.uintValue
                //print("Magic!~~ \(year)")
            }
        }
//        if years.count > 0 { year = years[0].numberValue as! UInt }
        
        return SongCommonMetaData(title: title, album: album, artist: artist, year: year, genre: genre)
    }
    
    static func extractCoverArt(fromRawMetadata metadata: [AnyObject]) -> [NSImage?] {
        
        let metadata = metadata as! [AVMetadataItem]
        
        let artworks = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon)
        
        var retArt = [NSImage?]()
        let aw = artworks[0]
        
        if let data = aw.dataValue,
            let art = NSImage(data: data) {
            retArt.append(art)
        }
        return retArt
    }
    /**
    Loads the metadata from the file at the given url.

    :params: urlString The song url string.
    - returns: the metadata.
    */
    static func loadMetaData(fromURLString urlString: String) -> SongCommonMetaData {
        
        var title: String = "No title"
        var album: String = "No album"
        var genre: String = "No genre"
        var artist: String = "No artist"
        var year: UInt = 0
        
        if let songURL = URL(string: urlString) {
            //let pathString = songURL.path
            
            if let metadata = MDItemCreateWithURL(kCFAllocatorDefault, songURL as CFURL!) {
                if let artists = MDItemCopyAttribute(metadata,kMDItemAuthors) as? NSArray {
                    artist = artists[0] as! String
                }
                if let ti = MDItemCopyAttribute(metadata,kMDItemTitle) as? String { title = ti }
                if let al = MDItemCopyAttribute(metadata,kMDItemAlbum) as? String { album = al }
                if let ge = MDItemCopyAttribute(metadata,kMDItemMusicalGenre) as? String { genre = ge }
                if let ye = MDItemCopyAttribute(metadata,kMDItemRecordingYear) as? UInt { year = ye }
            }
        }

        return SongCommonMetaData(title: title, album: album, artist: artist, year: year, genre: genre)
    }
    
    // replaces SongPool requestEmbeddedMetadataForSongID:
    static func metaDataForSong(_ song: TGSong) -> SongCommonMetaData {
        return song.metadata!
    }
}
