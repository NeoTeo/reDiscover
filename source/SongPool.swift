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
    
    // Until we've switched TGSongPool over to this class we'll use it as a delegate.
    static var delegate: SongPoolAccessProtocol?
    
    /** I wanted the fingerPrinter to be a static protocol that I could call without
        having to instantiate it and without having to know about a specific implementation
        but although Swift allows static protocols you cannot call them directly; you
        need a specific class that conforms to the static protocol and then you can call
        that instead. However, this means we're complected with that specific class which
        we want to avoid.*/
//    private static var fingerPrinter: OldFingerPrinter?
    //FIXME: turn these two into protocols!
    private static var albumCollection: AlbumCollection?
    private static var songAudioPlayer: TGSongAudioPlayer?
    
    
    private static var songPool: SongDictionary?
    private static var songPoolAccessQ: dispatch_queue_t?
    
    private static let songDataUpdaterOpQ = NSOperationQueue()
    
    /** Bodgy type method to set the instances of the things we haven't yet turned
        into static classes/structs */
//    static func setVarious(theFingerPrinter: OldFingerPrinter, audioPlayer: TGSongAudioPlayer) {
    static func setVarious( audioPlayer: TGSongAudioPlayer) {
        albumCollection = AlbumCollection()
        songAudioPlayer = audioPlayer
    }
    
    
    static func durationForSongId(songId: SongID) -> NSNumber {
        return delegate!.songDurationForSongID(songId)
    }
    
    
    /// Request the song for the given id and return a copy of it.
    static func songForSongId(songId: SongIDProtocol) -> TGSong? {
        return songPool?[songId as! SongID]
    }

    /**     Initiate a request to play back the given song.
    
            If the song has a selected sweet spot play the song from there otherwise
            just play the song from the start.
            :params: songID The id of the song to play.
    */
    static func requestSongPlayback(songId: SongIDProtocol) {
        guard let song = SongPool.songForSongId(songId) else { return }
        
        let startTime = SweetSpotController.selectedSweetSpotForSong(song)
        delegate!.requestSongPlayback(songId, withStartTimeInSeconds: startTime)
        
    }
    
    /** Set up a chain of operations each dependent on the previous that update 
        various data associated with a song; 
        1) Loading its embedded file metadata,
        2) Generating an acoustic fingerprint of the song's audio,
        3) Looking up additional data such as an UUID using the fingerprint,
        4) Maintaining and updating the local album collection data.
        5) Looking for cover art in a large variety of places (including a web service).
    */
    static func requestUpdatedData(forSongId songId: SongIDProtocol) {
        
        /// Let any interested parties know we've started updating the current song.
        NSNotificationCenter.defaultCenter().postNotificationName("songDidStartUpdating", object: songId)
        
        /** This shouldn't really be set every time we request updated data but
        since this is a static class we've no init to call. */
        songDataUpdaterOpQ.maxConcurrentOperationCount = 1
        songDataUpdaterOpQ.qualityOfService = .UserInitiated
        
        // Override all previous ops by cancelling them and adding the new one.
        songDataUpdaterOpQ.cancelAllOperations()
        

        /// All the calls inside the blocks are synchronous.
        let updateMetadataOp = NSBlockOperation {
            updateMetadata(forSongId: songId)
        }
        let fingerPrinterOp = NSBlockOperation {
            /// If fingerPrinter is an empty optional we want it to crash.
//            updateFingerPrint(forSongId: songId, withFingerPrinter: fingerPrinter! )
            updateFingerPrint(forSongId: songId )
        }
        /// This relies on the fingerprint to request the UUId from  a server.
        let remoteDataOp = NSBlockOperation {
            /// If songAudioPlayer is an empty optional we want it to crash.
            updateRemoteData(forSongId: songId, withDuration: songAudioPlayer!.songDuration)
        }
        let updateAlbumOp = NSBlockOperation {
            albumCollection = AlbumCollection.update(albumContainingSongId: songId, usingOldCollection: albumCollection!)
        }
        let checkArtOp = NSBlockOperation {
            checkForArt(forSongId: songId, inAlbumCollection: albumCollection!)
        }
        let fetchSweetspotsOp = NSBlockOperation {
            SweetSpotServerIO.requestSweetSpotsForSongID(songId)
        }

        /// Make operations dependent on each other.
        fingerPrinterOp.addDependency(updateMetadataOp)
        remoteDataOp.addDependency(fingerPrinterOp)

        /// The sweetspot fetcher and album op depend on the fingerprint and the UUID.
        fetchSweetspotsOp.addDependency(remoteDataOp)
        updateAlbumOp.addDependency(remoteDataOp)
        
        checkArtOp.addDependency(updateAlbumOp)
        
        
        /// Add the ops to the queue.
        songDataUpdaterOpQ.addOperations([  updateMetadataOp,
                                            fingerPrinterOp,
                                            remoteDataOp,
                                            updateAlbumOp,
                                            checkArtOp,
                                            fetchSweetspotsOp], waitUntilFinished: false)
    }
    
    static func updateMetadata(forSongId songId: SongIDProtocol) {
        
        guard let metadata = SongCommonMetaData.loadedMetaDataForSongId(songId) else { return }
        
        addSong(withChanges: [.Metadata : metadata], forSongId: songId)
        
        /// Let anyone listening know that we've updated the metadata for the songId.
        NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
    }
    
    static func updateRemoteData(forSongId songId: SongIDProtocol, withDuration duration: CMTime) {

        guard let song = songForSongId(songId) else { return }
        guard let fingerprint = song.fingerPrint else { return }
        
        // If the song has not yet a uuid, get one.
        let uuid = song.UUId
        if uuid == nil {
            let durationInSeconds = UInt(CMTimeGetSeconds(duration))
            if let acoustIdData = AcoustIDWebService.dataDict(forFingerprint: fingerprint, ofDuration: durationInSeconds),
                let songUUId = SongUUID.extractUUIDFromDictionary(acoustIdData),
                let bestRelease = AcoustIDWebService.bestMatchRelease(forSong: song, inDictionary: acoustIdData),
                let releaseId = bestRelease.objectForKey("id") {
                    SongPool.addSong(withChanges: [.RelId : releaseId, .UuId : songUUId], forSongId: songId)
            }
        }
    }
    
