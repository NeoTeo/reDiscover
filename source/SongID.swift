//
//  SongId.swift
//  reDiscover
//
//  Created by Teo on 17/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

/**
The SongId is the type that identifies a song in the current instance of the application.
SongIds do not persist across instances.
*/
//public typealias SongId = Int

/** SongId has to be a class because some Cocoa methods take AnyObjects which have
    to be of a(ny) class type.
*/
public class SongId : Hashable {
    var idValue: Int
    
    init(string: String){
        idValue = string.hash
    }
    
    func isEqualToSongId(anId: SongId) -> Bool {
        return anId.idValue == self.idValue
    }
    
    // Override NSObject's isEqual, hash and description methods
//    override func isEqual(object: AnyObject?) -> Bool {
//        if self === object {
//            return true
//        }
//        else
//        {
//            if object?.isKindOfClass(SongId) == false {
//                return false
//            }
//            
//            return self.isEqualToSongId(object as! SongId)
//        }
//    }
    
    public var hashValue: Int {
        return idValue
    }
    
//    override var description: String {
//        return String(format: "idValue: <%ld>",idValue)
//    }
    
    // To comply with the NSCopying protocol
//    func copyWithZone(zone: NSZone) -> AnyObject {
////        let copy = SongId.allocWithZone(zone)
//        let copy = self.copy()
//        //copy.idValue = self.idValue
//        return copy
//  public   }
}

public func == (lhs: SongId, rhs: SongId) -> Bool {
    return lhs.idValue == rhs.idValue
}