//
//  SongMetadataUpdater.swift
//  reDiscover
//
//  Created by teo on 03/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongMetadataUpdaterDelegate {
    func getSong(songId : SongId) -> TGSong?
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
	func sendSweetSpotsRequest(songId : SongId)
	func isCached(songId : SongId) -> Bool
}

public class SongMetadataUpdater {

    var delegate : SongMetadataUpdaterDelegate?
	
	/// The songUpdateTracker tracks when a song has last been updated.
	private var songUpdateTracker: SongMetadataUpdateTracker = TGSongMetadataUpdateTracker()

	/// An operation queue for udating the cache as a whole. Used by the cacher.
	private let songCacheDataUpdaterOpQ = NSOperationQueue()
	
    private let songDataUpdaterOpQ = NSOperationQueue()
    private var albumCollection = AlbumCollection()
	
    init(delegate : SongMetadataUpdaterDelegate) {
        self.delegate = delegate
        albumCollection.delegate = self

		/// Make the two operations queues effectively serial.
		songCacheDataUpdaterOpQ.maxConcurrentOperationCount = 1
		songCacheDataUpdaterOpQ.qualityOfService = .UserInitiated
		
		songDataUpdaterOpQ.maxConcurrentOperationCount = 1
		songDataUpdaterOpQ.qualityOfService = .UserInitiated

    }
	
	
	func requestUpdatedData(cachedSongIds : [SongId]) {
		
		/// Clear the previous cache request
		songCacheDataUpdaterOpQ.cancelAllOperations()
		
		for songId in cachedSongIds {

			/// Skip if below minimum interval or not cached.
			guard songUpdateTracker.secondsSinceUpdate(songId) >= songUpdateTracker.minUpdateInterval else { continue }
			guard delegate?.isCached(songId) != nil else { continue }
			
			runMetadataUpdate(songDataUpdaterOpQ, songId: songId)
			songUpdateTracker.markUpdate(songId)
		}
		
	}
    /** Set up a chain of operations each dependent on the previous that update
     various data associated with a song;
     1) Loading its embedded file metadata,
     2) Generating an acoustic fingerprint of the song's audio,
     3) Looking up additional data such as an UUID using the fingerprint,
     4) Maintaining and updating the local album collection data.
     5) Looking for cover art in a large variety of places (including a web service).
     */
    func requestUpdatedData(forSongId songId: SongId) {
		
		guard delegate?.isCached(songId) != nil else {
			print("Cannot request metadata for a song (id \(songId.hashValue)) which has not yet been cached")
			return
		}
		print("requestUpdatedData ALL GOOD")
        /// Let any interested parties know we've started updating the current song.
        NSNotificationCenter.defaultCenter().postNotificationName("songDidStartUpdating", object: songId)
        
		
        // Override all previous ops by cancelling them and adding the new one.
        songDataUpdaterOpQ.cancelAllOperations()
		
		runMetadataUpdate(songDataUpdaterOpQ, songId: songId)
        
    }
	
	func runMetadataUpdate(opQueue : NSOperationQueue, songId : SongId) {
		
		/// All the calls inside the blocks are synchronous.
		let updateMetadataOp = NSBlockOperation {
			self.updateMetadata(forSongId: songId)
			
			/// At this point we can signal that the metadata is up to date
			NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
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
			//            SweetSpotServerIO.requestSweetSpotsForSongID(songId)
			/// Initiate a request for sweet spots from the remote server.
			self.delegate?.sendSweetSpotsRequest(songId)
		}
		
		/// Make operations dependent on each other.
		fingerPrinterOp.addDependency(updateMetadataOp)
		remoteDataOp.addDependency(fingerPrinterOp)
		
		/// The sweetspot fetcher and album op depend on the fingerprint and the UUID.
		fetchSweetspotsOp.addDependency(remoteDataOp)
		updateAlbumOp.addDependency(remoteDataOp)
		
		checkArtOp.addDependency(updateAlbumOp)
		
		
		/// Add the ops to the queue.
		opQueue.addOperations([  updateMetadataOp,
			fingerPrinterOp,
			remoteDataOp,
			updateAlbumOp,
			checkArtOp,
			fetchSweetspotsOp], waitUntilFinished: false)
		
	}

    func updateMetadata(forSongId songId: SongId) {
		
        guard let song = delegate?.getSong(songId) else { return }
		
        /// Don't re-fetch the song common metadata if we already have it.
        if song.metadata != nil {
            print("updateMetadata already had metadata \(song.metadata?.artist)")
            print(song.metadata?.title)
            print(song.metadata?.album)
            return }
        
        guard let metadata = SongCommonMetaData.loadedMetaDataForSongId(song) else { return }

        delegate?.addSong(withChanges: [.Metadata : metadata], forSongId: songId)
        
        /// Let anyone listening know that we've updated the metadata for the songId.
//        NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
        /// Moved to the caller of this method.
    }
    
    func updateRemoteData(forSongId songId: SongId, withDuration duration: NSNumber) {
        
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
    
    func updateFingerPrint(forSongId songId: SongId) {
        
        guard let song = delegate?.getSong(songId) else { return }
        
        // If there is no fingerprint, generate one sync'ly - this can be slow!
        if song.fingerPrint == nil,
            let urlString = song.urlString,
            let songUrl = NSURL(string : urlString),
            let (newFingerPrint, duration) = TGSongFingerprinter.fingerprint(forSongUrl: songUrl) {
                
                /// Merge the duration into any existing metadata
                
                var metadata = song.metadata
                if let md = metadata {
                    metadata = SongCommonMetaData(  title: md.title,
                                                    album: md.album,
                                                    artist: md.artist,
                                                    year: md.year,
                                                    genre: md.genre,
                                                    duration: duration)
                } else {
                    metadata = SongCommonMetaData(duration: duration)
                }
                
                delegate?.addSong(withChanges: [.Fingerprint : newFingerPrint, .Metadata : metadata!], forSongId: songId)
                
                NSNotificationCenter.defaultCenter().postNotificationName("songMetaDataUpdated", object: songId)
        }
        
    }
    
    func checkForArt(forSongId songId: SongId, inAlbumCollection collection: AlbumCollection) {
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
    
    func getSong(songId : SongId) -> TGSong? {
        return delegate?.getSong(songId)
    }
}