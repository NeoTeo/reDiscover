//
//  SongPlayer.swift
//  reDiscover
//
//  Created by Matteo Sartori on 09/07/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

@objc
class SongPlayer: NSObject {

    let songPlayerEngine: AVAudioEngine
//    let songPlayerNode: AVAudioPlayerNode
    
    var currentlyPlaying: AVAudioPlayerNode?
    // tmp
    var currentFile: AVAudioFile?
    
    init() {
        songPlayerEngine = AVAudioEngine()
//        songPlayerNode = AVAudioPlayerNode()
//        songPlayerEngine.attachNode(songPlayerNode)
    }
    
    func playSongwithURL(theURL: NSURL, atTime theTime: Double) {
        var error: NSError?
        // Take a timestamp
        let startDate = NSDate()
        
        // It would seem that the Audio Player Node is removed from the engine when the song is done playing?!
        let songPlayerNode = currentlyPlaying ? currentlyPlaying! : AVAudioPlayerNode()
        
        if !currentlyPlaying {
            songPlayerEngine.attachNode(songPlayerNode)
        }
        
        if songPlayerNode.playing {
            songPlayerNode.stop()
        }
        
        let theFile = AVAudioFile(forReading: theURL, error: &error)

        if error {
            println("There was an error reading file.")
            return
        }
        
        
        // Set the frame we want to play from
        //        theFile.framePosition = AVAudioFramePosition(theTime * theFile.fileFormat.sampleRate)
        let myFramePosition = AVAudioFramePosition(theTime * theFile.fileFormat.sampleRate)
        let flDate = NSDate()
        
        // Getting the file length is really expensive (seconds!) - we want to pre load this in the bg!
        let framesToPlay = AVAudioFrameCount(theFile.length - theFile.framePosition)
        let fltime = NSDate().timeIntervalSinceDate(flDate)
        

        // Hook up the player node for this song to the engine.
        songPlayerEngine.connect(songPlayerNode, to: songPlayerEngine.mainMixerNode, format: theFile.processingFormat)

        // Request immediate playback.
        //        thePlayerNode.scheduleFile(theFile, atTime: nil, completionHandler: nil)
        if framesToPlay <= 0 { return }

        songPlayerNode.scheduleSegment(theFile, startingFrame: myFramePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)

        
        let interval = NSDate().timeIntervalSinceDate(startDate)
        if interval > 0.1 {
            println("WTF scheduled. Took \(interval)")
            println("fl time was \(fltime)")
        }
        
        // Gentlemen...
        if !songPlayerEngine.running {
            songPlayerEngine.startAndReturnError(&error)
        }
        
        songPlayerNode.play()
        
        if songPlayerNode.playing {
            println("Playing at volume \(songPlayerNode.volume)")
            currentlyPlaying = songPlayerNode
            currentFile = theFile
        }
    }

    
    func setPlaybackToTime(timeInSeconds: Double) {
        if let cP = currentlyPlaying {
            if let cF = currentFile {
                
                let myFramePosition = AVAudioFramePosition(timeInSeconds * cF.fileFormat.sampleRate)
                let framesToPlay = AVAudioFrameCount(cF.length - myFramePosition)
                
                if framesToPlay <= 0 { return }
                
                // I'd hoped seeking to a frame would be as easy as this, but...
//                cF.framePosition = myFramePosition
                // ...it seems you have to do this instead; stop/clear, reschedule with new frame pos, start again.
                cP.stop()
                cP.scheduleSegment(cF, startingFrame: myFramePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)
                cP.play()
                
            }
        }
    }
    
}
