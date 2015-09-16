//
//  SongAudioCacheOperation.swift
//  reDiscover
//
//  Created by Teo on 16/09/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation

/**
A CacheTask represents a unit of work that will cache a number of songs.
`TGSongAudioCacheTask` initiates the construction of a cache based on its given
context and waits for the caching to be done before returning. This is so that
the caller doesn't set too many tasks in motion that cannot be (as easily)
cancelled.

Eg. if we set 10 tasks going (by moving quickly over that many different
songs) and we create 10 tasks that return as soon as they have started but before
having finished caching, we have no (easy) way of interrupting a remote load
of a resource.

`TGSongAudioCacheTask` also tries to reuse what it can from the given oldCache
to avoid re-caching.
*/
class SongAudioCacheTask : NSObject {
    
    let cachingOpQueue = NSOperationQueue()
    
    // class context variable used by the observer.
    private var myContext = 0
    
    var songPoolAPI: SongPoolAccessProtocol?
    
    // holds the not yet ready players awaiting status change
    var loadingPlayers: PlayerToVoidClosure = PlayerToVoidClosure()
    let loadingPlayersLock = NSLock()
    
    // holds the ready players
    var songPlayerCache = HashToPlayerDictionary()
    
    init(songPoolAPI theAPI: SongPoolAccessProtocol?) {
        songPoolAPI = theAPI
    }
    
    func cacheWithContext(theContext: SongSelectionContext, oldCache: HashToPlayerDictionary) -> HashToPlayerDictionary {
        let group = dispatch_group_create()
        self.songPlayerCache = oldCache
        
        dispatch_group_enter(group)
        // Make a new cache and call trailing closure when done.
        self.newCacheFromCache(self.songPlayerCache, withContext: theContext, operationBlock: nil) { newCache in
            self.songPlayerCache = newCache
            dispatch_group_leave(group)
        }
        
        // Block until all that entered the group have left it.
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        return songPlayerCache
    }
    
    
    func newCacheFromCache(oldCache: HashToPlayerDictionary, withContext context: SongSelectionContext, operationBlock: NSBlockOperation?, completionHandler: (HashToPlayerDictionary)->()) {
        
        var wantedCacheCount    = 0
        let newCacheLock        = NSLock()
        
        var newCache: HashToPlayerDictionary = HashToPlayerDictionary() {
            /**
            Call the completion handler once the number of items in the `newCache`
            matches the `wantedCacheCount`.
            */
            didSet {
                if wantedCacheCount != 0 {
                    // If we're done, call the completion handler.
                    if newCache.count == wantedCacheCount {
                        completionHandler(newCache)
                    }
                }
            }
        }
        
        /**
        The method `generateWantedSongIds` will figure out, based on the `context`,
        what songs to cache and will call the trailing closure with each songId
        as it is chosen. The closure ensures existing players are re-used or
        initiates the creation of a new one by calling `performWhenReadyForPlayback`
        and adds it to the `newCache` once it is ready. The loading of a player
        ensures the song itself is cached (loaded and ready to play).
        */
        wantedCacheCount = generateWantedSongIds(context, operationBlock: operationBlock) { songId in
            // This is a handler that is passed a songId of a song that needs caching.
            // If the song was already in the old cache, copy it to the new cache.
            if let oldPlayer = oldCache[songId.hash] {
                /**
                Since oldCache is a deep copy of the actual cache we are effectively
                copying the asset. We need to lock it during access because it
                might get accessed concurrently by a loading completion block
                below that was initiated on a previous run.
                */
                
                newCacheLock.withCriticalScope {
                    newCache[songId.hash] = oldPlayer
                }
                
            } else {
                
                /// Song player had not been previously cached.
                /// Do it now and add it to the newCache when it's ready.
                self.performWhenReadyForPlayback(songId){ songPlayer in
                    
                    /// This can get called some time after
                    newCacheLock.withCriticalScope {
                        newCache[songId.hash] = songPlayer
                    }
                }
            }
        }
        
        /**
        This catches the case where all the songs are already cached by the
        time the `generateWantedSongsIds` returns with a `wantedCacheCount`:
        If the `newCache` contains the same amount of players as we wanted,
        we call the completion handler, otherwise the completion handler is
        called in the `didSet` of the `newCache`.
        */
        if newCache.count == wantedCacheCount {
            completionHandler(newCache)
        }
    }
    
