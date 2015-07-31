//
//  Song.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation


class Song : NSObject,TGSong {
    
    let songID: SongIDProtocol
    let urlString: String?
    let selectedSweetSpot: NSNumber? //Float
    let sweetSpots: [SweetSpot]?
    let metadata: SongCommonMetaData?
    let artID: String?
    let fingerPrint: String?
    let songReleases: NSData?
    let UUId: String?
    let RelId: String?
    
    required init(songId: SongIDProtocol, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
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
    //    func copy() {
    //        println("copy")
    //    }
}

extension Song {

    static func songWithChanges(theSong: TGSong, changes: [String : AnyObject]) -> TGSong {
        var songId = theSong.songID
        var metadata = theSong.metadata
        var urlString = theSong.urlString
        var sweetspots = theSong.sweetSpots
        var fingerprint = theSong.fingerPrint
        var selectedSS = theSong.selectedSweetSpot
        var releases = theSong.songReleases
        var artId = theSong.artID
        var uuid = theSong.UUId
        var relid = theSong.RelId
        
        for (change, obj) in changes {
            switch change {
            case "songId":
                songId = obj as! SongIDProtocol
            case "metadata":
                metadata = obj as? SongCommonMetaData
            case "urlString":
                urlString = obj as? String
            case "sweetSpots":
                sweetspots = obj as? [SweetSpot]
            case "fingerPrint":
                fingerprint = obj as? String
            case "selectedSS":
                selectedSS = obj as? SweetSpot
            case "releases":
                releases = obj as? NSData
            case "artId":
                artId = obj as? String
            case "UUId":
                uuid = obj as? String
            case "RelId":
                relid = obj as? String
            default:
                print("Unknown value in songWithChanges")
            }
        }
        
        return Song(songId: songId, metadata: metadata, urlString: urlString, sweetSpots: sweetspots, fingerPrint: fingerprint, selectedSS: selectedSS, releases: releases, artId: artId, UUId: uuid, RelId: relid)
    }
}