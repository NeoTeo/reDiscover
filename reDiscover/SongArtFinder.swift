//
//  SongArtFinder.swift
//  reDiscover
//
//  Created by Teo on 11/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

/**
The SongArtFinder tries to find the artwork for a given song using a variety of 
different ways.
1) Looks in the metadata via the SongMetaData class.
2) 
*/
struct SongArtFinder {
    static func findArtForSong(song: TGSongProtocol) -> NSImage? {
        // No existing artID. Try looking in the metadata.
        let arts = SongMetaData.getCoverArtForSong(song)
        if arts.count > 0 {
            // FIXME: For now just pick the first. We want this to be user selectable.
            return arts[0]
        }
        
        return nil
    }
}
