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
    let selectedSweetSpot: Float
    let sweetSpots: [SweetSpot]?
    let metadata: SongCommonMetaData?
    let artID: String?
    let fingerPrint: String?
    let songReleases: NSData?
    let UUId: String?
    let RelId: String?
    
    required init(songId: SongIDProtocol, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
        fingerPrint: String?, selectedSS: SweetSpot, releases: NSData?, artId: String?, UUId: String?, RelId: String?) {
            
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