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
typealias VoidVoidClosure = ()->()
typealias PlayerToVoidClosure = [AVPlayer:VoidVoidClosure]


class TGSongAudioCacher : NSObject {
    var songPoolAPI: SongPoolAccessProtocol?
    let cachingOpQueue = NSOperationQueue()
    var songPlayerCache = HashToPlayerDictionary()
    
    override init() {
        super.init()
        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
        cachingOpQueue.maxConcurrentOperationCount = 1
    }

    func cacheWithContext(theContext: NSDictionary) {
        // To make this as responsive as possible we cancel any previous ops and put the operation in an op queue.
        
        cachingOpQueue.cancelAllOperations()
        
        let operationBlock = NSBlockOperation()
        
        operationBlock.addExecutionBlock(){ [unowned operationBlock] in
            let cacheTask = TGSongAudioCacheTask(songPoolAPI: self.songPoolAPI)
            self.songPlayerCache = cacheTask.cacheWithContext(theContext)
        }
        
        operationBlock.completionBlock = {
            print("-------------- Caching op completed...")
            if operationBlock.cancelled == true { println("cancelled") } else { println("succeeded")}
        }
        
        cachingOpQueue.addOperation(operationBlock)
        
        println("cachingOpQueue count: \(cachingOpQueue.operationCount)")
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

class TGSongAudioCacheTask : NSObject {
    
    let cachingOpQueue = NSOperationQueue()
    
    // Global context variable used by the observer.
    private var myContext = 0
    
    var songPoolAPI: SongPoolAccessProtocol?
    
    // holds the not yet ready players awaiting status change
    var loadingPlayers: PlayerToVoidClosure = PlayerToVoidClosure()
    let loadingPlayersLock = NSLock()
    
    // holds the ready players
    var songPlayerCache = HashToPlayerDictionary()
    let cacheLock = NSLock();

    init(songPoolAPI theAPI: SongPoolAccessProtocol?) {
        songPoolAPI = theAPI
    }
    
    /*
    override init() {
        super.init()
        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
        cachingOpQueue.maxConcurrentOperationCount = 1
    }
    */
/*    func cacheWithContext(theContext: NSDictionary) {

        // To make this as responsive as possible we cancel any previous ops and put the operation in an op queue.
    
        cachingOpQueue.cancelAllOperations()
        
        let operationBlock = NSBlockOperation()
        
        operationBlock.addExecutionBlock(){ [unowned operationBlock] in

            self.newCacheFromCache(self.songPlayerCache, withContext: theContext, operationBlock: operationBlock) { newCache in
                self.songPlayerCache = newCache
            }
        }
        
        operationBlock.completionBlock = {
            print("-------------- Caching op completed...")
            if operationBlock.cancelled == true { println("cancelled") } else { println("succeeded")}
        }
        
        cachingOpQueue.addOperation(operationBlock)
        
        println("cachingOpQueue count: \(cachingOpQueue.operationCount)")
    }
*/
    func cacheWithContext(theContext: NSDictionary) -> HashToPlayerDictionary {
        let condLock = NSConditionLock(condition: 42)
        
            let players  = [AVPlayer](self.loadingPlayers.keys)
            for player in players {
                NSLog("Cancelling player %@",player)
                // might want to cancel loading here as well?
                player.removeObserver(self, forKeyPath: "status", context: &self.myContext)
                player.currentItem?.asset.cancelLoading()
                
                self.loadingPlayersLock.lock()
                self.loadingPlayers.removeValueForKey(player)
                self.loadingPlayersLock.unlock()
            }
            
            // The start a new cache.
            self.newCacheFromCache(self.songPlayerCache, withContext: theContext, operationBlock: nil) { newCache in
                self.songPlayerCache = newCache
                condLock.lock()
                condLock.unlockWithCondition(69)
            }
        
            condLock.lockWhenCondition(69)
            condLock.unlock()
            NSLog("done...")
        return songPlayerCache
    }
    
//    func newCacheFromCache(oldCache: HashToPlayerDictionary, theContext: NSDictionary, operationBlock: NSBlockOperation?) {
    func newCacheFromCache(oldCache: HashToPlayerDictionary, withContext context: NSDictionary, operationBlock: NSBlockOperation?, completionHandler: (HashToPlayerDictionary)->()) {
        
        var wantedCacheCount = 0

        let newCacheLock    = NSLock()
        var newCache: HashToPlayerDictionary = HashToPlayerDictionary() {
            // This keeps track of how many objects have been added to the cache.
            didSet {
                println("newCache count: \(newCache.count)")
//                if doneGenerating == true && newCache.count == wantedCacheCount {
                //if doneGenerating == true {
                if wantedCacheCount != 0 {
                    if newCache.count == wantedCacheCount {
                        println("completion handler that will be replacing cache. wantedCacheCount: \(wantedCacheCount)")
                        completionHandler(newCache)
                    }
                }
            }
        }

        println("Cachers gonna cache. Old cache size: \(oldCache.count)")
//        if operationBlock?.cancelled == true { print("cancelled inside newCacheFromCache.") ; return }
        
        wantedCacheCount = generateWantedSongIds(context, operationBlock: operationBlock) { songId in
            // This is a handler that is passed a songId of a song that needs caching.
//    if operationBlock?.cancelled == true { NSLog("cancelled in flight") ; return }
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
            NSLog("boing")
        }
        NSLog("boing2")
        // So newCache is not (necessarily) deleted upon exiting this function because it may have been captured by the closure passed to
        // the performWhenReadyForPlayback. Once that closure has been called (which in turn triggers the newCache's didSet which calls the completionHandler) it will get deleted.
    }

    func generateWantedSongIds(theContext: NSDictionary, operationBlock: NSBlockOperation?, idHandler: (SongIDProtocol)->()) -> Int {
        
        let selectedSongId  = theContext["selectedSongId"] as SongIDProtocol
        let selectionPos    = theContext["pos"]!.pointValue as NSPoint
        let gridDims        = theContext["gridDims"]!.pointValue as NSPoint
        let radius          = 2
        
        //        doneGenerating = false
        var wantedCacheCount = 0
        // Figure out what songs to cache
        for var row = Int(selectionPos.y)-radius ; row <= Int(selectionPos.y)+radius ; row++ {
            for var col = Int(selectionPos.x)-radius ; col <= Int(selectionPos.x)+radius ; col++ {
                
                // Guards
//                if operationBlock?.cancelled == true { NSLog("cancelled in flight") ; return 0 }

                if row < 0 || col < 0 { continue }
                if row >= Int(gridDims.y) || col >= Int(gridDims.x) { break }
                
                let gridPos = NSPoint(x: col, y: row)
                
                if let songId = songPoolAPI?.songIdFromGridPos(gridPos) {
                    //println(songId)
                    //                    NSLog("The songId is %@", songId.hash);
                    wantedCacheCount++
                    idHandler(songId)
                }
            }
        }
        //        doneGenerating = true
        return wantedCacheCount
    }
    
    func performWhenReadyForPlayback(songId: SongIDProtocol, readySongHandler: (AVPlayer)->()) {
        
        // At this point we don't know if the url is for the local file system or streaming.
        let songURL = self.songPoolAPI?.songURLForSongID(songId)
        var songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: nil)
//        var songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        
        let thePlayer = AVPlayer()
        // The closure we want to have executed upon successful loading. We store this with the player it belongs to.
        let aClosure: VoidVoidClosure = {
            // remove the player's observer since it may be deallocated subsequently.
            thePlayer.removeObserver(self, forKeyPath: "status", context: &self.myContext)

            // Call the handler with the player.
            readySongHandler(thePlayer)
        }
        
        // store the completionHandler for this player so it can be called on successful load.
        // locking access because it may be accessed async'ly by the observeValueForKeyPath observing a status change.
        self.loadingPlayersLock.lock()
        self.loadingPlayers[thePlayer] = aClosure
        self.loadingPlayersLock.unlock()
        NSLog("loadingPlayers is now %ld",self.loadingPlayers.count)

        // add an observer to get called when the player status changes.
        thePlayer.addObserver(self, forKeyPath: "status", options: .New, context: &self.myContext)

        songAsset.loadValuesAsynchronouslyForKeys(["tracks"]){
            // Everything in here is executed asyncly and thus any access to class properties need to either be atomic or serialized.
            // This completion block is called exactly once per invocation; either sync'ly if an error occurred straight away or
            // async'ly if a value of any one of the specified keys is loaded OR an error occurred in the loading OR cancelLoading was invoked on the asset.
            NSLog("loadValuesAsynchronouslyForKeys for asset %@ called",songAsset)

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
                println("ERROR: Cancelled?")
                return
            }
            
            // Currently waiting for the duration does not always return (or at least takes way too long).
            
            // Since the loading begins as soon as the player item is associated with the player I have to do this *after* adding the observer to an uninited player.
            thePlayer.replaceCurrentItemWithPlayerItem(thePlayerItem)
            
        }
    }
    
//    func awaitReadyStatus(completionHandler: ()->() {
//        
//    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            print("Status for \(object) changed to ")
            let playa = object as AVPlayer
            
            switch playa.status {
            case .ReadyToPlay:
                println("Ready to play!")
            default:
                println("Something went wrong")
            }

            // call the closure that corresponds to this player
            self.loadingPlayersLock.lock() // lock it because there might be concurrent accesses to the loadingPlayers
            let completionHandler = self.loadingPlayers.removeValueForKey(playa) as VoidVoidClosure?
            self.loadingPlayersLock.unlock()
            completionHandler?()
            
        } else {
            println("Observer with different context. Passing to super.")
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
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
