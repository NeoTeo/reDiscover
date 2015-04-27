//
//  AlbumCollection.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
class AlbumCollection : NSObject {
    let albumCache: [AlbumId : Album]
    
    override init() {
        albumCache = [AlbumId : Album]()
    }
    
    init(albums: [AlbumId : Album]) {
        albumCache = albums
    }
}

extension AlbumCollection {
    class func albumWithIdFromCollection(collection: AlbumCollection, albumId: AlbumId) -> Album? {
        return collection.albumCache[albumId]
//        if let album = albumCache[albumId] {
//            return Album(songIds: album.songIds)
//        }
//        return nil
    }
    
    class func collectionWithAddedAlbum(collection: AlbumCollection, album: Album) -> AlbumCollection {
        var tmpCache = collection.albumCache
        tmpCache[album.id] = album
        return AlbumCollection(albums: tmpCache)
    }
    
    class func artForAlbum(album: Album, inCollection: AlbumCollection) -> NSImage? {
        let songIds = album.songIds.allObjects
        var albumArts = [NSImage?]()
        
        for songId in songIds as! [SongIDProtocol] {
            if let song = SongPool.songForSongId(songId),
                let songArt = SongArt.artForSong(song) {
                  //FIXME: For now just return any song art we find
                    return songArt
            }
            
        }
        return nil
    }
}