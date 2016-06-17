//
//  TGSong.swift
//  reDiscover
//
//  Created by Teo on 14/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

// TGSong protocol definition

import Foundation


public protocol TGSong {
    
    var songId: SongId { get }
    var urlString: String? { get }
    var selectedSweetSpot: NSNumber? { get }
    var sweetSpots: Set<SweetSpot>? { get }
    var metadata: SongCommonMetaData? { get }
    var artID: String? { get }
    var fingerPrint: String? { get }
    var songReleases: Data? { get }
    var UUId: String? { get }
    var RelId: String? { get }
    
    init(songId: SongId, metadata: SongCommonMetaData?, urlString: String?, sweetSpots: Set<SweetSpot>?,
        fingerPrint: String?, selectedSS: SweetSpot?, releases: Data?, artId: String?, UUId: String?, RelId: String?)
    
    func metadataDict() -> NSDictionary
    
    /// Convenience methods
    func duration() -> NSNumber?
}

