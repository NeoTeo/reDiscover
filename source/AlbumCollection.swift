//
//  AlbumCollection.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

protocol AlbumCollectionDelegate {
    func getSong(songId : SongIDProtocol) -> TGSong?
}


public final class AlbumCollection : NSObject {
    let albumCache: [AlbumId : Album]
    
    var delegate : AlbumCollectionDelegate?
    
    override init() {
        albumCache = [AlbumId : Album]()
    }
    
    init(albums: [AlbumId : Album]) {
        albumCache = albums
    }
}

extension AlbumCollection {
    
    func albumWithIdFromCollection(collection: AlbumCollection, albumId: AlbumId) -> Album? {
        return collection.albumCache[albumId]
//        if let album = albumCache[albumId] {
//            return Album(songIds: album.songIds)
//        }
//        return nil
    }
    
    func update(albumContainingSongId songId: SongIDProtocol, usingOldCollection albums: AlbumCollection) -> AlbumCollection {

        /// Only make a new album if we have a valid song and albumId
        if let song = delegate?.getSong(songId),
            let albumId = Album.albumIdForSong(song) {
                
                /// Check if we already have an album with the given id in the given collection
                var album = albums.albumWithIdFromCollection(albums, albumId: albumId)
                
                /// If an album was found make a copy of it with the song added to
                /// it, otherwise make a new album.
                if album == nil {
                    album = Album(albumId: albumId, songIds: Set(arrayLiteral: songId as! SongID))
                } else {
                    album = Album.albumWithAddedSong(song, oldAlbum: album!)
                }
                
                // return a copy of the old collection with the new updated album added.
                return collectionWithAddedAlbum(albums, album: album!)
        }
        
        /// No change, just return the old album collection.
        return albums
    }
    
    func collectionWithAddedAlbum(collection: AlbumCollection, album: Album) -> AlbumCollection {
        var tmpCache = collection.albumCache
        tmpCache[album.id] = album
        return AlbumCollection(albums: tmpCache)
    }
    
    func artForAlbum(album: Album, inCollection: AlbumCollection) -> NSImage? {
        let songIds = album.songIds.allObjects
//        var albumArts = [NSImage?]()
        
        for songId in songIds as! [SongIDProtocol] {
            if let song = delegate?.getSong(songId),
                let artId = song.artID,
                let songArt = SongArt.getArt(forArtId: artId) {
                  //FIXME: For now just return any song art we find
                    return songArt
            }
            
        }
        return nil
    }
}