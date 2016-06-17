//
//  NSResponder+printResponderChain.swift
//  reDiscover
//
//  Created by Teo on 06/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

extension NSResponder {
    static func printResponderChain(_ responder: NSResponder?) {
        guard let r = responder else {
            Swift.print("End of chain.")
            return
        }
        print( r )
        printResponderChain(r.nextResponder)
        
    }
}
