//
//  SongPool.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation

typealias SongDictionary = [SongID: Song]

final class SongPool : NSObject, SongPoolAccessProtocol, SongMetadataUpdaterDelegate {
    
    // Until we've switched TGSongPool over to this class we'll use it as a delegate.
    //static var delegate: SongPoolAccessProtocol?
    
    //FIXME: turn these two into protocols!
//    private var albumCollection = AlbumCollection()
//    private static var songAudioPlayer: TGSongAudioPlayer?

    private var songPool: SongDictionary?
    private var songPoolAccessQ: dispatch_queue_t?
    private var serialDataLoad = dispatch_queue_create("serial data load queue", DISPATCH_QUEUE_SERIAL)
    

//    private let songDataUpdaterOpQ = NSOperationQueue()

//    private static var songAudioCacher = TGSongAudioCacher()
//    private static var currentSongDuration : NSNumber?

    
//    static var lastRequestedSongId : SongIDProtocol?
//    static var currentlyPlayingSongId : SongIDProtocol?
    
//    private static var requestedPlayheadPos : NSNumber?
//    static var requestedPlayheadPosition : NSNumber? {
//        /**
//         This method sets the requestedPlayheadPosition (which represents the position the user has manually set with a slider)
//         of the currently playing song to newPosition and sets a sweet spot for the song which gets stored on next save.
//         The requestedPlayheadPosition should only result in a sweet spot when the user releases the slider.
//         */
//        set(newPosition) {
//            guard newPosition != nil else { return }
//            self.requestedPlayheadPos = newPosition
//            songAudioPlayer?.currentPlayTime = newPosition!.doubleValue
//        }
//        
//        get {
//            return self.requestedPlayheadPos
//        }
//
//    }
    /// Being observed?
//    private static var playheadPos : NSNumber?
    
    /** Utility function allows wrapping code that needs to be sync'd on
        a queue in a block like this:
        synchronized {
            access common stuff...
            ...
        }
    */
    private func synchronized(f: Void -> Void) {
        guard songPoolAccessQ != nil else { fatalError("No songPoolAccessQ") }
        dispatch_sync(songPoolAccessQ!, f)
    }

//    static func setPlayhead(position : NSNumber) {
//        playheadPos = position
//        print("Playhead pos: \(playheadPos)")
//    }
    /** Bodgy type method to set the instances of the things we haven't yet turned
        into static classes/structs */
//    static func setVarious(theFingerPrinter: OldFingerPrinter, audioPlayer: TGSongAudioPlayer) {
//    func setVarious( audioPlayer: TGSongAudioPlayer) {
////        albumCollection = AlbumCollection()
////        songAudioPlayer = audioPlayer
//        //songAudioCacher.songPoolAPI = delegate
//    }
    /*
    static func cacheWithContext(cacheContext : SongSelectionContext) {
        
        /// Cache songs using the context
        songAudioCacher.cacheWithContext(cacheContext)
        
        /// Update the last requestedSongId.
        lastRequestedSongId = cacheContext.selectedSongId
        
        /// Request updated data for the selected song.
        requestUpdatedData(forSongId: lastRequestedSongId!)
    }
*/
//    static func durationForSongId(songId: SongID) -> NSNumber {
    /* Duration is now only obtained from the song itself
    static func durationForSongId(songId: SongIDProtocol) -> NSNumber {
        
        let song = SongPool.songForSongId(songId)
        let duration = song?.metadata?.duration
        
        if duration == 0.0 {
            return delegate!.songDurationForSongID(songId)
        } else {
            return NSNumber(double: duration!)
        }
    }
    */
    
