//
//  GridViewController.swift
//  reDiscover
//
//  Created by Matteo Sartori on 24/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation

class CoverViewController : NSViewController {
    
    @IBAction func selectorAction(sender: NSSegmentedControl) {
    
        let mainVC = self.parentViewController as MainViewController
        
        mainVC.userToggledPanel(sender.selectedSegment)
    }
    
}