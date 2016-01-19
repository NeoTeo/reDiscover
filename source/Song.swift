//
//  Song.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation


class Song : NSObject, TGSong {
    
    let songID: SongIDProtocol
    let urlString: String?
    let selectedSweetSpot: NSNumber? //Float
//    let sweetSpots: [SweetSpot]?
    let sweetSpots: Set<SweetSpot>?
    let metadata: SongCommonMetaData?
    let artID: String?
    let fingerPrint: String?
    let songReleases: NSData?
    let UUId: String?
    let RelId: String?
    
//    required init(songId: SongIDProtocol, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
    required init(songId: SongIDProtocol, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: Set<SweetSpot>?,
        fingerPrint: String?, selectedSS: SweetSpot?, releases: NSData?, artId: String?, UUId: String?, RelId: String?) {
            
            self.songID              = songId
            self.urlString           = urlString
            self.selectedSweetSpot   = selectedSS
            self.sweetSpots          = sweetSpots
            self.metadata            = metadata
            self.artID               = artId
            self.fingerPrint         = fingerPrint
            self.songReleases        = releases
            self.UUId                = UUId
            self.RelId               = RelId
    }
    
    //    func isEqualTo(aSong: TGSong) -> Bool {
    //        return aSong.songID.isEqual(self.songID)
    //    }
}

public enum SongProperty: Hashable {
    case Id
    case Metadata
    case UrlString
    case SweetSpots
    case Fingerprint
    case SelectedSS
    case Releases
    case ArtId
    case UuId
    case RelId
}

extension Song {
    
    static func songWithChanges(theSong: TGSong, changes: [SongProperty : AnyObject]) -> TGSong {
        
        var songId      = theSong.songID
        var metadata    = theSong.metadata
        var urlString   = theSong.urlString
        var sweetspots  = theSong.sweetSpots
        var fingerprint = theSong.fingerPrint
        var selectedSS  = theSong.selectedSweetSpot
        var releases    = theSong.songReleases
        var artId       = theSong.artID
        var uuid        = theSong.UUId
        var relid       = theSong.RelId
        
        for (change, obj) in changes {
            switch change {
            case .Id:
                songId = obj as! SongIDProtocol
            case .Metadata:
                metadata = obj as? SongCommonMetaData
            case .UrlString:
                urlString = obj as? String
            case .SweetSpots:
                sweetspots = obj as? Set<SweetSpot>
            case .Fingerprint:
                fingerprint = obj as? String
            case .SelectedSS:
                selectedSS = obj as? SweetSpot
            case .Releases:
                releases = obj as? NSData
            case .ArtId:
                artId = obj as? String
            case .UuId:
                uuid = obj as? String
            case .RelId:
                relid = obj as? String
            }
        }
        
        return Song(songId: songId, metadata: metadata, urlString: urlString, sweetSpots: sweetspots, fingerPrint: fingerprint, selectedSS: selectedSS, releases: releases, artId: artId, UUId: uuid, RelId: relid)
    }
    
    func metadataDict() -> NSDictionary {
        guard let md = metadata else { return [:] }
        return [    "Artist" : md.artist,
                    "Title" : md.title,
                    "Album" : md.album,
                    "Genre" : md.genre
        ]
    }
}