//
//  SweetSpotController.swift
//  reDiscover
//
//  Created by Teo on 12/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

typealias SweetSpot = NSNumber //Float
// The current implementation stores sweet spots in each song instance.
// To make songs immutable this means we need to make a new song from the old one
// every time we want to change any of its properties, including sweet spots.
// The methods of this class should act on songs and for those methods that modify
// a song (eg. add a new sweet spot) they should create and return a new song
// with the new sweetspot.
class SweetSpotController : NSObject {
    
    /// Add, to the song pool, a new sweet spot to an existing song given by the songId.
    static func addSweetSpot(atTime time: SweetSpot, forSongId songId: SongIDProtocol) {
        SongPool.addSong(withChanges: [.SelectedSS : time], forSongId: songId)
    }
    
    static func selectedSweetSpotForSong(song: TGSong) -> SweetSpot? {
        
        return song.selectedSweetSpot
        // Add request to sweetSpotServerIO (once rewritten) to check the server at some appropriate interval for
        // sweet spots for this song. The server may receive them at any time.
        //return 0.0
    }

    static func sweetSpots(forSongId songId: SongIDProtocol) -> Set<SweetSpot>? {
        
        guard let song = SongPool.songForSongId(songId) else { return nil }

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