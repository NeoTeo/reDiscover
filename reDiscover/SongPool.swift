//
//  SongPool.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

typealias SongDictionary = [SongID: Song]

final class SongPool : NSObject {
    
    private static var songPool: SongDictionary?
    static var delegate: SongPoolAccessProtocol?
    private static var songPoolAccessQ: dispatch_queue_t?

    
    static func durationForSongId(songId: SongID) -> NSNumber {
        return delegate!.songDurationForSongID(songId)
    }
    //MARK: deprecated - call SweetSpotController.sweetSpotsForSong directly
    static func sweetSpotsForSongId(songId: SongID) -> NSArray {
        return delegate!.sweetSpotsForSongID(songId)
    }
    
    // Until we've switched TGSongPool over to this class we'll use it as a delegate.
    // In this case we request the song for the given id and return a copy of it.
    static func songForSongId(songId: SongIDProtocol) -> TGSong? {
        return songPool?[songId as! SongID]
//        if let song = delegate?.songForID(songId) {
//            
//            return Song(songId: song.songID,
//                metadata: song.metadata,
//                urlString: song.urlString,
//                sweetSpots: song.sweetSpots,
//                fingerPrint: song.fingerPrint,
//                selectedSS: song.selectedSweetSpot,
//                releases: song.songReleases,
//                artId: song.artID,
//                UUId: song.UUId,
//                RelId: song.RelId)
//        }
//        return nil
    }

    
    static func UUIDStringForSongId(songId: SongIDProtocol) -> String? {
        return SongUUID.getUUIDForSongId(songId)
    }
    
    static func songCount() -> Int {
        guard let count = songPool?.count else { return 0 }
        return count
    }

    /**
        Make and return a dictionary of songs made from any audio URLs found 
        from the given URL.
    */
    static func fillSongPoolWithSongURLsAtURL(theURL: NSURL){
//        var allSongs = [SongID: Song]()
        songPool = SongDictionary()
        songPoolAccessQ = dispatch_queue_create("songPool dictionary access queue", DISPATCH_QUEUE_SERIAL)
        
        LocalAudioFileStore.applyAudioURLsToClosure(theURL) { songURL in
            
            //MARK: At this point we want to check if our core data store has info on the song.
            //println("songURL \(songURL)")
            let songString = songURL.absoluteString
            let songId = SongID(string: songString)
            let songCommonMetaData = SongCommonMetaData(title: nil, album: nil, artist: nil, year: 1071, genre: nil)
            let newSong = Song(songId: songId, metadata: songCommonMetaData, urlString: songString, sweetSpots: nil, fingerPrint: nil, selectedSS: nil, releases: nil, artId: nil, UUId: nil, RelId: nil)
            
            //songPool[songId] = newSong
            //FIXME: This is dangerous because other parts of the code may be accessing 
            // the songPool whilst we are adding to it.
            /*
            It is possible to get into a situation where the loading of the URLs takes so long that
            the songs' metadata is generated (fingerprint) or fetched (cover art) before this function is done.
            This would mean that different areas of the program would try to add the changes (as new songs) to 
            the songPool simultanously.
            So, access to the songPool needs to be done through a queue instead of directly as seen below.
            */
            SongPool.addSong(newSong)
            //SongPool.addSong(withMetadata: songCommonMetaData, forSongId: songId)
            
            NSNotificationCenter.defaultCenter().postNotificationName("NewSongAdded", object: songId)
        }
    }



    static func addSong(theSong: TGSong) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            SongPool.songPool![theSong.songID as! SongID] = theSong as? Song
            print("The song \(theSong.songID) just added to songPool has the following sweet spots \(theSong.sweetSpots)")
            if theSong.sweetSpots == nil {
                print("here")
            }else {
                print("cool")
            }
        }
    }

    static func addSong(withURLString urlString: String, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: [.UrlString:urlString])
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong as? Song
        }
    }
    
    static func addSong(withMetadata metadata: SongCommonMetaData, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata
            let newSong = Song(songId: songId,
                metadata: metadata,
                urlString: oldSong?.urlString,
                sweetSpots: oldSong?.sweetSpots,
                fingerPrint: oldSong?.fingerPrint,
                selectedSS: oldSong?.selectedSweetSpot,
                releases: oldSong?.songReleases,
                artId: oldSong?.artID,
                UUId: oldSong?.UUId,
                RelId: oldSong?.RelId)
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong
            
            print("AddSongMetadata: \(newSong.songID) just added to songPool has the following sweet spots \(newSong.sweetSpots)")
        }
    }

    static func addSong(withFingerprint fingerprint: String, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata
            let newSong = Song(songId: songId,
                metadata: oldSong?.metadata,
                urlString: oldSong?.urlString,
                sweetSpots: oldSong?.sweetSpots,
                fingerPrint: fingerprint,
                selectedSS: oldSong?.selectedSweetSpot,
                releases: oldSong?.songReleases,
                artId: oldSong?.artID,
                UUId: oldSong?.UUId,
                RelId: oldSong?.RelId)
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong
            
            print("AddSongFingerprint: \(newSong.songID) just added to songPool has the following sweet spots \(newSong.sweetSpots)")
        }
    }

    static func addSong(withUUId UUId: String, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata
            let newSong = Song(songId: songId,
                metadata: oldSong?.metadata,
                urlString: oldSong?.urlString,
                sweetSpots: oldSong?.sweetSpots,
                fingerPrint: oldSong?.fingerPrint,
                selectedSS: oldSong?.selectedSweetSpot,
                releases: oldSong?.songReleases,
                artId: oldSong?.artID,
                UUId: UUId,
                RelId: oldSong?.RelId)
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong
            
            print("AddSongUUId: \(newSong.songID) just added to songPool has the following sweet spots \(newSong.sweetSpots)")
        }
    }
    
    static func addSong(withReleaseId RelId: String, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: [.RelId : RelId])
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong as? Song
        }
    }

    static func addSong(withArtId artId: SongArtId, forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: [.ArtId : artId])
            
            // Then we add that new song to the song pool using the songId
            SongPool.songPool![songId as! SongID] = newSong as? Song
        }
    }

    static func checkForArt(forSongId songId: SongIDProtocol, inAlbumCollection collection: AlbumCollection) {
        guard let song = songForSongId(songId) else { return }

        // Change artForSong to take a songId
        if song.artID == nil || SongArt.getArt(forArtId: song.artID!) == nil {
            if let image = SongArtFinder.findArtForSong(song, collection: collection) {
                let newArtId = SongArt.addImage(image)
                SongPool.addSong(withArtId: newArtId, forSongId: songId)
            }
        } else {
            print("Image was found in art cache")
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("songCoverUpdated", object: songId)
    }
//    static func songPoolWithSong(thePool: SongDictionary, theSong: TGSong) -> SongDictionary {
//        
//    }
    /**
        Traverse the pool of songs and, for each, compare the metadata fields we want to save with the
        metadata fields of the corresponding core data item. If they differ, update the core data item so
        that it is saved when we call the associated managed object context's save.
    */
    
    static func save(pool: NSDictionary) {
//        let myStore = SongMetaDataStoreLocal(metaData:[:])

        for (_,value) in pool {
            let song: Song = value as! Song
            if let cmd = song.metadata {

                let genMD = SongGeneratedMetaData(UUId: song.UUId, URLString: song.urlString!)
                let theMetaData = SongMetaData(common: cmd, genMetaData: genMD)

                print("I gots: \(theMetaData.commonMetaData.title)")
            }
        }
    }
}