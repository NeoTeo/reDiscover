//
//  Song.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation


class Song : NSObject, TGSong {
    
    let songId: SongId
    let urlString: String?
    let selectedSweetSpot: NSNumber? //Float
    let sweetSpots: Set<SweetSpot>?
    let metadata: SongCommonMetaData?
    let artID: String?
    let fingerPrint: String?
    let songReleases: Data?
    let UUId: String?
    let RelId: String?
    
    required init(songId: SongId, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: Set<SweetSpot>?,
        fingerPrint: String?, selectedSS: SweetSpot?, releases: Data?, artId: String?, UUId: String?, RelId: String?) {
            
            self.songId              = songId
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
}

public enum SongProperty: Hashable {
    case id
    case metadata
    case urlString
    case sweetSpots
    case fingerprint
    case selectedSS
    case releases
    case artId
    case uuId
    case relId
}

extension Song {
    
    static func songWithChanges(_ theSong: TGSong, changes: [SongProperty : AnyObject]) -> TGSong {
        
        var songId      = theSong.songId
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
            case .id:
                songId = obj as! SongId
            case .metadata:
                metadata = obj as? SongCommonMetaData
            case .urlString:
                urlString = obj as? String
            case .sweetSpots:
                sweetspots = obj as? Set<SweetSpot>
            case .fingerprint:
                fingerprint = obj as? String
            case .selectedSS:
                selectedSS = obj as? SweetSpot
            case .releases:
                releases = obj as? Data
            case .artId:
                artId = obj as? String
            case .uuId:
                uuid = obj as? String
            case .relId:
                relid = obj as? String
            }
        }
        
        return Song(songId: songId,
                            metadata: metadata,
                            urlString: urlString,
                            sweetSpots: sweetspots,
                            fingerPrint: fingerprint,
                            selectedSS: selectedSS,
                            releases: releases,
                            artId: artId,
                            UUId: uuid,
                            RelId: relid)
    }
    
    
    func duration() -> NSNumber? {
        
        guard let dur = metadata?.duration else { return nil }
        
        return NSNumber(value: dur)
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
