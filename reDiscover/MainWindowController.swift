//
//  MainWindowController.swift
//  reDiscover
//
//  Created by Matteo Sartori on 25/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation

class MainWindowController : NSWindowController {
    override func awakeFromNib()  {
        println("the main wake")
        
        showWindow(self)
    }
    
}