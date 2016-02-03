//
//  SongPoolAccessProtocol.swift
//  reDiscover
//
//  Created by Teo on 21/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongPoolAccessProtocol : SongMetadataUpdaterDelegate {
    
    func addSong(theSong: TGSong)
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
    func songForSongId(songId: SongId) -> TGSong?
    func getUrl(songId: SongId) -> NSURL?
    func debugLogSongWithId(songId: SongId)
    func debugLogCaches()
    func load( anUrl : NSURL) -> Bool
}
