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
    static func add(songMetaData: SongMetaData, songStore: SongMetaDataStore) -> SongMetaDataStore {
        return SongMetaDataStoreLocal(metaData: [songMetaData.generatedMetaData.UUId : songMetaData])
    }
    
    static func get(forSong theSong: Song, songStore: SongMetaDataStore) -> SongMetaData? {
        return nil
    }
    
    static func save(songStore: SongMetaDataStore) {
        
    }
    
    static func load() -> SongMetaDataStore? {
        return nil
    }
}