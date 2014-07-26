//
//  SongPlayer2.swift
//  reDiscover
//
//  Created by Matteo Sartori on 24/07/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

//protocol MyBridge : Hashable {
//    func isEqual(object: MyBridge) -> Bool
//}
//
//@infix func == <T: MyBridge>(lhs: T, rhs: T) -> Bool {
//    return lhs == rhs
//}

//struct myThing : MyBridge {
//    
//    func isEqual(object: MyBridge) -> Bool {
//        return objec
//    }
//    var hashValue: Int {
//    return 69
//    }
//}

class SongPlayer2: NSObject {
    
    let songPlayer: AVPlayer?
    
    var delegate: SongPoolAccessProtocol?
    var songPlayerCache: [Int:AVPlayerItem]?
//    var test: [MyBridge:Int]?
    
    func playSongWithId(songID: SongIDProtocol, atTimeInSeconds newTime: Double) {
        

    }
    
    func fetchPlayerItemForSongID(songID: SongIDProtocol) -> AVPlayerItem {
        let songHash = songID.hash
        var playerItem: AVPlayerItem?
        if let playerItem = songPlayerCache?[songHash] {

            if let songURL = delegate?.songURLForSongID(songID) {
                
            }
        } else {
            
        }
        return playerItem!
    }
}
