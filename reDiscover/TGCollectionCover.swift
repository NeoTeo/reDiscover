//
//  TGCollectionCover.swift
//  reDiscover
//
//  Created by Teo on 15/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Cocoa

/*
An NSCollectionViewItem that visually represents a CoverImage in an
NSCollectionView.  A TGCollectionCover's "representedObject" property points to its
CoverImage.
*/
class TGCollectionCover: NSCollectionViewItem {

    @IBOutlet weak var CoverLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
