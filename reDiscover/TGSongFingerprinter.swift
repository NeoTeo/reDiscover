//
//  TGSongFingerprinter.swift
//  reDiscover
//
//  Created by Teo on 15/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

struct TGSongFingerprinter : SongFingerprinter {
    static func fingerprint(forSongId songId: SongIDProtocol) -> String? {
        
        guard let songUrl = SongPool.URLForSongId(songId) else {
            print("Error converting Song Id to song Url")
            return nil
        }
        guard let (fingerprintString, duration) = generateFingerprint(fromSongAtUrl: songUrl) else {
            print("Error generating fingerprint")
            return nil
        }
        print("The song duration is \(duration)")
        return fingerprintString
    }

}