//    static func getAlbum(forSongId songId: SongIDProtocol, fromAlbumCollection albums: AlbumCollection) -> Album? {
//        var album: Album?
//        if let song = songForSongId(songId),
//            let albumId = Album.albumIdForSong(song) {
//                album = AlbumCollection.albumWithIdFromCollection(albums, albumId: albumId)
//                if album == nil {
//                    album = Album(albumId: albumId, songIds: Set(arrayLiteral: songId as! SongID))
//                } else {
//                    album = Album.albumWithAddedSong(song, oldAlbum: album!)
//                }
//        }
//        return album
//    }
    
    static func updateFingerPrint(forSongId songId: SongIDProtocol) {
        guard let song = songForSongId(songId) else { return }
        
        // If there is no fingerprint, generate one sync'ly - this can be slow!
        if song.fingerPrint == nil,
            let songUrl = URLForSongId(songId),
            let newFingerPrint = TGSongFingerprinter.fingerprint(forSongUrl: songUrl) {
                addSong(withChanges: [.Fingerprint : newFingerPrint], forSongId: songId)
        }
        
    }
    
    static func URLForSongId(songId: SongIDProtocol) -> NSURL? {
        guard let song = songForSongId(songId) where (song.urlString != nil) else { return nil }
        return NSURL(string: song.urlString!)
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
        }
    }
    
    static func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongIDProtocol) {
        guard let queue = songPoolAccessQ else { return }
        
        dispatch_sync(queue) {
            // First we get the up-to-date song
            let oldSong = songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: changes)
            
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
                SongPool.addSong(withChanges: [.ArtId : newArtId], forSongId: songId)
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("songCoverUpdated", object: songId)
    }
    
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