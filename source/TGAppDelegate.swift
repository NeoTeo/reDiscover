//
//  TGAppDelegate.swift
//  reDiscover
//
//  Created by Teo on 09/02/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

class TGAppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        println("We did \(self.window)")
        NSApplication.shared()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("Active application!")
    }
}
