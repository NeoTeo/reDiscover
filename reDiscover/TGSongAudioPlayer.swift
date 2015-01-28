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
    
    var currentPlayTime: Double {
        get {
            if let timeInSecs = currentPlayer?.currentTime() {
                return CMTimeGetSeconds(timeInSecs)
            } else {
                return 0
            }
        }
        set(newPlayTime) {
            if newPlayTime >= 0 && newPlayTime < CMTimeGetSeconds(songDuration) {
                currentPlayer?.seekToTime(CMTimeMakeWithSeconds(newPlayTime, 1))
            }
        }
    }
    
    var songDuration: CMTime {
        get {
            if let duration = currentPlayer?.currentItem?.duration {
                return duration
            } else {
                return CMTimeMake(0, 1)
            }
            //return currentPlayer?.currentItem?.duration
        }
    }
    
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
    
    func playAtTime(startTime: Float64) {
        currentPlayer?.seekToTime(CMTimeMakeWithSeconds(startTime, 1)){ success in
            if success == true {
                println("Playback from \(startTime) succeeded")
                self.playSong()
            } else {
                println("Playback from \(startTime) FAILED")
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "stopSong", name: AVPlayerItemDidPlayToEndTimeNotification, object: currentPlayer)
    }
    
    func stopSong() {
        NSLog("song finished!")
        NSNotificationCenter.defaultCenter().removeObserver(currentPlayer!)
    }
    
    func setVolume(theVolume: Float) {
        currentVolume = theVolume
    }
    
    
}
