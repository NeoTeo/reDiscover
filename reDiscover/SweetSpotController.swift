//
//  SweetSpotController.swift
//  reDiscover
//
//  Created by Teo on 12/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation


// The current implementation stores sweet spots in each song instance.
// To make songs immutable this means we need to make a new song from the old one
// every time we want to change any of its properties, including sweet spots.
// The methods of this class should act on songs and for those methods that modify
// a song (eg. add a new sweet spot) they should create and return a new song
// with the new sweetspot.
class SweetSpotControl : NSObject {
    
    static func currentSweetSpotForSong(song: TGSongProtocol) -> Float {
        // Swift doesn't know what is inside the NSNumber, so we tell it.
        if let sss = song.selectedSweetSpot {
            return Float(sss);
        }
        return 0.0
    }
    
    // Used to be makeSweetSpotAtTime:
    /**
    Make a copy of the given song with a sweet spot set to the given time.
    
    :param: song The song to make a copy of.
    :param: startTime The time, in seconds, of the sweet spot.
    :returns: A copy of the given song with an added sweet spot at the given time.
    */
    static func songWithSweetSpot(song: TGSongProtocol, atTime startTime: Float) -> TGSongProtocol {
        // Make a new song where the given sweet spot (time) has been included.
        // Since we want to end up with a song being immutable, the way to make a
        // song with new properties is to call its constructor.
//        let songDuration = song.songDuration
        var newSong = song.copy() as! TGSongProtocol
        newSong.selectedSweetSpot = startTime
        return newSong
        //return SweetSpotControl.songWithSweetSpot(song, startTime)
    }
    
}