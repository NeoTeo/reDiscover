//
//  TGSongAudioCacher.swift
//  reDiscover
//
//  Created by Teo on 07/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

@objc public enum CachingMethod : Int {
    case None
    case All
    case Square
    case SpeedRect
}

typealias HashToPlayerDictionary    = [Int:AVPlayer]

final class TGSongAudioCacher : NSObject {
    
    typealias PlayerRequestBlock = (AVPlayer)->()

    struct SongIdToPlayerRequestBlock {
        var songId: SongIDProtocol
        var callBack: PlayerRequestBlock
    }
    
    var songPoolAPI: SongPoolAccessProtocol?
    /// Serialize the access to the pendingPlayerRequestCallback.
    let pendingRequestQ = dispatch_queue_create("Request access q", DISPATCH_QUEUE_SERIAL)
    var _pendingPlayerRequestCallback: SongIdToPlayerRequestBlock?
    var pendingPlayerRequestCallback: SongIdToPlayerRequestBlock? {
        get {
            var requestCallback: SongIdToPlayerRequestBlock?
            dispatch_sync(self.pendingRequestQ) {
                requestCallback = self._pendingPlayerRequestCallback
            }
            return requestCallback
        }
        set(request) {
            dispatch_sync(self.pendingRequestQ) {
                self._pendingPlayerRequestCallback = request
            }
        }
    }

    let cachingOpQueue  = NSOperationQueue()
    var songPlayerCache = HashToPlayerDictionary()

    var debugId = 0
    
    override init() {
        super.init()
        
        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
        cachingOpQueue.maxConcurrentOperationCount = 1
        
        // Make the qos higher than default.
        cachingOpQueue.qualityOfService = .UserInitiated
    }

    func cacheWithContext(theContext: SongSelectionContext) {

        /**
        Each cacheTask will block until it is done. Because we wrap them in operation
        blocks and add them to the cachingOpQueue all previous cacheTasks/op blocks
        can be cancelled if a newer (and implicitly more important) request arrives.
        */
        
        /// Cancel any pending operations in the cachingOpQueue.
        cachingOpQueue.cancelAllOperations()
        debugId++
        let operationBlock = NSBlockOperation()

        operationBlock.addExecutionBlock(){
            
            print("Execution block",self.debugId)
            
            let cacheTask = SongAudioCacheTask(songPoolAPI: self.songPoolAPI)

            /// cacheWithContext will block until the whole cache has been loaded.
            self.songPlayerCache = cacheTask.cacheWithContext(theContext, oldCache: self.songPlayerCache)
            
            /**     If there's a pending request check if this new cache can service it. */
            if let pp = self.pendingPlayerRequestCallback {
                
                // Check if the pending player request is in this new cache
                if let player = self.songPlayerCache[pp.songId.hash] {
                    pp.callBack(player)
                    self.pendingPlayerRequestCallback = nil
                }
            }
            
        }
        
/*        operationBlock.completionBlock = {

            if operationBlock.cancelled == true { println("cancelled") } else { println("succeeded")}
        }
*/
        /** Make the new operation dependent on the successful completion of the
        previous operation (if any) to ensure the tasks are executed in the order
        they were called.
        */
        if cachingOpQueue.operationCount > 0 {
            let prevOp = cachingOpQueue.operations[cachingOpQueue.operationCount-1]
            operationBlock.addDependency(prevOp)
        }
        
        cachingOpQueue.addOperation(operationBlock)
    }
    
    /**
            Called by the Song Pool when a song is requested.
    
            If the song is already in the cache the callBack closure is called with
            a copy of the player.
    
            If the song is not yet cached a new RequestBlock is created with the 
            given songId and callback and is stored in the pendingPlayerRequestCallback
            instance variable. Any existing pending request is overwritten because
            it has been overridden by this more recent request.
    */
    func performWhenPlayerIsAvailableForSongId(songId: SongIDProtocol, callBack: (AVPlayer)->()) {
        
        // If the requested Player is already in the cache, execute callback immediately.
        if let player = songPlayerCache[songId.hash] {
            callBack(player)
        } else {
            // Add the callback to a dictionary where it's associated with the songId.
            self.pendingPlayerRequestCallback = SongIdToPlayerRequestBlock(songId: songId, callBack: callBack)
            /** It is assumed that the requested song is in the process of being
                cached but has not yet succeeded. When it does succeed, the execution
                block (in cacheWithContext) will check for the pending request and 
                call it.
            */
        }
    }
}


/** Debug stuff */
extension TGSongAudioCacher {
    func dumpCacheToLog() {
        for id in songPlayerCache {
            print(id)
        }
    }
}
