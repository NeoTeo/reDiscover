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
    
    //: Return a song id given a column, row coordinate position
     func songIdFromGridPos(gridPos: NSPoint) -> SongIDProtocol?
    
}

// Override the NSCollectionView's mouseDown so it isn't swallowed by the default implementation.
extension NSCollectionView {
    override public func mouseDown(theEvent: NSEvent) {
        self.nextResponder?.mouseDown(theEvent)
    }
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
    
    private var currentIdxPath: NSIndexPath?
    
    public override func awakeFromNib() {

        coverCollectionView.selectable = true
        // Watch for changes to the CollectionView's selection, just so we can update our status display.
//        coverCollectionView.addObserver(self, forKeyPath:"selectionIndexPaths" , options: .New, context: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSongs:", name: "NewSongAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCovers:", name: "songCoverUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "boundsChanged:", name: NSScrollViewDidLiveScrollNotification, object: nil)
        let trackingRect = NSMakeRect(0, 0, self.view.frame.width, self.view.frame.height)
        let trackingArea = NSTrackingArea(rect: trackingRect, options: [.MouseEnteredAndExited, .MouseMoved, .ActiveInKeyWindow], owner: self, userInfo: nil)
        //coverCollectionView.addTrackingArea(trackingArea)
        self.view.addTrackingArea(trackingArea)
        
        print("the TGCoverDisplayViewController view is \(self.view)")
    }

    //: Called when mouse down on covers (if we've added an observer for seletionIndexPaths).
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (object === coverCollectionView) && (keyPath == "selectionIndexPaths") {
            print("selected index paths \(coverCollectionView.selectionIndexPaths)")
            
        } else {
            print("Bada Boom")
        }
    }
    
//    override public func mouseDown(theEvent: NSEvent) {
//        print("balls")
//        NSResponder.printResponderChain(self)
//    }

    public override func mouseMoved(theEvent: NSEvent) {
        
        // Convert the mouse pointer coordinates to the coverCollectionView coordinates. 
        // This does takes scrolling into consideration.
        let loc = coverCollectionView.convertPoint(theEvent.locationInWindow, fromView: nil)
        if let (item, idxPath) = coverAndIdxAtLocation(loc) where idxPath != currentIdxPath {
            
            // Store it so I can bail out above (Do I really need this?)
            currentIdxPath = idxPath
            print("The item and index is \(item) \(idxPath)")
            
            // At this point we don't know yet if the cover has been uncovered.
            var songId = mappedSongIds[idxPath.item]

            // Not yet uncovered. So we pick a random song from the unmapped songs.
            if songId == nil {
                print("unCover!")
                // get random songId from unmapped and add it to the mapped
                let unmappedCount = UInt32(unmappedSongIdArray.count)
                let randIdx = arc4random_uniform(unmappedCount)
                
                songId = unmappedSongIdArray.removeAtIndex(Int(randIdx))
                mappedSongIds[idxPath.item] = songId
            }
            
//            if let song = SongPool.songForSongId(songId!),
//                let image = SongArt.artForSong(song) {
//                item.representedObject = CoverImage(image: image)
//            }
            
            postNotificationOfSelection(songId!, atIndex: idxPath.item)
            
//            item.view.layer?.cornerRadius = 8
            item.CoverLabel.stringValue = "mouse over"
            
//            let tmpSong = SongPool.songForSongId(songId!)!
//            print("Title: \(tmpSong.metadata?.title) for songId : \(songId)")
        }
    }
    
    
    func postNotificationOfSelection(songId: SongIDProtocol, atIndex idx: Int) {
        // 1) Package the context in a data structure.
        // 2) post notification with the context.
        //FIXME: For now we bodge the speed vector. And the dims.
        
        let (cols, rows) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()

        let y = Int(floor(CGFloat(idx / cols)))
        let x = Int(floor(CGFloat(idx - (cols * y))))
        let loc = NSMakePoint(CGFloat(x), CGFloat(y))
        
        print("cols \(cols) and rows \(rows), x \(x) and y \(y)")
        
        //let dims = NSMakePoint(CGFloat(coverCollectionView.maxNumberOfColumns), CGFloat(coverCollectionView.maxNumberOfRows))
        let dims = NSMakePoint(CGFloat(cols), CGFloat(rows))
        let context = TGSongSelectionContext(selectedSongId: songId, speedVector: NSMakePoint(1, 1), selectionPos: loc, gridDimensions: dims)
        
        NSNotificationCenter.defaultCenter().postNotificationName("userSelectedSong", object: context)
        
    }
    
    
    func coverAndIdxAtLocation(location: NSPoint) -> (TGCollectionCover, NSIndexPath)? {
        
        if let idxPath = coverCollectionView.indexPathForItemAtPoint(location),
            let cover = coverCollectionView.itemAtIndex(idxPath.item) as? TGCollectionCover {
                return (cover, idxPath)
        }
        return nil
    }
    
    //: Return the songId found at the position in the grid. Nil if not found.
    public func songIdFromGridPos(gridPos: NSPoint) -> SongIDProtocol? {
        
        return mappedSongIds[indexFromGridPos(gridPos)]
    }

    // Convert from a column and row coordinate point to a flat index.
    func indexFromGridPos(gridPos: NSPoint) -> Int {
        
        let (cols, _) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()
        
        return Int(gridPos.y) * cols + Int(gridPos.x)
    }
    
    func boundsChanged(theEvent: NSEvent) {
        print("Scrollage")
    }
    
     func updateSongs(notification: NSNotification) {
        if let songId = notification.object as? SongIDProtocol {
            // Internally (from methods) it's ok to mutate the array.
            // How can we know if the songIDProtocol object is value or reference type?
            // And so how can we know if the unmappedSongIdArray is value or reference based?
            //FIXME:
            unmappedSongIdArray.append(songId)

            // The next empty index is the same as the songCount (number of songs in collection).
            let newIndexPath = NSIndexPath(forItem: songCount, inSection: 0)
            songCount++
            
            // insertItemsAtIndexPaths wants a set, so we make a set.
            let indexPaths: Set<NSIndexPath> = [newIndexPath]
            
            // collection view flips if we do this off the main queue, so The Dude abides.
            dispatch_async(dispatch_get_main_queue()){
                self.coverCollectionView.insertItemsAtIndexPaths(indexPaths)
            }
        }
    }
    
    
    func updateCovers(notification: NSNotification) {
        print("Cover update")
      // We should call the cover animation from here.
        
        // How to get from songId to indexPath
        if let songId = notification.object as? SongIDProtocol {
            let mappedSongIdArray = mappedSongIds.filter { $1.isEqual(songId) }.map { return $0.0 }
            if mappedSongIdArray.count == 1 {
                let idx = mappedSongIdArray[0]
                let newIndexPath = NSIndexPath(forItem: idx, inSection: 0)
                let iPaths: Set<NSIndexPath> = [newIndexPath]
                print("reloading at \(newIndexPath)")
                dispatch_async(dispatch_get_main_queue()){
                    self.coverCollectionView.reloadItemsAtIndexPaths(iPaths)
                }
            }
        }
    }
    //MARK: NSCollectionViewDataSource methods
