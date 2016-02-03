//
//  SweetSpotController.swift
//  reDiscover
//
//  Created by Teo on 12/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SweetSpotControllerDelegate {
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongIDProtocol)
    func getSong(songId : SongIDProtocol) -> TGSong?
}

public typealias SweetSpot = NSNumber //Float
// The current implementation stores sweet spots in each song instance.
// To make songs immutable this means we need to make a new song from the old one
// every time we want to change any of its properties, including sweet spots.
// The methods of this class should act on songs and for those methods that modify
// a song (eg. add a new sweet spot) they should create and return a new song
// with the new sweetspot.
/**
    Perhaps it would be better if this class (which might as well be a struct since
    everything is static) kept a map of songIds to selected sweet spots. To avoid
    concurrency issues it would control access through a queue. The downside is 
    that storing it would be more work than if everything just resided in the song.
*/
public class SweetSpotController : NSObject {
    
    var delegate : SweetSpotControllerDelegate?
    
    /// Add, to the song pool, a new sweet spot to an existing song given by the songId.
    func addSweetSpot(atTime time: SweetSpot, forSongId songId: SongIDProtocol) {
        delegate?.addSong(withChanges: [.SelectedSS : time], forSongId: songId)
    }
    
    static func selectedSweetSpotForSong(song: TGSong) -> SweetSpot? {
        
        return song.selectedSweetSpot
        /// FIXME:
        // Add request to sweetSpotServerIO (once rewritten) to check the server at some appropriate interval for
        // sweet spots for this song. The server may receive them at any time.
        //return 0.0
    }

    func sweetSpots(forSongId songId: SongIDProtocol) -> Set<SweetSpot>? {
        
        guard let song = delegate?.getSong(songId) else { return nil }

        return song.sweetSpots
    }

    static func sweetSpots(forSong song: TGSong) -> Set<SweetSpot>? {
        return song.sweetSpots //as? [SweetSpot]
    }
/*
    static func songWithSweetSpots(sweetSpots: Set<SweetSpot>, forSong song: TGSong) -> TGSong {
        return Song(songId: song.songID, metadata: song.metadata, urlString: song.urlString, sweetSpots: sweetSpots, fingerPrint: song.fingerPrint, selectedSS: song.selectedSweetSpot, releases: song.songReleases, artId: song.artID, UUId: song.UUId, RelId: song.RelId)
    }
    
    /**
    Make a copy of the given song with a sweet spot set to the given time.
    
    - parameter song: The song to make a copy of.
    - parameter startTime: The time, in seconds, of the sweet spot.
    - returns: A copy of the given song with an added sweet spot at the given time.
    */
    static func songWithSelectedSweetSpot(song: TGSong, atTime startTime: SweetSpot) -> TGSong {
        return Song(songId: song.songID, metadata: song.metadata, urlString: song.urlString, sweetSpots: song.sweetSpots, fingerPrint: song.fingerPrint, selectedSS: startTime, releases: song.songReleases, artId: song.artID, UUId: song.UUId, RelId: song.RelId)
        
    }
*/
}