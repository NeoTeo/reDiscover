//
//  SongSelectionContext.swift
//  reDiscover
//
//  Created by Teo on 25/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

@objc public protocol SongSelectionContext {
    var selectedSongId: SongIDProtocol { get }
    var speedVector: NSPoint { get }
    var selectionPos: NSPoint { get }
    var gridDimensions: NSPoint { get }
}

//struct TGSongSelectionContext : SongSelectionContext {
final class TGSongSelectionContext : NSObject, SongSelectionContext {
    let selectedSongId: SongIDProtocol
    let speedVector: NSPoint
    let selectionPos: NSPoint
    let gridDimensions: NSPoint
    
    init(selectedSongId: SongIDProtocol, speedVector: NSPoint, selectionPos: NSPoint, gridDimensions: NSPoint) {
        self.selectedSongId = selectedSongId
        self.speedVector = speedVector
        self.selectionPos = selectionPos
        self.gridDimensions = gridDimensions
    }
}