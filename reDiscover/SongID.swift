//
//  SongID.swift
//  reDiscover
//
//  Created by teo on 17/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation

@objc
class SongID {
    let idValue: Int?
    
    init(URL: String) {
        idValue = URL.hashValue
    }
    
    // Alas we can't use this in reDiscover because Obj-c doesn't allow generics.
    //    func isEqual<T>(thing: T) -> Bool {
    //
    //        switch thing {
    //            case let someID as SongID:
    //                return someID.idValue == idValue
    //
    //            case let anIDString as String:
    //                return anIDString.hashValue == idValue
    //
    //            default:
    //                return false
    //        }
    //    }
    
    func isEqualToString(urlString: String) -> Bool {
        return idValue == urlString.hashValue
    }
    
    func isEqualToSongID(songID: SongID) -> Bool {
        return songID.idValue == idValue
    }
}
