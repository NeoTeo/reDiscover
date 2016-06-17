//
//  SweetSpotController.swift
//  reDiscover
//
//  Created by Teo on 12/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SweetSpotControllerDelegate {
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
    func getSong(_ songId : SongId) -> TGSong?
}

protocol SweetSpotControllerLocalStoreDelegate {
	
	func storeUploadedSweetSpotsDictionary()
	func markSweetSpotAsUploaded(_ uuid : String, sweetSpot : SweetSpot)
	func sweetSpotHasBeenUploaded(_ theSS: Double, song : TGSong) -> Bool

}

public typealias SweetSpot = NSNumber //Float

/**
	The current implementation stores sweet spots in each song instance.
	To make songs immutable this means we need to make a new song from the old one
	every time we want to change any of its properties, including sweet spots.
	The methods of this class should act on songs and for those methods that modify
	a song (eg. add a new sweet spot) they should create and return a new song
	with the new sweetspot.
*/
public class SweetSpotController : NSObject {
    
    var delegate : SweetSpotControllerDelegate?
	var storeDelegate : SweetSpotControllerLocalStoreDelegate = TGSweetSpotLocalStore()
	
	let sweetSpotServerIO = SweetSpotServerIO()
	
	override init() {
		super.init()
		
		sweetSpotServerIO.delegate = self
	}
	
    /// Set the song's selected sweet spot to the given time.
    func addSweetSpot(atTime time: SweetSpot, forSongId songId: SongId) {
        delegate?.addSong(withChanges: [.selectedSS : time], forSongId: songId)
    }
    
    static func selectedSweetSpotForSong(_ song: TGSong) -> SweetSpot? {
        
        return song.selectedSweetSpot
        /// FIXME:
        // Add request to sweetSpotServerIO (once rewritten) to check the server at some appropriate interval for
        // sweet spots for this song. The server may receive them at any time.
        //return 0.0
    }

    func sweetSpots(forSongId songId: SongId) -> Set<SweetSpot>? {
        
        guard let song = delegate?.getSong(songId) else { return nil }

        return song.sweetSpots
    }

    func sweetSpots(forSong song: TGSong) -> Set<SweetSpot>? {
        return song.sweetSpots //as? [SweetSpot]
    }
	
	func uploadSweetSpots(_ songId : SongId) {
		
		guard let song = delegate?.getSong(songId) else { return }
		
		//sweetSpotServerIO.delegate = self
		let _ = sweetSpotServerIO.uploadSweetSpots(song)
	}
	
	/**
		Initiate a request for sweet spots for the song with the given song id.
		Will post a SweetSpotsUpdated notification when done.
	*/
	func requestSweetSpots(_ songId : SongId) {
		let _ = sweetSpotServerIO.requestSweetSpotsForSongID(songId)
	}
	
	/**
		Promotes the currently selected sweet spot to the sweet spot set so that 
		it can be uploaded and saved.
	*/
	func promoteSelectedSweetSpot(_ songId : SongId) {

		guard let song		 = delegate?.getSong(songId) else { return }
		guard let selectedSS = song.selectedSweetSpot else { return }

		/// Insert into existing sweetspots if there otherwise make new set.
		var newSweetSpots = song.sweetSpots ?? Set<SweetSpot>()
		newSweetSpots.insert(selectedSS)
		
		/// Update the song in the song pool with the changed sweet spots.
		delegate?.addSong(withChanges: [.sweetSpots : newSweetSpots], forSongId: songId)
	}
	
	func storeSweetSpots() {

		/// Access the delegate's type method via dynamicType.
		/// FIXME: Decide on the advantage of this over an instance method.
		/** 
			This just stores the list of sweet spots we already have uploaded to
			the server.
		*/
		storeDelegate.storeUploadedSweetSpotsDictionary()
	}
}

extension SweetSpotController : SweetSpotServerIODelegate {
	
	func getSong(_ songId : SongId) -> TGSong? {
		return delegate?.getSong(songId)
	}
	
	func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId) {
		delegate?.addSong(withChanges: changes, forSongId: songId)
	}
	
	func sweetSpotHasBeenUploaded(_ theSS: Double, song : TGSong) -> Bool {
		return storeDelegate.sweetSpotHasBeenUploaded(theSS, song: song)
	}
	
	func markSweetSpotAsUploaded(_ uuid : String, sweetSpot : SweetSpot) {
		storeDelegate.markSweetSpotAsUploaded(uuid, sweetSpot: sweetSpot)
	}
}
