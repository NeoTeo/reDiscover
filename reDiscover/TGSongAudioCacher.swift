//
//  TGSongAudioCacher.swift
//  reDiscover
//
//  Created by Teo on 07/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

typealias HashToPlayerDictionary = [UInt:AVPlayer]

class TGSongAudioCacher: NSObject {
    let cachingOpQueue = NSOperationQueue()
    var songPoolAPI: SongPoolAccessProtocol?

    var songPlayerCache = HashToPlayerDictionary()
    
    override init() {
        super.init()
        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
        cachingOpQueue.maxConcurrentOperationCount = 1
    }

    
    func cacheWithContext(context: NSDictionary) {
        cachingOpQueue.cancelAllOperations()
        
        let operationBlock = NSBlockOperation()
        
        operationBlock.addExecutionBlock(){ [unowned operationBlock] in
            let newTask = CacherTask()
            newTask.songPoolAPI = self.songPoolAPI
            //FIXME: We're going to need to pass in the operationBlock so we can cancel inside.
            // Call cache with context and a completion closure
            newTask.newCacheFromCache(self.songPlayerCache, withContext: context) { newCache in
                self.songPlayerCache = newCache
            }
        }
        
        operationBlock.completionBlock = {
            print("-------------- Caching op completed...")
            if operationBlock.cancelled == true { println("cancelled") } else { println("succeeded")}
        }
        
        cachingOpQueue.addOperation(operationBlock)

    }
    
    func dumpCacheToLog() {
        for id in songPlayerCache {
            println(id)
        }
    }

}

class CacherTask: NSObject {
    
    // Global context variable used by the observer.
    private var myContext = 0
    
    var songPoolAPI: SongPoolAccessProtocol?
    
    // holds the not yet ready players awaiting status change
    //var loadingPlayers = NSMutableArray()
    typealias VoidVoidClosure = ()->()
    var loadingPlayers = [AVPlayer:VoidVoidClosure]()
    let loadingPlayersLock = NSLock()
    
    // holds the ready players
    var songPlayerCache = HashToPlayerDictionary()
    let cacheLock = NSLock();
    
    var wantedCacheCount = 0
    var doneGenerating = false
    
//    let cachingOpQueue = NSOperationQueue()
    
//    override init() {
//        super.init()
//        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
//        cachingOpQueue.maxConcurrentOperationCount = 1
//    }
    /*
    func cacheWithContext(theContext: NSDictionary) {

        // To make this as responsive as possible we cancel any previous ops and put the operation in an op queue.
    
        cachingOpQueue.cancelAllOperations()
        
        let operationBlock = NSBlockOperation()
        
        operationBlock.addExecutionBlock(){ [unowned operationBlock] in
            self.newCacheFromCache(self.songPlayerCache, theContext: theContext, operationBlock: operationBlock)
        
        }
        
        operationBlock.completionBlock = {
            print("-------------- Caching op completed...")
            if operationBlock.cancelled == true { println("cancelled") } else { println("succeeded")}
        }
        
        cachingOpQueue.addOperation(operationBlock)
        println("cachingOpQueue count: \(cachingOpQueue.operationCount)")
    }
    */
//    func newCacheFromCache(oldCache: HashToPlayerDictionary, theContext: NSDictionary, operationBlock: NSBlockOperation?) {
    func newCacheFromCache(oldCache: HashToPlayerDictionary, withContext context: NSDictionary, completionHandler: (HashToPlayerDictionary)->()) {
        //let minRow          = selectionPos.y as Int
        let newCacheLock    = NSLock()
        var newCache: HashToPlayerDictionary = HashToPlayerDictionary() {
            // This keeps track of how many objects have been added to the cache.
            didSet {
                println("newCache count: \(newCache.count) and wantedCacheCount is \(wantedCacheCount)")
//                if doneGenerating == true && newCache.count == wantedCacheCount {
                if doneGenerating == true {
                    if newCache.count == wantedCacheCount {
                        println("completion handler that will be replacing cache. wantedCacheCount: \(wantedCacheCount)")
                        completionHandler(newCache)
                    }
                }
            }
        }

        println("Cachers gonna cache. Old cache size: \(oldCache.count)")
        
//        if operationBlock?.cancelled == true { print("cancelled inside newCacheFromCache.") ; return }
        
        generateWantedSongIds(context) { songId in
            // This is a handler that is passed a songId of a song that needs caching.

            var allDone = true
    
            // If the song was already in the old cache, copy it to the new cache.
            if let oldPlayer = oldCache[songId.hash] {
                // since oldCache is a deep copy of the actual cache we are effectively copying the asset.
                // We need to lock it during access because it might get accessed concurrently by the loading completion block below.
                newCacheLock.lock()
                newCache[songId.hash] = oldPlayer
                newCacheLock.unlock()
            } else {
                self.performWhenReadyForPlayback(songId){ songPlayer in
                 
                    newCacheLock.lock()
                    newCache[songId.hash] = songPlayer
                    newCacheLock.unlock()
                }
            }
        }
        // This catches the case where the songs cache before the generateWantedSongsIds is done.
        if newCache.count == wantedCacheCount {

            println("(early bird) completion handler that will be replacing cache. wantedCacheCount: \(wantedCacheCount)")
            completionHandler(newCache)

        }

    }

