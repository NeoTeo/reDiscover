//
//  SongSelectionContext.swift
//  reDiscover
//
//  Created by Teo on 25/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation


public protocol SongSelectionContext {
    var selectedSongId: SongId { get }
    var speedVector: NSPoint { get }
    var selectionPos: NSPoint { get }
    var gridDimensions: NSPoint { get }
    var cachingMethod: CachingMethod { get }
	
	/// A closure called after the completion of the caching task
	var postCompletion: (([SongId]) -> Void)? { get set }
}

//struct TGSongSelectionContext : SongSelectionContext {
final class TGSongSelectionContext : NSObject, SongSelectionContext {
    let selectedSongId: SongId
    let speedVector: NSPoint
    let selectionPos: NSPoint
    let gridDimensions: NSPoint
    let cachingMethod: CachingMethod
	
	var postCompletion : (([SongId]) -> Void)?
	
    init(selectedSongId: SongId,
        speedVector: NSPoint,
        selectionPos: NSPoint,
        gridDimensions: NSPoint,
        cachingMethod: CachingMethod) {
            
        self.selectedSongId = selectedSongId
        self.speedVector = speedVector
        self.selectionPos = selectionPos
        self.gridDimensions = gridDimensions
        self.cachingMethod = cachingMethod
    }
}
