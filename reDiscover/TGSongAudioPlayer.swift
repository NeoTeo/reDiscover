//
//  TGSongAudioPlayer.swift
//  reDiscover
//
//  Created by Teo on 12/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation
extension CMTime {
    var isValid: Bool { return flags & .Valid != nil }
    var isIndefinite: Bool { return flags & .Indefinite != nil }
}

class TGSongAudioPlayer: NSObject {

    var currentPlayer: AVPlayer?
    var prevSongPlayer: AVPlayer?
    var songPlayerItem: AVPlayerItem?
    var currentVolume:Float  = 1.0
    var playerObserver: AnyObject?
    let testQ = dispatch_queue_create("playback queue", nil)
    
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
                playAtTime(newPlayTime)
            }
        }
    }
    
    var songDuration: CMTime {
        get {
            if let duration = currentPlayer?.currentItem?.duration {
                if !duration.isValid || duration.isIndefinite  { return CMTimeMake(0, 1) }
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
        //FIXME: What's to keep the prevSongPlayer to be overwritten before it has a chance
        // to free its time observer
        set(newPlayer) {
            if currentPlayer != nil {
                prevSongPlayer = currentPlayer
            }
            currentPlayer = newPlayer
        }
    }

    func setSongPlayer(newPlayer: AVPlayer, block: (CMTime) -> ()) {
        if let prevPlayer = prevSongPlayer where playerObserver != nil {
            prevPlayer.removeTimeObserver(playerObserver)
        }
        
        if currentPlayer != nil {
            prevSongPlayer = currentPlayer
        }
        currentPlayer = newPlayer
        
        currentPlayer?.addPeriodicTimeObserverForInterval(CMTimeMake(10, 100), queue: testQ, usingBlock: block)
    }

    func getPrevSongPlayer()->AVPlayer? {
        return prevSongPlayer
    }
    
    func playSong() {
        
        if let prevPlayer = prevSongPlayer {
            prevPlayer.pause()
            NSNotificationCenter.defaultCenter().removeObserver(prevPlayer)
        }
        
        if let player = songPlayer {
            player.volume = currentVolume

            if player.status == .ReadyToPlay {
                player.play()
            }
        }
    }
    
    func playAtTime(startTime: Float64) {
        currentPlayer?.seekToTime(CMTimeMakeWithSeconds(startTime, 1)){ success in
            if success == true {
//                println("Playback from \(startTime) succeeded")
                self.playSong()
            }
//            else {
////                println("Playback from \(startTime) failed/was interrupted.")
//            }
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
    
    func songDidUpdatePlayheadPosition(position: Double) {
        // Set the value of a playhead position var that is bound to 
        // TGTimelineSliderCell's currentPlayheadPositionInPercent
    }
    
}
