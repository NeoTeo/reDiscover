//
//  TGSongFingerprinter.swift
//  reDiscover
//
//  Created by Teo on 15/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

struct TGSongFingerprinter : SongFingerprinter {

    static func fingerprint(forSongUrl songUrl: NSURL) -> String? {

        guard let (fingerprintString, duration) = generateFingerprint(fromSongAtUrl: songUrl) else {
            print("Error generating fingerprint")
            return nil
        }
        
        print("The song duration is \(duration). Use this instead of getting duration from SongPlayer!")
        return fingerprintString
    }

}