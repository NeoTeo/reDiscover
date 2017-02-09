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
 
    var droppedURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        /// Skip the drop to speed up debugging of main app
    }
    
    override func viewDidAppear() {
        let envVars = ProcessInfo.processInfo.environment
        if let _ = envVars["NO_DROP"] {
            droppedURL = URL(fileURLWithPath: "/Users/teo/Desktop/songs")
            if droppedURL != nil  {
                dropViewDidReceiveURL(droppedURL!)
            }
        }
    }
    
    override var representedObject: Any? {
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
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
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
        self.view.window?.isReleasedWhenClosed = true
        self.view.window?.close()

    }
    
    
    func dropViewDidReceiveURL(_ theURL: URL) {
        if validateURL(theURL) {
            droppedURL = theURL
//            performSegueWithIdentifier("oldStyleSegue", sender: self)
            performSegue(withIdentifier: "segueToSplitView", sender: self)            
            // We need to do this again because the app is deactivated when the user clicks a folder
            // in Finder to drag onto here.

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func validateURL(_ theURL: URL) -> Bool {
        // TEO For now...
        return true
    }
}
