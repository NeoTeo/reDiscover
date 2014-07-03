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
    
    override func awakeFromNib() {
        println("wakey wake")
        let dropView = self.view as DropView
        dropView.delegate = self

    }
    
    override func prepareForSegue(segue: NSStoryboardSegue!, sender: AnyObject!) {
        println("Drop View Controller preparing for segue")
        let mainVC = segue.destinationController as TGMainViewController
        if droppedURL {
            mainVC.theURL = droppedURL
        } else {
            println("Error: no song pool")
        }
        
    }
        
    func dropViewDidReceiveURL(theURL: NSURL) {
        if validateURL(theURL) {
            droppedURL = theURL
            println("Gogo widget")

//            performSegueWithIdentifier("goMainViewSegue", sender: self)
            performSegueWithIdentifier("oldStyleSegue", sender: self)
            
        }
        println("Done")
    }

    func validateURL(theURL: NSURL) -> Bool {
        // TEO For now...
        return true
    }
}
