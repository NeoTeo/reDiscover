//
//  TGSongUIPopupController.swift
//  reDiscover
//
//  Created by Teo on 09/02/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa


@objc
protocol TGSongUIPopupProtocol {
    func songUIPlusButtonWasPressed()
    func songUITimelineButtonWasPressed()
    func songUIInfoButtonWasPressed()
    func songUIGearButtonWasPressed()
}

class TGSongUIPopupController: NSViewController {

    var delegate: TGSongUIPopupProtocol?
    
    @IBOutlet weak var timelineButton: NSButton!
    @IBOutlet weak var plusButton: NSButton!
    @IBOutlet weak var gearButton: NSButton!
    @IBOutlet weak var infoButton: NSButton!
    
    var position: NSPoint = NSPoint(x: 0, y: 0)
    var dimensions: NSSize = NSSize(width: 150, height: 150)
    
    @IBAction func timelineAction(sender: AnyObject) {
        println("Go timeline")
        delegate?.songUITimelineButtonWasPressed()
    }
    
    @IBAction func plusAction(sender: AnyObject) {
        delegate?.songUIPlusButtonWasPressed()
    }
    
    @IBAction func gearAction(sender: AnyObject) {
        delegate?.songUIGearButtonWasPressed()
    }
    
    @IBAction func infoAction(sender: AnyObject) {
        delegate?.songUIInfoButtonWasPressed()
    }
    
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
    
    
    func showUI(state: Bool) {
        view.hidden = !state
    }
    
    func isUIActive() -> Bool {
        return !view.hidden
    }
    
}
