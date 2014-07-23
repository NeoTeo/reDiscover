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

class DropView : NSView {
    
    var delegate: DropViewDelegate?
    
    @IBOutlet var dropArrowImageView: NSImageView!
    
    override func awakeFromNib() {
        
        // This is necessary to avoid the NSImageView hijacking the drag event. Took me an afternoon to track down.
        dropArrowImageView.unregisterDraggedTypes()
        
        // Register for notifications of URLs and filenames.
        self.registerForDraggedTypes([NSURLPboardType,NSFilenamesPboardType])
    }
    
    override func draggingEntered(sender: NSDraggingInfo!) -> NSDragOperation {
        return NSDragOperation.Link
    }
    
    override func prepareForDragOperation(sender: NSDraggingInfo!) -> Bool {
        return true
    }
    
    override func performDragOperation(sender: NSDraggingInfo!) -> Bool {
        let pboard = sender.draggingPasteboard()
        let myArray = pboard.types as NSArray
        
        if myArray.containsObject(NSURLPboardType) {
            let fileURL = NSURL.URLFromPasteboard(pboard)
            delegate?.dropViewDidReceiveURL(fileURL)
        }
        
        return true
    }
    
}