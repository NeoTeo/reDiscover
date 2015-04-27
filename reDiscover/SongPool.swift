//
//  SongPool.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

class SongPool : NSObject {
    
    static var delegate: SongPoolAccessProtocol?
    
    // Until we've switched TGSongPool over to this class we'll use it as a delegate.
    // In this case we request the song for the given id and return a copy of it.
    class func songForSongId(songId: SongIDProtocol) -> TGSong? {
        if let song = delegate?.songForID(songId) {
            
            return Song(songId: song.songID,
                metadata: song.metadata,
                urlString: song.urlString,
                sweetSpots: song.sweetSpots,
                fingerPrint: song.fingerPrint,
                selectedSS: song.selectedSweetSpot,
                releases: song.songReleases,
                artId: song.artID,
                UUId: song.UUId)
        }
        return nil
    }
}