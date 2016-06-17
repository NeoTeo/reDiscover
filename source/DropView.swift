//
//  DropView.swift
//  reDiscover
//
//  Created by Matteo Sartori on 23/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit

protocol DropViewDelegate {
    func dropViewDidReceiveURL(_ theURL: URL);
}

class DropView : NSView {//, NSDraggingDestination {
    
    var delegate: DropViewDelegate?
    
    @IBOutlet var dropArrowImageView: NSImageView!
    
    override func awakeFromNib() {
        
        // Since the dropArrowImageView sits on top of the view we want to capture drag & drop for,
        // we unregister it so that the underlying view will get the events. //GOTCHA
        dropArrowImageView.unregisterDraggedTypes()
        
        // Register for notifications of URLs and filenames.
        self.register(forDraggedTypes: [NSURLPboardType,NSFilenamesPboardType])
    }
    
    
    /// Method to coordinate with source about the types of drop we handle and it provides.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let dMask = sender.draggingSourceOperationMask()
        // Ensure the sender supports the link operation and assure it we do too.
        if (dMask.rawValue & NSDragOperation.link.rawValue) != 0 {
            return NSDragOperation.generic
        }

        return NSDragOperation()
    }
    
    /// Method to determine whether we can accept the particular drop data.
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.animatesToDestination = false
        return true
    }
    
    // Method to handle the dropped data.
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {

        let pboard = sender.draggingPasteboard()
        let myArray = pboard.types! as NSArray
        
        if myArray.contains(NSURLPboardType),
            let fileURL = NSURL(from: pboard) {
            delegate?.dropViewDidReceiveURL(fileURL as URL)
        }
        
        return true
    }
    
//    override func concludeDragOperation(sender: NSDraggingInfo!) {
//        println("Drag operation concluded.")
//    }
}
