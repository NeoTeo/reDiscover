//
//  TGTimelineBarView.swift
//  reDiscover
//
//  Created by teo on 18/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa

public class TGTimelineBarView : NSView {
    
    private var playheadPositionInPercent : Double!
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        playheadPositionInPercent = 0
    }

    public func setPlayheadPositionInPercent(_ pos : Double) {
        self.playheadPositionInPercent = pos
    }
    
    func knobPosition() -> NSPoint {
        let rect = self.bounds
        return NSPoint(x: rect.width / 100 * CGFloat(playheadPositionInPercent), y: rect.midY)
    }

    override public func draw(_ dirtyRect: NSRect) {
        
        let rect = self.bounds
        NSColor.lightGray.setFill()
        NSRectFill(rect)
        
        // Calculate the width of the rect based on current playhead position
        let width = rect.width / 100 * CGFloat(playheadPositionInPercent)
        let playbackRect = NSRect(x: rect.origin.x+1,
                                  y: rect.origin.y+1,
                              width: width,
                             height: rect.size.height-2)
        
        NSColor.darkGray.setFill()
        NSRectFill(playbackRect)
    }
}
