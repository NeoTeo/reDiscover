//
//  CoverImage.swift
//  reDiscover
//
//  Created by Teo on 22/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

final class CoverImage : NSObject {
    // The dynamic keyword signals that we want access to be dynamically dispatched
    // through Obj-c's runtime so this can be KVO bound.
    dynamic let previewImage: NSImage?
    
    init(image: NSImage) {
        previewImage = image.copy() as? NSImage
    }
}