//
//  SongUUID.swift
//  reDiscover
//
//  Created by Teo on 07/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongData {
    
}

struct UUIDData : SongData {
    let uuid: String?
}


class SongUUID : NSObject {

//    static func getUUIDForSongId(songId: SongId) -> String? {
//        return SongPool.songForSongId(songId)?.UUId
//    }

    static func getUUIDForSong(song: TGSong) -> String? {
        return song.UUId
    }
    
    static func songWithNewUUId(song: TGSong, newUUId: String, newReleaseId: String?) -> TGSong {
        return Song(songId: song.songId, metadata: song.metadata, urlString: song.urlString,
            sweetSpots: song.sweetSpots, fingerPrint: song.fingerPrint, selectedSS: song.selectedSweetSpot,
            releases: song.songReleases, artId: song.artID, UUId: newUUId, RelId: newReleaseId)
    }
    
    class func extractUUIDFromDictionary(songDict: NSDictionary) -> String? {
        if let uuidString = songDict.objectForKey("id") as? String {
            return uuidString
        }
        return nil
    }    
}