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
 
    override func awakeFromNib() {
        println("wakey wake")
        let dropView = self.view as DropView
        dropView.delegate = self

    }
    
    override func prepareForSegue(segue: NSStoryboardSegue!, sender: AnyObject!) {
        println("Drop View Controller preparing for segue")
    }
        
    func dropViewDidReceiveURL(theURL: NSURL) {
        let songPool = TGSongPool()
        if songPool.validateURL(theURL) {
            println("Gogo widget")

            performSegueWithIdentifier("goMainViewSegue", sender: self)
        }
        println("Done")
    }
}
