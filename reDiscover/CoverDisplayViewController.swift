//
//  CoverDisplayViewController.swift
//  reDiscover
//
//  Created by Teo on 15/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

@objc
public protocol CoverDisplayViewController {
    
}


public class TGCoverDisplayViewController: NSViewController, CoverDisplayViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var coverCollectionView: NSCollectionView!
    
    //MARK: NSCollectionViewDataSource methods
    public func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 16
    }
    
    public func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItemWithIdentifier("Cover", forIndexPath: indexPath)
        // Find the referenced image and connect it to the item
        let image = NSImage(named: "fetchingArt")
        item.representedObject = image
        item.imageView?.image = image
        return item
    }
    
    public func collectionView(collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> NSView {
        return NSView()
    }
    
}