//
//  TGSong.swift
//  reDiscover
//
//  Created by Teo on 14/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

// TGSong protocol definition

import Foundation


@objc protocol TGSong {
    
    var songID: SongIDProtocol { get }
    var urlString: String? { get }
    var selectedSweetSpot: Float { get }
    var sweetSpots: [SweetSpot]? { get }
    var metadata: SongMetaData? { get }
    var artID: String? { get }
    var fingerPrint: String? { get }
    var songReleases: NSData? { get }
    var UUId: String? { get }
    
    init(songId: SongIDProtocol, metadata: SongMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
        fingerPrint: String?, selectedSS: SweetSpot, releases: NSData?, artId: String?, UUId: String?)
    
    //func isEqualTo(aSong: TGSong) -> Bool;
    //func copy()
}

class Song : NSObject,TGSong {
    
    let songID: SongIDProtocol
    let urlString: String?
    let selectedSweetSpot: Float
    let sweetSpots: [SweetSpot]?
    let metadata: SongMetaData?
    let artID: String?
    let fingerPrint: String?
    let songReleases: NSData?
    let UUId: String?
    
    required init(songId: SongIDProtocol, metadata: SongMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
        fingerPrint: String?, selectedSS: SweetSpot, releases: NSData?, artId: String?, UUId: String?) {
    
        self.songID              = songId
        self.urlString           = urlString
        self.selectedSweetSpot   = selectedSS
        self.sweetSpots          = sweetSpots
        self.metadata            = metadata
        self.artID               = artId
        self.fingerPrint         = fingerPrint
        self.songReleases        = releases
        self.UUId                = UUId
    }
    
//    func isEqualTo(aSong: TGSong) -> Bool {
//        return aSong.songID.isEqual(self.songID)
//    }
//    func copy() {
//        println("copy")
//    }
}