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
        /// Skip the drop to speed up debugging of main app
    }
    
    override func viewDidAppear() {
        let envVars = NSProcessInfo.processInfo().environment
        if let _ = envVars["NO_DROP"] {
            droppedURL = NSURL(fileURLWithPath: "/Users/teo/Desktop/50 Cent")
            if droppedURL != nil  {
                dropViewDidReceiveURL(droppedURL!)
            }
        }
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func awakeFromNib() {
        
        let dropView = self.view as! DropView
        dropView.delegate = self
        
    }
   
    /** Called by performSegueWithIdentifier and gives us a chance to set things 
        up before the segue happens. In this case we're closing and releasing the
        drop window before TGSplitViewController's viewDidAppear is called.
    */
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {
        print("Drop View Controller preparing for segue")

      let splitViewCtrlr = segue.destinationController as! TGSplitViewController
        
        if droppedURL == nil {
            print("Error: no song pool")
            return
        }
        
        //REFAC better way of passing the url?
        splitViewCtrlr.theURL = droppedURL
        
        /// close and release the drop window.
        //print("The window we're about to close: \(self.view.window)")
        self.view.window?.releasedWhenClosed = true
        self.view.window?.close()

    }
    
    
    func dropViewDidReceiveURL(theURL: NSURL) {
        if validateURL(theURL) {
            droppedURL = theURL
//            performSegueWithIdentifier("oldStyleSegue", sender: self)
            performSegueWithIdentifier("segueToSplitView", sender: self)            
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
