//
//  SongFingerprinter.swift
//  reDiscover
//
//  Created by Teo on 15/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongFingerprinter {
//    static func fingerprint(forSongUrl songUrl: NSURL) -> String?
        static func fingerprint(forSongUrl songUrl: NSURL) -> (String, Double)?
}