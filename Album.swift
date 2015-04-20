//
//  Album.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

// An album is a set of song ids.
// We'd like to define it as such, but the SongIDProtocol, by necessity,
// needs to be defined as an Obj-C protocol. Since Obj-C protocols cannot inherit
// the Swift Hashable protocol it cannot be used as a type in a Swift Set or
// Dictionary.
// One solution could have been to make the SongAlbums an Obj-C class.
// In the end I've opted to stick with Swift since I'd like to move as much of the project to it as possible.
//typealias Album = Set<TGSong> // no go since TGSong, an Obj-C protocol, cannot adopt Hashable.
//typealias Album = NSSet
typealias AlbumId = String

class Album : NSObject {
    
    let songIds: NSSet
    
    init(songIds: NSSet){
        self.songIds = songIds
    }
}

extension Album {
    
    static func albumIdForSong(song: TGSong) -> AlbumId? {
        if let artist = song.metadata?.artist,let album = song.metadata?.album {
            
            return Hasher.hashFromString(album+artist)
        }
        return nil
    }
 
    /**
    Returns a new album 
    */
    static func albumWithAddedSong(song: TGSong,oldAlbum: Album) -> Album {
        return Album(songIds: oldAlbum.songIds.setByAddingObject(song.songID))
    }
}