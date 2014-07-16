//
//  ScrollingTextView.swift
//  reDiscover
//
//  Created by Matteo Sartori on 16/07/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

@objc
class ScrollingTextView: NSView {

    var scrollText:NSString = ""
    var textWidth = 0.0
    var scrollSpeed: NSTimeInterval = 0
    var scrollTimer: NSTimer?
    var textPosition = NSZeroPoint
    
    init(frame: NSRect) {
        super.init(frame: frame)
        // Initialization code here.
    }

    func setText(newText: NSString) {
        scrollText = newText
        textWidth = newText.sizeWithAttributes(nil).width

        if scrollTimer == nil && scrollSpeed > 0 && scrollText != nil {
            scrollTimer = NSTimer.scheduledTimerWithTimeInterval(scrollSpeed, target: self, selector: "moveText:", userInfo: nil, repeats: true)
        }
    }
    
    func setSpeed(newSpeed: NSTimeInterval) {
        if newSpeed == scrollSpeed { return }
        scrollSpeed = newSpeed
        scrollTimer?.invalidate()
        scrollTimer = nil
        if scrollSpeed > 0.00 && scrollText != nil {
            scrollTimer = NSTimer.scheduledTimerWithTimeInterval(scrollSpeed, target: self, selector: "moveText:", userInfo: nil, repeats: true)
        }
    }
    
 
    func moveText(timer: NSTimer) {
        textPosition.x -= 1.0
        self.needsDisplay = true

    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        if textPosition.x + textWidth  < 0 {
            textPosition.x = dirtyRect.size.width
        }
        
        scrollText.drawAtPoint(textPosition, withAttributes: nil)
        
        if textPosition.x < 0 {
            var otherPoint = textPosition
            otherPoint.x += dirtyRect.size.width
            scrollText.drawAtPoint(otherPoint, withAttributes: nil)
        }
        
    }
    
}
