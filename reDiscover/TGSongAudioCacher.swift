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

//            var doneGenerating = false
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

        }

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
                    println(songId)
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
        var songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
//        var songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: nil)
        let sema = dispatch_semaphore_create(0)
        
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
                
                // Signal that we're done.
                dispatch_semaphore_signal(sema)
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
        
        NSLog("performWhenReadyForPlayback waiting...")
        // Wait for the signal that the async song loading has succeeded. 
        // The problem with this is that a cancellation won't stop this. An operation cancellation will not remove or stop an operation that is already in progress. 
        // If the operation has reached this point where it's waiting for a signal and has been cancelled, the semaphore will not periodically check for cancellation 
        // and drop out accordingly. This means that as long as this is executing, any operations added to the queue will do nothing until this
        // is finished and is removed from the queue.
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
        NSLog("performWhenReadyForPlayback done waiting...")
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
    
    
    
    func songPlayerForSongId(songId: SongIDProtocol) -> AVPlayer? {
        
        return songPlayerCache[songId.hash]
    }
    
    func dumpCacheToLog() {
        for id in songPlayerCache {
            println(id)
        }
    }
}