    /// Request the song for the given id and return a copy of it.
    func songForSongId(songId: SongIDProtocol) -> TGSong? {
        return songPool?[songId as! SongID]
    }

    
//    /** Set up a chain of operations each dependent on the previous that update
//        various data associated with a song;
//        1) Loading its embedded file metadata,
//        2) Generating an acoustic fingerprint of the song's audio,
//        3) Looking up additional data such as an UUID using the fingerprint,
//        4) Maintaining and updating the local album collection data.
//        5) Looking for cover art in a large variety of places (including a web service).
//    */
//    func requestUpdatedData(forSongId songId: SongIDProtocol) {
//        
//        /// Let any interested parties know we've started updating the current song.
//        NSNotificationCenter.defaultCenter().postNotificationName("songDidStartUpdating", object: songId)
//        
//        /** This shouldn't really be set every time we request updated data but
//        since this is a static class we've no init to call. */
//        songDataUpdaterOpQ.maxConcurrentOperationCount = 1
//        songDataUpdaterOpQ.qualityOfService = .UserInitiated
//        
//        // Override all previous ops by cancelling them and adding the new one.
//        songDataUpdaterOpQ.cancelAllOperations()
//        
//
//        /// All the calls inside the blocks are synchronous.
//        let updateMetadataOp = NSBlockOperation {
//            self.updateMetadata(forSongId: songId)
//        }
//        let fingerPrinterOp = NSBlockOperation {
//            /// If fingerPrinter is an empty optional we want it to crash.
////            updateFingerPrint(forSongId: songId, withFingerPrinter: fingerPrinter! )
//            self.updateFingerPrint(forSongId: songId )
//        }
//        /// This relies on the fingerprint to request the UUId from  a server.
//        let remoteDataOp = NSBlockOperation {
//            /// If songAudioPlayer is an empty optional we want it to crash.
//            if let song = self.songForSongId(songId),
//                let duration = song.duration() {
//                self.updateRemoteData(forSongId: songId, withDuration: duration)
//            }
//        }
//        let updateAlbumOp = NSBlockOperation {
//            self.albumCollection = self.albumCollection.update(albumContainingSongId: songId, usingOldCollection: self.albumCollection)
//        }
//        let checkArtOp = NSBlockOperation {
//            self.checkForArt(forSongId: songId, inAlbumCollection: self.albumCollection)
//        }
//        let fetchSweetspotsOp = NSBlockOperation {
//            SweetSpotServerIO.requestSweetSpotsForSongID(songId)
//        }
//
//        /// Make operations dependent on each other.
//        fingerPrinterOp.addDependency(updateMetadataOp)
//        remoteDataOp.addDependency(fingerPrinterOp)
//
//        /// The sweetspot fetcher and album op depend on the fingerprint and the UUID.
//        fetchSweetspotsOp.addDependency(remoteDataOp)
//        updateAlbumOp.addDependency(remoteDataOp)
//        
//        checkArtOp.addDependency(updateAlbumOp)
//        
//        
//        /// Add the ops to the queue.
//        songDataUpdaterOpQ.addOperations([  updateMetadataOp,
//                                            fingerPrinterOp,
//                                            remoteDataOp,
//                                            updateAlbumOp,
//                                            checkArtOp,
//                                            fetchSweetspotsOp], waitUntilFinished: false)
//    }
    
//    func updateMetadata(forSongId songId: SongIDProtocol) {
//        
//        /// Check that the song doesn't already have metadata.
//        guard let song = songForSongId(songId) else { return }
////        if SongPool.songForSongId(songId)?.metadata != nil { return }
//        guard let metadata = SongCommonMetaData.loadedMetaDataForSongId(song) else { return }
//        /// We need to handle the case where metadata already exists!
//        addSong(withChanges: [.Metadata : metadata], forSongId: songId)
//        
//        /// Let anyone listening know that we've updated the metadata for the songId.
//        NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
//    }
//    
//    func updateRemoteData(forSongId songId: SongIDProtocol, withDuration duration: NSNumber) {
//
//        guard let song = songForSongId(songId) else { return }
//        guard let fingerprint = song.fingerPrint else { return }
//        
//        // If the song has not yet a uuid, get one.
//        let uuid = song.UUId
//        if uuid == nil {
//            let durationInSeconds = UInt(duration.integerValue) //UInt(CMTimeGetSeconds(duration))
//            if let acoustIdData = AcoustIDWebService.dataDict(forFingerprint: fingerprint, ofDuration: durationInSeconds),
//                let songUUId = SongUUID.extractUUIDFromDictionary(acoustIdData),
//                let bestRelease = AcoustIDWebService.bestMatchRelease(forSong: song, inDictionary: acoustIdData),
//                let releaseId = bestRelease.objectForKey("id") {
//                    addSong(withChanges: [.RelId : releaseId, .UuId : songUUId], forSongId: songId)
//            }
//        }
//    }
    
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
    
//    func updateFingerPrint(forSongId songId: SongIDProtocol) {
//        guard let song = songForSongId(songId) else { return }
//        
//        // If there is no fingerprint, generate one sync'ly - this can be slow!
//        if song.fingerPrint == nil,
//            let songUrl = getUrl(songId),
//            let (newFingerPrint, duration) = TGSongFingerprinter.fingerprint(forSongUrl: songUrl) {
//                let metadata = SongCommonMetaData(duration: duration)
//                
//                addSong(withChanges: [.Fingerprint : newFingerPrint, .Metadata : metadata], forSongId: songId)
//        }
//        
//    }
    
