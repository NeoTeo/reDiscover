//
//  SongArtCache.swift
//  reDiscover
//
//  Created by Teo on 11/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

//
struct SongArtCache {
    typealias HashToImageDict = [String : NSImage]
    
    private let coverArtById: HashToImageDict
    
    
    init() {
        var defaultCache = HashToImageDict()
        coverArtById = defaultCache
    }
    
    init(startCache: HashToImageDict) {
        coverArtById = startCache
    }
    
    
    func addImage(image: NSImage?) -> SongArtCache {
        
        if let img = image {
            var tmpCache = coverArtById
            tmpCache[img.hashId()] = img
            return SongArtCache(startCache: tmpCache)
        }
        
        // If nothing was added we just return the same cache
        return self
    }
    
    func artForArtId(artId: SongArtId) -> NSImage? {
        // Return art that is already in the cache.
            return coverArtById[artId as String]
    }
}
