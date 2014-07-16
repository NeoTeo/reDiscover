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

    // Gives access to the song pool
    var delegate: SongPoolAccessProtocol?
    
    let songPlayerEngine: AVAudioEngine
//    let songPlayerNode: AVAudioPlayerNode
    
    var currentPlayerNode: AVAudioPlayerNode?
    // tmp
    var currentFile: AVAudioFile?
    
    init() {
        songPlayerEngine = AVAudioEngine()
//        songPlayerNode = AVAudioPlayerNode()
//        songPlayerEngine.attachNode(songPlayerNode)
    }
    
    func playSongwithID(songID: AnyObject, atTime theTime: Double) {
        var error: NSError?
        
        if !delegate { return }
        
        // Take a timestamp
        let startDate = NSDate()
        
        // It would seem that the Audio Player Node is removed from the engine when the song is done playing?!
        let songPlayerNode = currentPlayerNode ? currentPlayerNode! : AVAudioPlayerNode()
        
        // If a previous node exists it must already be attached. If not, attach it.
        if !currentPlayerNode {
            songPlayerEngine.attachNode(songPlayerNode)
        }
        
        if songPlayerNode.playing {
            songPlayerNode.stop()
        }
        
        // First see if the file has been cached. (It's Song Pool's responsibility until we move that into SongPlayer)
        var theFile = delegate!.cachedAudioFileForSongID(songID)
        var theFileLength = delegate!.cachedLengthForSongID(songID).longLongValue
        
        if !theFile {
            println("AVAudioFile cache miss for song ID \(songID)")
            theFile = AVAudioFile(forReading: delegate!.songURLForSongID(songID), error: &error)
//            theFileLength = theFile.length
            // for now take a wild guess
            theFileLength = Int64((theTime+20) * theFile.fileFormat.sampleRate)
        }
        
        if error {
            println("There was an error reading file.")
            return
        }
        
        
        // Set the frame we want to play from
        //        theFile.framePosition = AVAudioFramePosition(theTime * theFile.fileFormat.sampleRate)
        let myFramePosition = AVAudioFramePosition(theTime * theFile.fileFormat.sampleRate)
        let flDate = NSDate()
        
        // Getting the file length is really expensive (seconds!) - we want to pre load this in the bg!
        let framesToPlay = AVAudioFrameCount(theFileLength - theFile.framePosition)
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
            currentPlayerNode = songPlayerNode
            currentFile = theFile
                        println("Setting the current file \(theFile)")
        }
    }

    
    func setPlaybackToTime(timeInSeconds: Double) {
        if let cP = currentPlayerNode {
            if let cF = currentFile {
                
                let myFramePosition = AVAudioFramePosition(timeInSeconds * cF.fileFormat.sampleRate)
                let framesToPlay = AVAudioFrameCount(cF.length - myFramePosition)
                
                if framesToPlay <= 0 { return }
                
                // I'd hoped seeking to a frame would be as easy as this, but...
//                cF.framePosition = myFramePosition
                // ...it seems you have to do this instead; stop/clear, reschedule with new frame pos, start again.
                cP.stop()
//                cP.pause()
                cP.scheduleSegment(cF, startingFrame: myFramePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)
                cP.play()
                
            }
        }
    }
    
    func refreshPlayingFrameCount() {
        if let cF = currentFile {
            if let cP = currentPlayerNode {
//                println("Frame position: \(cF.framePosition)") // this always returns 0 in beta 3
//                cP.pause()
                let framesToPlay = AVAudioFrameCount(cF.length - cF.framePosition)
                cP.stop()
                cP.scheduleSegment(cF, startingFrame: cF.framePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)
                cP.play()

//                println("frames to play \(framesToPlay)")
                
            }
        }
    }
}
