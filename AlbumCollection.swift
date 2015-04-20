//
//  AlbumCollection.swift
//  reDiscover
//
//  Created by Teo on 20/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
class AlbumCollection {
    private static var albumCache = [String : Album]()
}

extension AlbumCollection {
    static func albumWithId(albumId: AlbumId) -> Album? {
        return albumCache[albumId]
//        if let album = albumCache[albumId] {
//            return Album(songIds: album.songIds)
//        }
//        return nil
    }
}