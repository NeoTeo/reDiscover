//
//  MainViewController.swift
//  reDiscover
//
//  Created by Matteo Sartori on 23/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit

enum PanelNames {
    case Playlist
    case Covers
    case Information
}

class MainViewController : NSSplitViewController {
    
    var theURL: NSURL?
    
    override func performSegueWithIdentifier(identifier: String!, sender: AnyObject!) {
        println("Swift perform segue")
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue!, sender: AnyObject!) {
        println("Swift prepare for segue")
    }
    
    override func keyDown(theEvent: NSEvent!) {
        println("A key \(theEvent.characters) was pressed")
        println("ANd now the first responder is \(self.view.window.firstResponder)")

    }
    
    
    override func viewDidAppear() {
        println("Pling")
        println("My window is \(self.view.window)")
        println("ANd the first responder is \(self.view.window.firstResponder)")
        NSApp.activateIgnoringOtherApps(true)
        println(self.view.window.makeFirstResponder(self))
                println("ANd now the first responder is \(self.view.window.firstResponder)")
    }
    
    func userToggledPanel(panelID: Int) {
        let splitViewItem = self.splitViewItems[panelID] as NSSplitViewItem
        let anchor: NSLayoutAttribute = (panelID == 0) ? .Trailing : .Leading
        
        self.view.window.setAnchorAttribute(anchor, forOrientation: .Horizontal)
        splitViewItem.animator().collapsed = !splitViewItem.collapsed
    }
}