//    public func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
//        return 1
//    }
    
    public func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return songCount
    }
    
    public func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        print("returning item for index \(indexPath)")
        let item = collectionView.makeItemWithIdentifier("Cover", forIndexPath: indexPath) as! TGCollectionCover
        item.CoverLabel.stringValue = "covered"
        var image: NSImage?
        // If the indexpath is not associated with a song, pick a random unassigned
        // song and associate them, then return the item.
        // Find the referenced image and connect it to the item
        if let songId = mappedSongIds[indexPath.item] {
            image = SongArt.artForSong(SongPool.songForSongId(songId)!)
            item.CoverLabel.stringValue = "mapped & uncovered"
//            item.view.layer?.cornerRadius = 8
        } else {
            item.CoverLabel.stringValue = "covered"
        }
        
        if image == nil {
            print("image was nil")
            image = NSImage(named: "songImage")
        }
        

//        let image = NSImage(named: "fetchingArt")
        print("the image is \(image)")
        let obj = CoverImage(image: image!)
        item.representedObject = obj
        item.view.layer?.cornerRadius = 8
        return item
    }
    
//    public func collectionView(collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> NSView {
//        return NSView()
//    }
    
}

//: Extend the flow layout to provide column and row coordinates of its layout.
extension NSCollectionViewFlowLayout {
    
    func colsAndRowsFromLayout() -> (Int, Int) {
        let contSize = collectionViewContentSize()
        let iSpacing = minimumInteritemSpacing
        let lSpacing = minimumLineSpacing
        let inset = sectionInset
        
        let cols = Int(ceil((contSize.width - (inset.left + inset.right)) / (itemSize.width+iSpacing)))
        let rows = Int(ceil((contSize.height - (inset.top + inset.bottom)) / (itemSize.height+lSpacing)))
        return (cols, rows)
    }

}