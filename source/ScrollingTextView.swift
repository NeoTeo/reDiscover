//
//  ScrollingTextView.swift
//  reDiscover
//
//  Created by Matteo Sartori on 16/07/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

class ScrollingTextView: NSView {

    var scrollText:NSString = ""
    // Why this can't just be a Double I don't know.
    var textWidth: CGFloat = 0.0
    var scrollSpeed: TimeInterval = 0
    var scrollTimer: Timer?
    var textPosition = NSZeroPoint
    
    func setText(_ newText: NSString) {
        scrollText = newText
        textWidth = newText.size(withAttributes: nil).width

        if scrollTimer == nil && scrollSpeed > 0 {
            scrollTimer = Timer.scheduledTimer(timeInterval: scrollSpeed, target: self, selector: #selector(ScrollingTextView.moveText(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func setSpeed(_ newSpeed: TimeInterval) {
        if newSpeed == scrollSpeed { return }
        scrollSpeed = newSpeed
        scrollTimer?.invalidate()
        scrollTimer = nil
        if scrollSpeed > 0.00 {
            scrollTimer = Timer.scheduledTimer(timeInterval: scrollSpeed, target: self, selector: #selector(ScrollingTextView.moveText(_:)), userInfo: nil, repeats: true)
        }
    }
    
 
    func moveText(_ timer: Timer) {
        textPosition.x -= 1.0
        self.needsDisplay = true

    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if textPosition.x + textWidth  < 0 {
            textPosition.x = dirtyRect.size.width
        }
        
        scrollText.draw(at: textPosition, withAttributes: nil)
        
        if textPosition.x < 0 {
            var otherPoint = textPosition
            otherPoint.x += dirtyRect.size.width
            scrollText.draw(at: otherPoint, withAttributes: nil)
        }
        
    }
    
}
