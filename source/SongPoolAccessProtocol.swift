//
//  SongPoolAccessProtocol.swift
//  reDiscover
//
//  Created by Teo on 21/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongPoolAccessProtocol : SongMetadataUpdaterDelegate {
    
//    func songForID(songID: SongIDProtocol) -> TGSong
    func addSong(theSong: TGSong)
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongIDProtocol)
    func songForSongId(songId: SongIDProtocol) -> TGSong?
//    func songURLForSongID(songID: SongIDProtocol) -> NSURL
    func getUrl(songId: SongIDProtocol) -> NSURL?
//    func requestSongPlayback(songID: SongIDProtocol)
//    func requestSongPlayback(songID: SongIDProtocol, withStartTimeInSeconds time: NSNumber?)
//    func songDurationForSongID(songID: SongIDProtocol) -> NSNumber
//    func songIdFromGridPos(gridPosition: NSPoint) -> SongIDProtocol
//    func lastRequestedSongId() -> SongIDProtocol
//    func currentlyPlayingSongId() -> SongIDProtocol
    //func cacheWithContext(cacheContext: SongSelectionContext)
    func debugLogSongWithId(songId: SongIDProtocol)
    func debugLogCaches()
    
//    func setRequestedPlayheadPosition(newPosition : NSNumber)
    func load( anUrl : NSURL) -> Bool
}
