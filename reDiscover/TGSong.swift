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
    var metadata: SongCommonMetaData? { get }
    var artID: String? { get }
    var fingerPrint: String? { get }
    var songReleases: NSData? { get }
    var UUId: String? { get }
    var RelId: String? { get }
    
    init(songId: SongIDProtocol, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: [SweetSpot]?,
        fingerPrint: String?, selectedSS: SweetSpot, releases: NSData?, artId: String?, UUId: String?, RelId: String?)
    
    //func isEqualTo(aSong: TGSong) -> Bool;
    //func copy()
}

