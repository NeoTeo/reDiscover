//
//  SongPool.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

class SongPool : NSObject {
    
    static var delegate: SongPoolAccessProtocol?
    
    // Until we've switched TGSongPool over to this class we'll use it as a delegate.
    // In this case we request the song for the given id and return a copy of it.
    class func songForSongId(songId: SongIDProtocol) -> TGSong? {
        if let song = delegate?.songForID(songId) {
            
            return Song(songId: song.songID,
                metadata: song.metadata,
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
    
    /**
        Make and return a dictionary of songs made from any audio URLs found 
        from the given URL.
    */
    static func songDictionaryFromURL(theURL: NSURL) -> [SongID : Song]? {
        var allSongs = [SongID: Song]()
        
        LocalAudioFileStore.applyAudioURLsToClosure(theURL) { songURL in
            
            println("songURL \(songURL)")
            let songString = songURL.absoluteString!
            let songId = SongID(string: songString)
            let songCommonMetaData = SongCommonMetaData(title: nil, album: nil, artist: nil, year: 1071, genre: nil)
            let newSong = Song(songId: songId, metadata: songCommonMetaData, urlString: songString, sweetSpots: nil, fingerPrint: nil, selectedSS: 0, releases: nil, artId: nil, UUId: nil, RelId: nil)
            
            allSongs[songId] = newSong
            
            NSNotificationCenter.defaultCenter().postNotificationName("NewSongAdded", object: songId)
        }
        return allSongs
    }

    /**
        Traverse the pool of songs and, for each, compare the metadata fields we want to save with the
        metadata fields of the corresponding core data item. If they differ, update the core data item so
        that it is saved when we call the associated managed object context's save.
    */
    static func save(pool: NSDictionary) {
        let myStore = SongMetaDataStoreLocal(metaData:[:])

        for (key,value) in pool {
            let song: Song = value as! Song
            if let cmd = song.metadata {

                let genMD = SongGeneratedMetaData(UUId: song.UUId, URLString: song.urlString!)
                let theMetaData = SongMetaData(common: cmd, genMetaData: genMD)

                println("I gots: \(theMetaData.commonMetaData.title)")
            }
        }
    }
}