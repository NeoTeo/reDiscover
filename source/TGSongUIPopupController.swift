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

    var delegate: TGSongUIPopupProtocol?
    
    @IBOutlet weak var timelineButton: NSButton!
    @IBOutlet weak var plusButton: NSButton!
    @IBOutlet weak var gearButton: NSButton!
    @IBOutlet weak var infoButton: NSButton!
    
    var position: NSPoint = NSPoint(x: 0, y: 0)
    var dimensions: NSSize = NSSize(width: 150, height: 150)
    
    @IBAction func timelineAction(_ sender: AnyObject) {
        delegate?.songUITimelineButtonWasPressed()
    }
    
    @IBAction func plusAction(_ sender: AnyObject) {
        delegate?.songUIPlusButtonWasPressed()
    }
    
    @IBAction func gearAction(_ sender: AnyObject) {
        delegate?.songUIGearButtonWasPressed()
    }
    
    @IBAction func infoAction(_ sender: AnyObject) {
        delegate?.songUIInfoButtonWasPressed()
    }
    
    var currentUIPosition: NSPoint {
        get {
            return position
        }
        set {
            position = newValue
            view.frame = CGRect(x: newValue.x, y: newValue.y,
                width: dimensions.width, height: dimensions.height)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func showInside(_ state: Bool, frame: NSRect) {
        currentUIPosition = frame.origin
        view.isHidden = !state
    }
    
    func showUI(_ state: Bool) {
        view.isHidden = !state
    }
    
    func isUIActive() -> Bool {
        return !view.isHidden
    }
    
}
