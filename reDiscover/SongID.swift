//
//  SongID.swift
//  reDiscover
//
//  Created by teo on 17/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation


/*
@objc
protocol SongIDProtocol : NSObject {
//    func isEqualToSongID(object: SongIDProtocol!) -> Bool
}

@objc
class SongID : NSObject, SongIDProtocol {
    var idValue: Int?
    
    init(string: String) {
        idValue = string.hashValue
        println("The idValue is \(idValue)")
    }
    
    // Alas we can't use this in reDiscover because Obj-c doesn't allow generics.
    //    func isEqual<T: Equatable>(thing: T) -> Bool {
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
    
    // Currently global functions are not available on the Obj-C side :(
    func == (lhs: SongID, rhs: SongID) -> Bool {
    println("Comparing...")
    return lhs.idValue == rhs.idValue
    }
    
//    func isEqualToSongID(object: SongIDProtocol!) -> Bool {
//        let otherSong = object as SongID
//        return idValue == otherSong.idValue
//    }
}


// And neither are structs
//@objc
//struct ^re {
//    
//}
*/