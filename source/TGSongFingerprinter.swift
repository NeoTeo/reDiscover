//
//  TGSongFingerprinter.swift
//  reDiscover
//
//  Created by Teo on 15/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

struct TGSongFingerprinter : SongFingerprinter {

//    static func fingerprint(forSongUrl songUrl: NSURL) -> String? {
    static func fingerprint(forSongUrl songUrl: NSURL) -> (String, Double)? {
        
        guard let (fingerprintString, duration) = generateFingerprint(fromSongAtUrl: songUrl) else {
            print("Error generating fingerprint")
            return nil
        }
        
        return (fingerprintString, duration)
    }

}