    func performWhenReadyForPlayback(songId: SongIDProtocol, readySongHandler: (AVPlayer)->()) {
        // At this point we don't know if the url is for the local file system or streaming.
        let songURL = self.songPoolAPI?.songURLForSongID(songId)
        var songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        
        songAsset.loadValuesAsynchronouslyForKeys(["tracks"]){
            // Everything in here is executed asyncly and thus any access to class properties need to either be atomic or serialized.
            var error: NSError?
            var thePlayerItem: AVPlayerItem?
            
            // since the completion handler is also called when the call is cancelled we need to check.
            // Streams don't have a tracks value so if it fails we assume it's a stream.
            switch(songAsset.statusOfValueForKey("tracks", error: &error)) {
            case .Loaded:
                // This is a file
                thePlayerItem = AVPlayerItem(asset: songAsset)
                
            case .Failed:
                // This is a stream
                thePlayerItem = AVPlayerItem(URL: songURL)
                
            default:
                println("ERROR:")
                return
            }

            // Associating the player item with the player starts it getting ready to play. Presumably we don't want to wait too long before
            // adding an observer to the player.
//            let thePlayer = AVPlayer(playerItem: thePlayerItem)
            let thePlayer = AVPlayer()
            
            NSLog("thePlayer is %@",thePlayer)
            //println("Add observer to \(thePlayer)")
            // The closure we want to have executed upon successful loading. We store this with the player it belongs to.
            let aClosure: VoidVoidClosure = {
                // remove the player's observer since it may be deallocated subsequently.
                thePlayer.removeObserver(self, forKeyPath: "status", context: &self.myContext)
                
                // Call the handler with the player.
                readySongHandler(thePlayer)
            }
            
            // store the completionHandler for this player so it can be called on successful load.
            self.loadingPlayersLock.lock()
            self.loadingPlayers[thePlayer] = aClosure
            self.loadingPlayersLock.unlock()
            NSLog("loadingPlayers is now %ld",self.loadingPlayers.count)

            // add an observer to get called when the player status changes.
            thePlayer.addObserver(self, forKeyPath: "status", options: .New, context: &self.myContext)
            
            // Since the loading begins as soon as the player item is associated with the player I have to do this *after* adding the observer to an uninited player.
            thePlayer.replaceCurrentItemWithPlayerItem(thePlayerItem)
        }
    }
    
//    func awaitReadyStatus(completionHandler: ()->() {
//        
//    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            println("Status for \(object) changed to \(change[NSKeyValueChangeNewKey])")
            let playa = object as AVPlayer
            
            switch playa.status {
            case .ReadyToPlay:
                println("That means ready to play!")
            default:
                println("Something went wrong")
            }
            
            // call the closure that corresponds to this player
            self.loadingPlayersLock.lock()
            let completionHandler = self.loadingPlayers.removeValueForKey(playa) as VoidVoidClosure?
            self.loadingPlayersLock.unlock()
            completionHandler!()
            
        } else {
            println("Observer with different context. Passing to super.")
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
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
                
                if let songId = songPoolAPI?.songIdFromGridPos(gridPos) {
                    println(songId)
//                    NSLog("The songId is %@", songId.hash);
                    wantedCacheCount++
                    idHandler(songId)
                }
            }
        }
        doneGenerating = true
    }
    
    func songPlayerForSongId(songId: SongIDProtocol) -> AVPlayer? {
        
        return songPlayerCache[songId.hash]
    }
    
    func dumpCacheToLog() {
        for id in songPlayerCache {
            println(id)
        }
    }
}
