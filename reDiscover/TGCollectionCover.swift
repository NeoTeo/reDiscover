//
//  TGCollectionCover.swift
//  reDiscover
//
//  Created by Teo on 15/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Cocoa

//: I can't figure out how to make a protocol that both requires the methods I'm
// declaring and the methods of NSCollectionViewItem so there's little point in 
// using a protocol at all here - I'm commenting it out until if figure out how.
//protocol CollectionCover  {
//    var CoverLabel: NSTextField! { get set }
//}

/*:
An NSCollectionViewItem that visually represents a CoverImage in an
NSCollectionView.  A TGCollectionCover's "representedObject" property points to its
CoverImage.
*/
//class TGCollectionCover: NSCollectionViewItem, CollectionCover {
class TGCollectionCover: NSCollectionViewItem {

    @IBOutlet weak var CoverLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

//    override func mouseDown(theEvent: NSEvent) {
//        let location = collectionView.convertPoint(theEvent.locationInWindow, fromView: nil)
//        let idxPath = collectionView.indexPathForItemAtPoint(location)
//        print("mouseDown gives index \(idxPath?.item)")
//        NSResponder.printResponderChain(self)
//    }
}

