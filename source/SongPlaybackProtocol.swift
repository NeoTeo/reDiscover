//
//  SongPlaybackProtocol.swift
//  reDiscover
//
//  Created by teo on 02/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongPlaybackProtocol {
//- (void)requestSongPlayback:(id<SongId>)songID withStartTimeInSeconds:(NSNumber *)time {
    func requestPlayback(songId : SongId, startTimeInSeconds : NSNumber) 
}