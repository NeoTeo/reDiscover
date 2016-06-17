//
//  DebugDisplay.swift
//  reDiscover
//
//  Created by Teo on 24/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

class DebugDisplay: NSViewController {
    
    var position: NSPoint = NSPoint(x: 0, y: 0)
    var dimensions: NSSize = NSSize(width: 500, height: 150)

    var refreshTimer: Timer?
    
    static var updatePending = false
    static var debugString = "No data"
    
    @IBOutlet weak var titleLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = "Debug Display"
        // Do view setup here.
        // start up some periodic updating
    }
    
    var uiPosition: NSPoint {
        get {
            return position
        }
        set {
            position = newValue
            view.frame = CGRect(x: newValue.x, y: newValue.y, width: dimensions.width, height: dimensions.height)
        }
    }
    
    func showUI(_ state: Bool) {
        if state == true {
            print("Setting timer")
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector("refresh"), userInfo: nil, repeats: true)
        }
        else {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        view.isHidden = !state
    }

    func isVisible() -> Bool {
        return !view.isHidden
    }
 
    // The class that actually has an instance of DebugDisplay can copy the class
    // debugString into the instance titleLabel
    func refresh() {
        if DebugDisplay.updatePending == true {
            titleLabel.stringValue = DebugDisplay.debugString
            DebugDisplay.updatePending = false
        }
    }
    
    // Allows me to update from anywhere without needing an instance.
    static func updateDebugStrings(_ newString: String) {
        debugString = newString
        updatePending = true
    }
}
