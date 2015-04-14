//
//  SweetSpotController.swift
//  reDiscover
//
//  Created by Teo on 12/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

typealias SweetSpot = Float
// The current implementation stores sweet spots in each song instance.
// To make songs immutable this means we need to make a new song from the old one
// every time we want to change any of its properties, including sweet spots.
// The methods of this class should act on songs and for those methods that modify
// a song (eg. add a new sweet spot) they should create and return a new song
// with the new sweetspot.
class SweetSpotControl : NSObject {
    
    static func selectedSweetSpotForSong(song: TGSong) -> Float {
        // Swift doesn't know what is inside the NSNumber, so we tell it.
        if let sss = song.selectedSweetSpot {
            return Float(sss);
        }
        // Add request to sweetSpotServerIO (once rewritten) to check the server at some appropriate interval for
        // sweet spots for this song. The server may receive them at any time.
        return 0.0
    }
    
    static func sweetSpotsForSong(song: TGSong) -> [SweetSpot]? {
        return song.sweetSpots as? [SweetSpot]
    }
    
    // Used to be makeSweetSpotAtTime:
    /**
    Make a copy of the given song with a sweet spot set to the given time.
    
    :param: song The song to make a copy of.
    :param: startTime The time, in seconds, of the sweet spot.
    :returns: A copy of the given song with an added sweet spot at the given time.
    */
    static func songWithSelectedSweetSpot(song: TGSong, atTime startTime: SweetSpot) -> TGSong {
        var newSong = song.copy() as! TGSong
        newSong.selectedSweetSpot = startTime
        return newSong
    }
    
    // replacement for TGSong storeSelectedSweetSpot
    static func songWithAddedSweetSpot(song: TGSong, withSweetSpot sweetSpot: SweetSpot) -> TGSong {
        var newSong = song.copy() as! TGSong
        var tmpSpots = SweetSpotControl.sweetSpotsForSong(song)
        tmpSpots?.append(sweetSpot)
        newSong.sweetSpots = tmpSpots
        return newSong
    }
}