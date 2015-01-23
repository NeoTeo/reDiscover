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

    var currentPlayer: AVPlayer?
    var prevSongPlayer: AVPlayer?
    var songPlayerItem: AVPlayerItem?
    var currentVolume:Float  = 1.0
    
    var songPlayer: AVPlayer? {
        get {
            return self.currentPlayer
        }
        set(newPlayer) {
            if currentPlayer != nil {
                prevSongPlayer = currentPlayer
            }
            currentPlayer = newPlayer
        }
    }
    
    func getPrevSongPlayer()->AVPlayer? {
        return prevSongPlayer
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
