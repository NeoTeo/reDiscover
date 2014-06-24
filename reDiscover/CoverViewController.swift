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
        
        // Explicit conversion from segment to panel name to avoid sync errors if one or the other changes.
        switch sender.selectedSegment {
        case 0:
            mainVC.userToggledPanel(PanelNames.Playlist)
        case 2:
            mainVC.userToggledPanel(PanelNames.Information)
        default:
            break
        }
    }
    
}