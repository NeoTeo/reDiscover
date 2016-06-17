//
//  SongPoolAccessProtocol.swift
//  reDiscover
//
//  Created by Teo on 21/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongPoolAccessProtocol {
    
    func addSong(_ theSong: TGSong)
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
    func songForSongId(_ songId: SongId) -> TGSong?
    func getUrl(_ songId: SongId) -> URL?
    func debugLogSongWithId(_ songId: SongId)
    func debugLogCaches()
    func load( _ anUrl : URL) -> Bool
}
