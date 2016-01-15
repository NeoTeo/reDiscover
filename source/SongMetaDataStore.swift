//
//  SongMetaDataStore.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation


/**
The Song metadata store is where we save the metadata we have fetched, constructed or
accepted from the user.
*/
protocol SongMetaDataStore {
    
    var allSongMetaData: [String : SongMetaData] { get }
    
    static func add(songMetaData: SongMetaData, songStore: SongMetaDataStore) -> SongMetaDataStore
    static func save(songStore: SongMetaDataStore)
    static func load() -> SongMetaDataStore?
}