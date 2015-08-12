//
//  SongID.swift
//  reDiscover
//
//  Created by Teo on 17/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

/**
The SongID is the type that identifies a song in the current instance of the application.
SongIDs do not persist across instances.
*/
@objc class SongID : NSObject, SongIDProtocol {
    var idValue: Int
    
    init(string: String){
        idValue = string.hash
    }
    
    func isEqualToSongID(anId: SongID) -> Bool {
        return anId.idValue == self.idValue
    }
    
    // Override NSObject's isEqual, hash and description methods
    override func isEqual(object: AnyObject?) -> Bool {
        if self === object {
            return true
        }
        else
        {
            if object?.isKindOfClass(SongID) == false {
                return false
            }
            
            return self.isEqualToSongID(object as! SongID)
        }
    }
    
    override var hash: Int {
        return idValue
    }
    
    override var description: String {
        return String(format: "idValue: <%ld>",idValue)
    }
    
    // To comply with the NSCopying protocol
    func copyWithZone(zone: NSZone) -> AnyObject {
//        let copy = SongID.allocWithZone(zone)
        let copy = self.copy()
        //copy.idValue = self.idValue
        return copy
    }
}