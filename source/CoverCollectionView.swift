//
//  CoverCollectionView.swift
//  reDiscover
//
//  Created by Teo on 08/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

class CoverCollectionView: NSCollectionView {
    
    override func mouseDown(with theEvent: NSEvent) {
        // Just pass the event on to the next responder in the chain.
        nextResponder?.mouseDown(with: theEvent)
    }

}