    func getUrl(songId: SongIDProtocol) -> NSURL? {
        guard let song = songForSongId(songId) where (song.urlString != nil) else { return nil }
        return NSURL(string: song.urlString!)
    }
    
    func UUIDStringForSongId(songId: SongIDProtocol) -> String? {
        guard let song = songForSongId(songId) else { return nil }
        return SongUUID.getUUIDForSong(song)
    }
    
    func songCount() -> Int {
        guard let count = songPool?.count else { return 0 }
        return count
    }

    func load(anUrl: NSURL) -> Bool {
        dispatch_async(serialDataLoad) {
            self.fillSongPoolWithSongURLsAtURL(anUrl)
        }
        return true
    }
    /**
        Make and return a dictionary of songs made from any audio URLs found 
        from the given URL.
    */
    func fillSongPoolWithSongURLsAtURL(theURL: NSURL){
//        var allSongs = [SongID: Song]()
        songPool = SongDictionary()
        songPoolAccessQ = dispatch_queue_create("songPool dictionary access queue", DISPATCH_QUEUE_SERIAL)
        
        LocalAudioFileStore.applyAudioURLsToClosure(theURL) { songURL in
            
            //MARK: At this point we want to check if our core data store has info on the song.
            //println("songURL \(songURL)")
            let songString = songURL.absoluteString
            let songId = SongID(string: songString)
            let songCommonMetaData : SongCommonMetaData? = nil//SongCommonMetaData()
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
            self.addSong(newSong)
            //SongPool.addSong(withMetadata: songCommonMetaData, forSongId: songId)
            
            NSNotificationCenter.defaultCenter().postNotificationName("NewSongAdded", object: songId)
        }
    }

    func addSong(theSong: TGSong) {
        
        synchronized {
            self.songPool![theSong.songID as! SongID] = theSong as? Song
        }
    }
    
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongIDProtocol) {

        /// FIXME : Do we really need to sync all of this?
        synchronized {
            // First we get the up-to-date song
            let oldSong = self.songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: changes)
            
            if let md = changes[.Metadata] as? SongCommonMetaData {
                print("metadata change \(md.duration)")
            }
            print("addSong withChanges has duration \(newSong.duration())")
            // Then we add that new song to the song pool using the songId
            self.songPool![songId as! SongID] = newSong as? Song
        }
    }
    
//    func checkForArt(forSongId songId: SongIDProtocol, inAlbumCollection collection: AlbumCollection) {
//        guard let song = songForSongId(songId) else { return }
//
//        // Change artForSong to take a songId
//        if song.artID == nil || SongArt.getArt(forArtId: song.artID!) == nil {
//            if let image = SongArtFinder.findArtForSong(song, collection: collection) {
//                
//                let newArtId = SongArt.addImage(image)
//                addSong(withChanges: [.ArtId : newArtId], forSongId: songId)
//            }
//        }
//        
//        NSNotificationCenter.defaultCenter().postNotificationName("songCoverUpdated", object: songId)
//    }
 
    /*
    static func storeSongData() {
        
        /// We need the dictionary to be available
//        save(songPoolDictionary)
        
        /// We need the MOC and Private MOC to be available
        CoreDataStore.save(
    
        SweetSpotServerIO.storeUpload...etc
    }
    */
    /**
     - (void)storeSongData {
         // REFAC
         [SongPool save:songPoolDictionary];
         
         // TEOSongData test
         [self saveContext:NO];
         
         // uploadedSweetSpots save
         [SweetSpotServerIO storeUploadedSweetSpotsDictionary];
         
         return;
     }
*/
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

extension SongPool : AlbumCollectionDelegate {
    func getSong(songId : SongIDProtocol) -> TGSong? {
        return songForSongId(songId)
    }
}

extension SongPool {
    func debugLogSongWithId(songId: SongIDProtocol) {
        
    }
    func debugLogCaches() {
        
    }

}