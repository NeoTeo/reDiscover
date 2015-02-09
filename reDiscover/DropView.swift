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
    func dropViewDidReceiveURL(theURL: NSURL);
}

class DropView : NSView, NSDraggingDestination {
    
    var delegate: DropViewDelegate?
    
    @IBOutlet var dropArrowImageView: NSImageView!
    
    override func awakeFromNib() {
        
        // Since the dropArrowImageView sits on top of the view we want to capture drag & drop for,
        // we unregister it so that the underlying view will get the events. //GOTCHA
        dropArrowImageView.unregisterDraggedTypes()
        
        // Register for notifications of URLs and filenames.
        self.registerForDraggedTypes([NSURLPboardType,NSFilenamesPboardType])
    }
    
    
    /// Method to coordinate with source about the types of drop we handle and it provides.
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        let dMask = sender.draggingSourceOperationMask()
        // Ensure the sender supports the link operation and assure it we do too.
        if (dMask.rawValue & NSDragOperation.Link.rawValue) != 0 {
            return NSDragOperation.Generic
        }

        return NSDragOperation.None
    }
    
    /// Method to determine whether we can accept the particular drop data.
    override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        sender.animatesToDestination = false
        return true
    }
    
    // Method to handle the dropped data.
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {

        let pboard = sender.draggingPasteboard()
        let myArray = pboard.types! as NSArray
        
        if myArray.containsObject(NSURLPboardType) {
            let fileURL = NSURL(fromPasteboard: pboard)
            delegate?.dropViewDidReceiveURL(fileURL!)
        }
        
        return true
    }
    
//    override func concludeDragOperation(sender: NSDraggingInfo!) {
//        println("Drag operation concluded.")
//    }
}