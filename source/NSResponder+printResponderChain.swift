//
//  NSResponder+printResponderChain.swift
//  reDiscover
//
//  Created by Teo on 06/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

extension NSResponder {
    static func printResponderChain(responder: NSResponder?) {
        guard let r = responder else {
            Swift.print("End of chain.")
            return
        }
        print( r )
        printResponderChain(r.nextResponder)
        
    }
}
