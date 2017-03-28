//
//  TGSongAudioCacher.swift
//  reDiscover
//
//  Created by Teo on 07/01/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa
import AVFoundation

public enum CachingMethod : Int {
    case none
    case all
    case square
    case speedRect
}

protocol SongAudioCacherDelegate {

        func getUrl(_ songId : SongId) -> URL?
        func getSongId(_ gridPos : NSPoint) -> SongId?
}

typealias SongIdToPlayerDictionary    = [SongId : AVPlayer]

final class TGSongAudioCacher : NSObject {
    
    typealias PlayerRequestBlock = (AVPlayer)->()

    struct SongIdToPlayerRequestBlock {
        var songId: SongId
        var callBack: PlayerRequestBlock
    }
    
    var delegate : SongAudioCacherDelegate?
    
    /// Serialize the access to the pendingPlayerRequestCallback.
    let pendingRequestQ = DispatchQueue(label: "Request access q")
    var _pendingPlayerRequestCallback: SongIdToPlayerRequestBlock?
    var pendingPlayerRequestCallback: SongIdToPlayerRequestBlock? {
        get {
            var requestCallback: SongIdToPlayerRequestBlock?
            self.pendingRequestQ.sync {
                requestCallback = self._pendingPlayerRequestCallback
            }
            return requestCallback
        }
        set(request) {
            self.pendingRequestQ.sync {
                self._pendingPlayerRequestCallback = request
            }
        }
    }

    let cachingOpQueue  = OperationQueue()
	var songPlayerCache = SongIdToPlayerDictionary()

    var debugId = 0
    
    override init() {
        super.init()
        
        // Ensure the caching operation queue is effectively serial by reducing its concurrent op count to 1.
        cachingOpQueue.maxConcurrentOperationCount = 1
        
        // Make the qos higher than default.
        cachingOpQueue.qualityOfService = .userInitiated
    }

    func cacheWithContext(_ theContext: SongSelectionContext) {

        /**
        Each cacheTask will block until it is done. Because we wrap them in operation
        blocks and add them to the cachingOpQueue all previous cacheTasks/op blocks
        can be cancelled if a newer (and implicitly more important) request arrives.
        */
        
        /// Cancel any pending operations in the cachingOpQueue.
        cachingOpQueue.cancelAllOperations()
        debugId += 1
        let operationBlock = BlockOperation()

        operationBlock.addExecutionBlock(){
            
            print("Execution block",self.debugId)
            
            let cacheTask = SongAudioCacheTask()
            cacheTask.delegate = self
            
            /// cacheWithContext will block until the whole cache has been loaded.
            self.songPlayerCache = cacheTask.cacheWithContext(theContext, oldCache: self.songPlayerCache)
            
            /**     If there's a pending request check if this new cache can service it. */
            if let pp = self.pendingPlayerRequestCallback {
                
                // Check if the pending player request is in this new cache
                if let player = self.songPlayerCache[pp.songId] {				
                    pp.callBack(player)
                    self.pendingPlayerRequestCallback = nil
                }
            }
			/// hertil : let's call the update metadata from here?
			let songIds = Array(self.songPlayerCache.keys)
			
            if theContext.postCompletion == nil { print("POSTCOMPLETION WAS NIL! <-------------------------") }
            
            theContext.postCompletion?(songIds)

			print("We have a fresh new cache of size \(self.songPlayerCache.count)")
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
    func performWhenPlayerIsAvailableForSongId(_ songId: SongId, callBack: @escaping (AVPlayer)->()) {
        
        // If the requested Player is already in the cache, execute callback immediately.
        if let player = songPlayerCache[songId] {
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
	
	func isCached(_ songId : SongId) -> Bool {
		guard let _ = songPlayerCache[songId] else { return false }
		return true
	}
	
	func getCachedSongIds() -> [SongId] {
		return Array(songPlayerCache.keys)
	}
}

extension TGSongAudioCacher : SongAudioCacheTaskDelegate {
    
    func getSongURL(_ songId : SongId) -> URL? {
        return delegate?.getUrl(songId)
    }
    
    func getSongId(_ gridPos : NSPoint) -> SongId? {
        return delegate?.getSongId(gridPos)
    }
}
/** Debug stuff */
extension TGSongAudioCacher {
    func dumpCacheToLog() {
		let _ = songPlayerCache.map { (key, value) in print("cached: \(key.hashValue)") }
    }
}
