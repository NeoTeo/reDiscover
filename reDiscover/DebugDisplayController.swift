//
//  DebugDisplayController.swift
//  reDiscover
//
//  Created by Matteo Sartori on 13/07/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

class DebugDisplayController: NSViewController {
//init() {
//        super.init()
//        println("Debug Display Controller init")
//        self.view = NSView(frame: NSMakeRect(0, 0, 600, 600))
//    }
//    
//    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
//        super.init(nibName: nibName, bundle: nibBundleOrNil)
//    }

    //MARK:
    @IBOutlet var testLabel: NSTextFieldCell!

    init(coder: NSCoder!) {
        println("Debug Display Controller init with coder")
        super.init(coder: coder)
    }
    
    override func loadView()  {
        println("Debug Display Controller loadview")
//        Crashes. That's how fucked beta 3 is.
//        testLabel.stringValue = "ARSE"
    }
    
    func displayCachedCells(cache: NSSet, songPool: SongPoolAccessProtocol) {
        // traverse the cache and get the frame of each of the songs.
        for songID in cache {
            
        }
    }
}
