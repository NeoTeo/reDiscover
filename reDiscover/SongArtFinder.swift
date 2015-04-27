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
@objc class SongArtFinder {
    static func findArtForSong(song: TGSong, collection: AlbumCollection) -> NSImage? {
        // No existing artID. Try looking in the metadata.
        let arts = SongMetaData.getCoverArtForSong(song)
        if arts.count > 0 {
            // FIXME: For now just pick the first. We want this to be user selectable.
            return arts[0]
        }
        
        if let art = findArtForAlbum(forSong: song, inCollection: collection) {
            return art
        }
        
        if let urlString = song.urlString,
            let url = NSURL(string: urlString),
            let dirURL = url.filePathURL?.URLByDeletingLastPathComponent {
            LocalFileIO.imageURLsAtPath(dirURL)
        }
        return nil
    }
    
    /**
    Look at the other songs in the same album the given song belongs to see if they
    have art associated with them and return it if found.
    */
    static private func findArtForAlbum(forSong song: TGSong, inCollection collection: AlbumCollection) -> NSImage? {
        if let albumId = Album.albumIdForSong(song),
            let album = AlbumCollection.albumWithIdFromCollection(collection, albumId: albumId),
            let albumArt = AlbumCollection.artForAlbum(album, inCollection: collection){
                return albumArt
        }
        return nil
    }
    
}
