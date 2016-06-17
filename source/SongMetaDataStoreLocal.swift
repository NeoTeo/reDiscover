//
//  SongMetaDataStoreLocal.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

class SongMetaDataStoreLocal : SongMetaDataStore {

    let allSongMetaData: [String : SongMetaData]
    
    init(metaData: [String : SongMetaData]) {
        allSongMetaData = metaData
    }
}

extension SongMetaDataStoreLocal {
    static func add(_ songMetaData: SongMetaData, songStore: SongMetaDataStore) -> SongMetaDataStore {
        
        var allSongs = songStore.allSongMetaData
        allSongs[songMetaData.generatedMetaData.URLString] = songMetaData
        
        return SongMetaDataStoreLocal(metaData: allSongs)
    }
    
    static func get(forSong theSong: Song, songStore: SongMetaDataStore) -> SongMetaData? {
        return nil
    }
    
    static func save(_ songStore: SongMetaDataStore) {
        
    }
    
    static func load() -> SongMetaDataStore? {
        return nil
    }
}
