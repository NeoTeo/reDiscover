//
//  SongPoolAccessProtocol.swift
//  reDiscover
//
//  Created by Teo on 21/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

@objc protocol SongPoolAccessProtocol {
    
    func songForID(songID: SongIDProtocol) -> TGSong
    func songURLForSongID(songID: SongIDProtocol) -> NSURL
    func requestSongPlayback(songID: SongIDProtocol)
    func requestSongPlayback(songID: SongIDProtocol, withStartTimeInSeconds time: NSNumber?)
    func songDurationForSongID(songID: SongIDProtocol) -> NSNumber
    func songIdFromGridPos(gridPosition: NSPoint) -> SongIDProtocol
    func lastRequestedSongId() -> SongIDProtocol
    func currentlyPlayingSongId() -> SongIDProtocol
    func cacheWithContext(cacheContext: SongSelectionContext)
    func debugLogSongWithId(songId: SongIDProtocol)
    func debugLogCaches()
    
    func setRequestedPlayheadPosition(newPosition : NSNumber)
}
