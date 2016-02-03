//
//  SongMetadataUpdater.swift
//  reDiscover
//
//  Created by teo on 03/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongMetadataUpdaterDelegate {
    func getSong(songId : SongIDProtocol) -> TGSong?
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongIDProtocol)
}

public class SongMetadataUpdater {

    var delegate : SongMetadataUpdaterDelegate?
    
    private let songDataUpdaterOpQ = NSOperationQueue()
    private var albumCollection = AlbumCollection()

    init(delegate : SongMetadataUpdaterDelegate) {
        self.delegate = delegate
        albumCollection.delegate = self
    }
    
    
    /** Set up a chain of operations each dependent on the previous that update
     various data associated with a song;
     1) Loading its embedded file metadata,
     2) Generating an acoustic fingerprint of the song's audio,
     3) Looking up additional data such as an UUID using the fingerprint,
     4) Maintaining and updating the local album collection data.
     5) Looking for cover art in a large variety of places (including a web service).
     */
    func requestUpdatedData(forSongId songId: SongIDProtocol) {
        
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
            self.updateMetadata(forSongId: songId)
        }
        let fingerPrinterOp = NSBlockOperation {
            /// If fingerPrinter is an empty optional we want it to crash.
            //            updateFingerPrint(forSongId: songId, withFingerPrinter: fingerPrinter! )
            self.updateFingerPrint(forSongId: songId )
        }
        /// This relies on the fingerprint to request the UUId from  a server.
        let remoteDataOp = NSBlockOperation {
            /// If songAudioPlayer is an empty optional we want it to crash.
            if let song = self.delegate?.getSong(songId),
                let duration = song.duration() {
                    self.updateRemoteData(forSongId: songId, withDuration: duration)
            }
        }
        let updateAlbumOp = NSBlockOperation {
            self.albumCollection = self.albumCollection.update(albumContainingSongId: songId, usingOldCollection: self.albumCollection)
        }
        let checkArtOp = NSBlockOperation {
            self.checkForArt(forSongId: songId, inAlbumCollection: self.albumCollection)
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

    func updateMetadata(forSongId songId: SongIDProtocol) {
        
        /// Check that the song doesn't already have metadata.
        guard let song = delegate?.getSong(songId) else { return }
        //        if SongPool.songForSongId(songId)?.metadata != nil { return }
        guard let metadata = SongCommonMetaData.loadedMetaDataForSongId(song) else { return }
        /// We need to handle the case where metadata already exists!
        delegate?.addSong(withChanges: [.Metadata : metadata], forSongId: songId)
        
        /// Let anyone listening know that we've updated the metadata for the songId.
        NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
    }
    
    func updateRemoteData(forSongId songId: SongIDProtocol, withDuration duration: NSNumber) {
        
        guard let song = delegate?.getSong(songId) else { return }
        guard let fingerprint = song.fingerPrint else { return }
        
        // If the song has not yet a uuid, get one.
        let uuid = song.UUId
        if uuid == nil {
            let durationInSeconds = UInt(duration.integerValue) //UInt(CMTimeGetSeconds(duration))
            if let acoustIdData = AcoustIDWebService.dataDict(forFingerprint: fingerprint, ofDuration: durationInSeconds),
                let songUUId = SongUUID.extractUUIDFromDictionary(acoustIdData),
                let bestRelease = AcoustIDWebService.bestMatchRelease(forSong: song, inDictionary: acoustIdData),
                let releaseId = bestRelease.objectForKey("id") {
                    delegate?.addSong(withChanges: [.RelId : releaseId, .UuId : songUUId], forSongId: songId)
            }
        }
    }
    
    func updateFingerPrint(forSongId songId: SongIDProtocol) {
        
        guard let song = delegate?.getSong(songId) else { return }
        
        // If there is no fingerprint, generate one sync'ly - this can be slow!
        if song.fingerPrint == nil,
            let urlString = song.urlString,
            let songUrl = NSURL(string : urlString),
            let (newFingerPrint, duration) = TGSongFingerprinter.fingerprint(forSongUrl: songUrl) {
                let metadata = SongCommonMetaData(duration: duration)
                
                delegate?.addSong(withChanges: [.Fingerprint : newFingerPrint, .Metadata : metadata], forSongId: songId)
        }
        
    }
    
    func checkForArt(forSongId songId: SongIDProtocol, inAlbumCollection collection: AlbumCollection) {
        guard let song = delegate?.getSong(songId) else { return }
        
        // Change artForSong to take a songId
        if song.artID == nil || SongArt.getArt(forArtId: song.artID!) == nil {
            if let image = SongArtFinder.findArtForSong(song, collection: collection) {
                
                let newArtId = SongArt.addImage(image)
                delegate?.addSong(withChanges: [.ArtId : newArtId], forSongId: songId)
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("songCoverUpdated", object: songId)
    }
}

/// Could have just set the AlbumCollection's delegate to our own but, for now,
/// let's see if any other requirements surface.
extension SongMetadataUpdater : AlbumCollectionDelegate {
    
    func getSong(songId : SongIDProtocol) -> TGSong? {
        return delegate?.getSong(songId)
    }
}