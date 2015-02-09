//
//  TGSongUIPopupController.swift
//  reDiscover
//
//  Created by Teo on 09/02/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

protocol TGSongUIPopupProtocol {
    func songUIPlusButtonWasPressed()
    func songUITimelineButtonWasPressed()
    func songUIInfoButtonWasPressed()
    func songUIGearButtonWasPressed()
}

class TGSongUIPopupController: NSViewController {

    var position: NSPoint = NSPoint(x: 0, y: 0)
    var dimensions: NSSize = NSSize(width: 150, height: 150)
    
    var currentUIPosition: NSPoint {
        get {
            return position
        }
        set {
            position = newValue
            view.frame = CGRectMake(newValue.x, newValue.y, dimensions.width, dimensions.height)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        println("View DID appear!")
    }
}
