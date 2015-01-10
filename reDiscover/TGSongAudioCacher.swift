//
//  TGSongAudioCacher.swift
//  reDiscover
//
//  Created by Teo on 07/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

import Cocoa

//class foo {
//    var baz = false
//    
//    func test() {
//
//        var bar: Int = 1 {
//            didSet {
//                if baz == true && bar == 2 {
//                    println("baz")
//                }
//            }
//        }
//        
//    }
//}


class TGSongAudioCacher: NSObject {

    var songPoolAPI: SongPoolAccessProtocol?
    
    typealias cacheType = [UInt:AVAsset]
    
    var songAssetCache = cacheType()
    var wantedCacheCount = 0
    var doneGenerating = false
    
    func cacheWithContext(theContext: NSDictionary) {

        newCacheFromCache(songAssetCache, theContext: theContext)

    }
    
    func newCacheFromCache(oldCache: cacheType, theContext: NSDictionary) {
        //let minRow          = selectionPos.y as Int
        let newCacheLock       = NSLock()
        var newCache: cacheType = cacheType() {
            // This keeps track of how many objects have been added to the cache.
            didSet {
                println("newCache count: \(newCache.count)")
//                if doneGenerating == true && newCache.count == wantedCacheCount {
                if doneGenerating == true {
                    if newCache.count == wantedCacheCount {
                        println("Replacing cache. wantedCacheCount: \(wantedCacheCount)")
                        songAssetCache = newCache
                    }
                }
            }
        }

        println("Cachers gonna cache. Old cache size: \(oldCache.count)")
        
        generateWantedSongIds(theContext) { songId in
            
            var allDone = true
            
            // This is a handler that is passed a songId of a song that needs caching.
            println(songId)
            if let oldAsset = oldCache[songId.hash] {
                // since oldCache is a deep copy of the actual cache we are effectively copying the asset.
                newCacheLock.lock()
                newCache[songId.hash] = oldAsset
                newCacheLock.unlock()
                println("copy")
            } else {
                println("new")
                let songURL = self.songPoolAPI?.songURLForSongID(songId)
                
                    
                // for now load the song here, but eventually we'll want it from a songAudioPlayer class
                var songAsset = AVAsset.assetWithURL(songURL) as AVAsset?
                if songAsset == nil { println("WTF, songAsset is nil!") ; return }
                
                songAsset?.loadValuesAsynchronouslyForKeys(["duration"]){
                    var error: NSError?
                    // since the completion handler is also called when the call is cancelled we need to check.
                    if let status = songAsset?.statusOfValueForKey("duration", error: &error) {
                        switch(status) {
                            case .Loaded:
                                
                                // If this is already in the old cache, copy it to the new one.
                                // This breaks because of concurrent access to the same reference (newCache).
                                // Solve by taking turns (serial queue) adding to the cache or make access atomic.
                                newCacheLock.lock()
                                newCache[songId.hash] = songAsset
                                newCacheLock.unlock()
                            default:
                                println("ERROR:")
                        }
                    }
                }
            }
        }
        // This catches the case where the songs cache before the generateWantedSongsIds is done.
        if newCache.count == wantedCacheCount {
            println("Replacing cache. wantedCacheCount: \(wantedCacheCount)")
            songAssetCache = newCache
        }

    }
    
    func generateWantedSongIds(theContext: NSDictionary, idHandler: (SongIDProtocol)->()){

        let selectedSongId  = theContext["selectedSongId"] as SongIDProtocol
        let selectionPos    = theContext["pos"]!.pointValue as NSPoint
        let gridDims        = theContext["gridDims"]!.pointValue as NSPoint
        let radius          = 2

        doneGenerating = false
        wantedCacheCount = 0
        // Figure out what songs to cache
        for var row = Int(selectionPos.y)-radius ; row <= Int(selectionPos.y)+radius ; row++ {
            for var col = Int(selectionPos.x)-radius ; col <= Int(selectionPos.x)+radius ; col++ {
                
                // Guards
                if row < 0 || col < 0 { continue }
                if row >= Int(gridDims.y) || col >= Int(gridDims.x) { break }
                
                let gridPos = NSPoint(x: col, y: row)
                
                let songId = songPoolAPI?.songIdFromGridPos(gridPos)
                //println("From gridpos \(gridPos) we got id \(songId)")
                if songId == nil { continue }
                
                wantedCacheCount++
                idHandler(songId!)
            }
        }
        doneGenerating = true
    }
    
    func songAssetForSongId(songId: SongIDProtocol) -> AVAsset? {
        
        return songAssetCache[songId.hash]
    }
    
    func dumpCacheToLog() {
        for id in songAssetCache {
            println(id)
        }
    }
}
