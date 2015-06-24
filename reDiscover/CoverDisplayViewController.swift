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

/*:
The way we randomize the songs for display is/was:
Upon loading of each song by the song pool we add it to an array of unmapped items.
As a new item is requested by the collection view we pick an unmapped song at 
random and associate it the requested index path so that any subsequent requests for
that particular index path will result in the same item.
*/
public class TGCoverDisplayViewController: NSViewController, CoverDisplayViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var coverCollectionView: NSCollectionView!
    
    private var unmappedSongIdArray: [SongIDProtocol] = []
    private var mappedSongIds: [Int:SongIDProtocol] = [:]
    private var songCount = 0
    
    
    
    public override func awakeFromNib() {

        coverCollectionView.selectable = true
        // Watch for changes to the CollectionView's selection, just so we can update our status display.
        coverCollectionView.addObserver(self, forKeyPath:"selectionIndexPaths" , options: .New, context: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSongs:", name: "NewSongAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCovers:", name: "songCoverUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "boundsChanged:", name: NSScrollViewDidLiveScrollNotification, object: nil)
        let trackingRect = NSMakeRect(0, 0, self.view.frame.width, self.view.frame.height)
        let trackingArea = NSTrackingArea(rect: trackingRect, options: [.MouseEnteredAndExited, .MouseMoved, .ActiveInKeyWindow], owner: self, userInfo: nil)
        coverCollectionView.addTrackingArea(trackingArea)
    }
//    - (void)newSongAdded:(NSNotification*)notification {
//    // TGLog(TGLOG_REFAC,@"newSongAdded with %@",songId);
//    id<SongIDProtocol> songId = (id<SongIDProtocol>)notification.object;
//    [self songPoolDidLoadSongURLWithID:songId];
//    //REFAC
//    [_coverDisplayController.view setNeedsDisplay:YES];
//    }
//    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (object == imageCollectionView && [keyPath isEqual:selectionIndexPathsKey]) {
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (object === coverCollectionView) && (keyPath == "selectionIndexPaths") {
            print("selected index paths \(coverCollectionView.selectionIndexPaths)")
            
        } else {
            print("Bada Boom")
        }
    }
    
    public override func mouseMoved(theEvent: NSEvent) {
        
        // Convert the mouse pointer coordinates to the coverCollectionView coordinates. 
        // This does takes scrolling into consideration.
        let loc = coverCollectionView.convertPoint(theEvent.locationInWindow, fromView: nil)
        
        if let idxPath = coverCollectionView.indexPathForItemAtPoint(loc) {
            print("The index is \(idxPath)")
//            let paths: Set<NSIndexPath> = [idxPath]
//            coverCollectionView.selectItemsAtIndexPaths(paths, scrollPosition: .None)
            if let item = coverCollectionView.itemAtIndex(idxPath.item) as? TGCollectionCover {
                item.view.layer?.cornerRadius = 80
                item.CoverLabel.stringValue = "Arse"
            }
        }

    }
    
    func boundsChanged(theEvent: NSEvent) {
        print("Scrollage")
    }
    
     func updateSongs(notification: NSNotification) {
        if let songId = notification.object as? SongIDProtocol {
            // Internally (from methods) it's ok to mutate the array.
            // How can we know if the songIDProtocol object is value or reference type?
            // And so how can we know if the unmappedSongIdArray is value or reference based?
            unmappedSongIdArray.append(songId)
            // defensive copying - bah

            print("Added song with id: \(songId)")
            songCount++
            coverCollectionView.reloadData()
        }
    }
    
    func updateCovers(notification: NSNotification) {
        coverCollectionView.reloadData()
        print("Cover update")
    }
    //MARK: NSCollectionViewDataSource methods
//    public func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
//        return 1
//    }
    
    public func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return songCount
    }
    
    public func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        var image: NSImage?
        // If the indexpath is not associated with a song, pick a random unassigned
        // song and associate them, then return the item.
        // Find the referenced image and connect it to the item
        if let songId = mappedSongIds[indexPath.item] where indexPath.item < mappedSongIds.count {
            image = SongArt.artForSong(SongPool.songForSongId(songId)!)
        } else {
            // get r!andom songId from unmapped and add it to the mapped
            let unmappedCount = UInt32(unmappedSongIdArray.count)
            let randIdx = arc4random_uniform(unmappedCount)
            
            let songId = unmappedSongIdArray[Int(randIdx)]
            image = SongArt.artForSong(SongPool.songForSongId(songId)!)
            if image != nil {
                unmappedSongIdArray.removeAtIndex(Int(randIdx))
                mappedSongIds[indexPath.item] = songId
            } else {
              image = NSImage(named: "fetchingArt")
            }
        }
        let item = collectionView.makeItemWithIdentifier("Cover", forIndexPath: indexPath)
//        let image = NSImage(named: "fetchingArt")
        let obj = CoverImage(image: image)
        item.representedObject = obj

        return item
    }
    
    public func collectionView(collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> NSView {
        return NSView()
    }
    
}