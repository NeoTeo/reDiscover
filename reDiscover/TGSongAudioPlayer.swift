//
//  TGSongAudioPlayer.swift
//  reDiscover
//
//  Created by Teo on 12/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

class TGSongAudioPlayer: NSObject {

    var songPlayer: AVPlayer?
    var prevSongPlayer: AVPlayer?
    var songPlayerItem: AVPlayerItem?
    var currentVolume:Float  = 1.0
    
    func setSong(newPlayer: AVPlayer) {
        if songPlayer != nil {
            prevSongPlayer = songPlayer
        }
        songPlayer = newPlayer
    }
    
    func playSong() {
        
        if prevSongPlayer != nil {
            prevSongPlayer?.pause()
        }
        if songPlayer == nil { return }
        songPlayer!.volume = currentVolume

        if songPlayer!.status == .ReadyToPlay {
            songPlayer!.play()
        }
    }
    
    func setVolume(theVolume: Float) {
        currentVolume = theVolume
    }
}
