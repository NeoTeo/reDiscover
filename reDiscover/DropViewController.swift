//
//  DropViewController.swift
//  reDiscover
//
//  Created by Matteo Sartori on 23/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit

class DropViewController : NSViewController, DropViewDelegate {
 
    var droppedURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func awakeFromNib() {
        let dropView = self.view as DropView
        dropView.delegate = self
        
        // We need this to bring the window to the front on app start.
        NSApp.activateIgnoringOtherApps(true)

    }
   
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {
        println("Drop View Controller preparing for segue")

//        let mainVC = segue.destinationController as MainViewController
        let mainVC = segue.destinationController as TGMainViewController

        if droppedURL == nil {
            println("Error: no song pool")
            return
        }
        mainVC.theURL = droppedURL

    }
    
    func dropViewDidReceiveURL(theURL: NSURL) {
        if validateURL(theURL) {
            droppedURL = theURL

            performSegueWithIdentifier("oldStyleSegue", sender: self)
            
            // We need to do this again because the app is deactivated when the user clicks a folder
            // in Finder to drag onto here.
            NSApp.activateIgnoringOtherApps(true)
        }
    }

    func validateURL(theURL: NSURL) -> Bool {
        // TEO For now...
        return true
    }
}
