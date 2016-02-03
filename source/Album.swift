//
//  Album.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

// An album is a set of song ids.
// We'd like to define it as such, but the SongId, by necessity,
// needs to be defined as an Obj-C protocol. Since Obj-C protocols cannot inherit
// the Swift Hashable protocol it cannot be used as a type in a Swift Set or
// Dictionary.
typealias AlbumId = String

class Album : NSObject {
    
    let id: AlbumId
    var songIds: Set<SongId>
    
    init(albumId: AlbumId, songIds: Set<SongId>){
        id = albumId
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
    Returns a new album formed by adding a given song to the given album.
    */
    static func albumWithAddedSong(song: TGSong,oldAlbum: Album) -> Album {
        if let aId = Album.albumIdForSong(song) {
            /// FIXME : This mutates and probably shouldn't
            var newSongIds = oldAlbum.songIds
            newSongIds.insert(song.songId)
            return Album(albumId: aId, songIds: newSongIds )
        }
        print("Album.albumWithAddedSong returned the old album without changes.")
        return oldAlbum
    }
}