    /**
    This method will use the given context to decide on a number of songIds
    that should be cached.
    It calls the given `idHandler` with each chosen `songId` right away.
    
    Future improvements will take a caching algo to allow for different
    types of caching selections.
    */
    func generateWantedSongIds(theContext: SongSelectionContext, operationBlock: NSBlockOperation?, idHandler: (SongIDProtocol)->()) -> Int {
        
        let selectionPos    = theContext.selectionPos
        let gridDims        = theContext.gridDimensions
        let radius          = 2
        
        var wantedCacheCount = 0
        // Figure out what songs to cache
        for var row = Int(selectionPos.y)-radius ; row <= Int(selectionPos.y)+radius ; row++ {
            for var col = Int(selectionPos.x)-radius ; col <= Int(selectionPos.x)+radius ; col++ {
                
                // Guards - Don't go lower than 0 or outside the dims of the grid.
                if row < 0 || col < 0 { continue }
                if row >= Int(gridDims.y) || col >= Int(gridDims.x) { continue } //break }
                
                let gridPos = NSPoint(x: col, y: row)
                
                if let songId = songPoolAPI?.songIdFromGridPos(gridPos) {
                    wantedCacheCount++
                    idHandler(songId)
                }
            }
        }
        print("wantedCacheCount \(wantedCacheCount)")
        return wantedCacheCount
    }
    
    /**
    This method performs the given closure when the player for a given songId is
    ready to play. This implies that it has been cached and has an associated AVPlayer
    with which to play back the song that the id refers to.
    */
    func performWhenReadyForPlayback(songId: SongIDProtocol, readySongHandler: (AVPlayer)->()) {
        
        // At this point we don't know if the url is for the local file system or streaming.
        guard let songURL = self.songPoolAPI?.songURLForSongID(songId) else {
            print("No songPool!")
            return
        }
        
        let songAsset: AVURLAsset = AVURLAsset(URL: songURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        print("slow loading AV URL asset")
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
        //FIXME: Find a non locking solution (like a queue)
        self.loadingPlayersLock.withCriticalScope {
            self.loadingPlayers[thePlayer] = aClosure
        }
        
        // add an observer to get called when the player status changes (to signal completion).
        thePlayer.addObserver(self, forKeyPath: "status", options: .New, context: &self.myContext)
        
        songAsset.loadValuesAsynchronouslyForKeys(["tracks"]){
            /**
            Everything in here is executed asyncly and thus any access to class
            properties need to either be atomic or serialized. This completion
            block is called exactly once per invocation; either sync'ly if an
            error occurred straight away or async'ly if a value of any one of
            the specified keys is loaded OR an error occurred in the loading
            OR `cancelLoading` was invoked on the asset.
            */
            var error: NSError?
            var thePlayerItem: AVPlayerItem?
            
            /**
            Since this closure is also called when the call is cancelled we
            need to check for specific values. Streams don't have a tracks value
            so if it fails we assume it's a stream.
            */
            switch(songAsset.statusOfValueForKey("tracks", error: &error)) {
            case .Loaded:
                // This is a file
                thePlayerItem = AVPlayerItem(asset: songAsset)
                
            case .Failed:
                // This is a stream
                thePlayerItem = AVPlayerItem(URL: songURL)
                
            default:
                print("ERROR: Cancelled?")
                return
            }
            
            //Make sure the asset's duration value is available before kicking off the song player loading.
            songAsset.loadValuesAsynchronouslyForKeys(["duration"]){
                print("load async duration")
                /// Since the loading begins as soon as the player item is associated with the player I have to do this *after* adding the observer to an uninited player.
                thePlayer.replaceCurrentItemWithPlayerItem(thePlayerItem)
            }
        }
    }
    
    /**
    Observer method called when the status of the player changes.
    */
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            
            let playa = object as! AVPlayer
            
            // call the closure that corresponds to this player
            //FIXME: Don't actually believe loadingPlayers can be accessed concurrently.
            // Both this and the closure executed by loadValuesAsynchronouslyForKeys are on the same thread,
            // so they shouldn't be concurrent. Try to remove and test.
            var completionHandler: VoidVoidClosure?
            /// Lock it because performWhenReadyForPlayback may be adding to loadingPlayers in a different thread.
            self.loadingPlayersLock.withCriticalScope {
                completionHandler = self.loadingPlayers.removeValueForKey(playa) as VoidVoidClosure?
            }
            
            completionHandler?()
            
        } else {
            // Observer with different context. Passing to super.
            //super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
}
