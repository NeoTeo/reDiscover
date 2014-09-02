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
    
    var playingSongID: SongIDProtocol?
    
    var currentPlayerNode: AVAudioPlayerNode?
    // tmp
    var currentFile: AVAudioFile?
    
    override init() {
        songPlayerEngine = AVAudioEngine()
//        songPlayerNode = AVAudioPlayerNode()
//        songPlayerEngine.attachNode(songPlayerNode)
    }
    
    func playSongwithID(songID: SongIDProtocol, atTime theTime: Double) {
        var error: NSError?
        
        if delegate == nil { return }
    
        playingSongID = songID
        
        // Take a timestamp
        let startDate = NSDate()
        
        // It would seem that the Audio Player Node is removed from the engine when the song is done playing?!
        let songPlayerNode = currentPlayerNode ?? AVAudioPlayerNode()
        
        // If a previous node exists it must already be attached. If not, attach it.
        if currentPlayerNode == nil {
            songPlayerEngine.attachNode(songPlayerNode)
        }

        if songPlayerNode.playing {
            songPlayerNode.stop()
            // As far as I can see stopping the engine is the only way to reset the frame positon (songPlayerEngine.reset() doesn't.)
            songPlayerEngine.stop()
            
            currentPlayerNode?.addObserver(self, forKeyPath: "lastRenderTime.sampleTime", options: NSKeyValueObservingOptions.New, context: nil)
        }
        // First see if the file has been cached. (It's Song Pool's responsibility until we move that into SongPlayer)
        var theFile = delegate!.cachedAudioFileForSongID(songID)
        var theFileLength = delegate!.cachedLengthForSongID(songID).longLongValue
        
        if theFile == nil {
            println("AVAudioFile cache miss for song ID \(songID)")
            theFile = AVAudioFile(forReading: delegate!.songURLForSongID(songID), error: &error)
//            theFileLength = theFile.length
            //FIXME: for now take a wild guess
            theFileLength = Int64((theTime+20) * theFile.fileFormat.sampleRate)
        }
        
        if error != nil {
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
        

        // Hook up the player node up to the mainMixerNode using the processingFormat of the file.
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
        println("setPlaybackToTime")
        if let cP = currentPlayerNode {
            if let cF = currentFile {
//                println("Frame position: \(cF.framePosition)") // this always returns 0 in beta 3                
                let myFramePosition = AVAudioFramePosition(timeInSeconds * cF.fileFormat.sampleRate)
                let framesToPlay = AVAudioFrameCount(cF.length - myFramePosition)
                
                if framesToPlay <= 0 { return }
                
                // I'd hoped seeking to a frame would be as easy as this, but...
                cF.framePosition = myFramePosition
                // ...it seems you have to do this instead; stop/clear, reschedule with new frame pos, start again.
                cP.stop()
                cP.scheduleSegment(cF, startingFrame: myFramePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)
                cP.play()
                println("Frame position: \(cF.framePosition)") // this always returns 0 in beta 3
            }
        }
    }
    
    
    // The point of this funcition is to ensure that, once the length of the cached songs are known,
    // the currently playing song, which may well be using an estimated length to get going quickly,
    // can be updated with the actual length.
    // To do this we need to 
    // 1. Figure out how far into the song the player node is.
    // 2. Calculate how many frames are left to play.
    // 3. Schedule the proper song file with the player node.
    func refreshPlayingFrameCount() {
//        if currentFile {
//            println("\(currentFile!) pre Refresh frame position: \(currentFile!.framePosition)")
//            println("The last render time is \(currentPlayerNode!.lastRenderTime.sampleTime)")
//        }
        
        // A player node is associated with a file so, if I change the currentFile its node will not correspond and neither will its rendertime.
        // Check if the playing song has been cached.
        currentFile = delegate!.cachedAudioFileForSongID(playingSongID)

        if let cF = currentFile {
            if let cP = currentPlayerNode {
//                cF.framePosition = cP.lastRenderTime.sampleTime
                cP.stop()
                if let tmpFP = cP.lastRenderTime?.sampleTime {
                    println("\(cF) Refresh frame position: \(tmpFP)")
    //                let framesToPlay = AVAudioFrameCount(cF.length - cF.framePosition)
                    let framesToPlay = AVAudioFrameCount(cF.length - tmpFP)
                    cP.scheduleSegment(cF, startingFrame: tmpFP, frameCount: framesToPlay, atTime: nil, completionHandler: nil)

    //                cP.scheduleSegment(cF, startingFrame: cF.framePosition, frameCount: framesToPlay, atTime: nil, completionHandler: nil)
                    cP.play()
                }
//                println("frames to play \(framesToPlay)")
                
            }
        }
    }
    
}
