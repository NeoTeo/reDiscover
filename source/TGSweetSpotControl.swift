//
//  TGSweetSpotControl.swift
//  reDiscover
//
//  Created by teo on 24/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa

class TGSweetSpotControl : NSButton {
    
    override func drawRect(dirtyRect: NSRect) {
        self.image?.drawInRect(dirtyRect)
    }
}