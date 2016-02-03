//
//  CoverDisplayViewController.swift
//  reDiscover
//
//  Created by Teo on 15/06/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa


public protocol CoverDisplayViewControllerDelegate {
    
    /// For TGCoverDisplayViewController
    func getSong(songId : SongIDProtocol) -> TGSong?
    func getArt(artId : String) -> NSImage?
    
    /// For TimelinePopoverViewControllerDelegate
    func getSongDuration(songId : SongIDProtocol) -> NSNumber?
    func getSweetSpots(songId : SongIDProtocol) -> Set<SweetSpot>?
    func userSelectedSweetSpot(index : Int)
}

public class TGCoverDisplayViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var coverCollectionView: CoverCollectionView!
    
    private var unmappedSongIdArray: [SongIDProtocol] = []
    private var mappedSongIds: [Int:SongIDProtocol] = [:]
    private var songCount = 0

    private var currentTrackingArea: NSTrackingArea?
    private var currentIdxPath: NSIndexPath?
    private var songUIController: TGSongUIPopupController?
    public var songTimelineController: TimelinePopoverViewController?
//    public var songTimelineController: TGSongTimelineViewController?
    
    var delegate : CoverDisplayViewControllerDelegate?
    
    private var collectionAccessQ: dispatch_queue_t = dispatch_queue_create("collectionAccessQ", DISPATCH_QUEUE_SERIAL)
    
    public override func awakeFromNib() {

//        print("TGCoverDisplayViewController awake")
//        print("    The coverCollectionView is \(coverCollectionView)")
//        coverCollectionView.selectable = true
        // Watch for changes to the CollectionView's selection, just so we can update our status display.
//        coverCollectionView.addObserver(self, forKeyPath:"selectionIndexPaths" , options: .New, context: nil)
        
    }

    public override func viewDidLoad() {
        
        initializeObservers()
        
        initializeUIController()
        
        initializeTimelinePopover()
    }
        
    func initializeObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSongs:", name: "NewSongAdded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCovers:", name: "songCoverUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "boundsChanged:", name: NSScrollViewDidLiveScrollNotification, object: nil)
    }
    
    public override func viewWillLayout() {
        currentTrackingArea = replaceTrackingArea(currentTrackingArea, fromView: self.view)
    }
    
    func replaceTrackingArea(oldTrackingArea: NSTrackingArea?, fromView theView: NSView) -> NSTrackingArea {
        if let oldTA = oldTrackingArea {
            theView.removeTrackingArea(oldTA)
        }
        let trackingRect = NSMakeRect(0, 0, theView.frame.width, theView.frame.height)
        let newTrackingArea = NSTrackingArea(rect: trackingRect, options: [.MouseEnteredAndExited, .MouseMoved, .ActiveInKeyWindow], owner: self, userInfo: nil)
        
        theView.addTrackingArea(newTrackingArea)

        return newTrackingArea
    }
    
    func initializeTimelinePopover() {
        //songTimelineController = TGSongTimelineViewController(nibName: "TGSongTimelineView", bundle: nil)
        songTimelineController = TimelinePopoverViewController(nibName: "TGSongTimelineView", bundle: nil)
        
        songTimelineController!.delegate = self
        songTimelineController?.view
    }

    func initializeUIController() {
        
        // Load the UIPopup if it hasn't already been.
        if songUIController == nil {
            songUIController = TGSongUIPopupController(nibName: "TGSongUIPopupController", bundle: nil)
            
            // let the UI controller know we will handle button presses.
            songUIController?.delegate = self
            
            // Initiall the UI is invisible
            songUIController?.showUI(false)
            
            // Add it to the view hierarchy.
            self.view.addSubview(songUIController!.view)
        }
        
    }
    //: Called when mouse down on covers (if we've added an observer for seletionIndexPaths).
//    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        
//        if (object === coverCollectionView) && (keyPath == "selectionIndexPaths") {
//        } else {
//            print("Bada Boom")
//        }
//    }
    
    override public func mouseDown(theEvent: NSEvent) {

        // Show the UI for the item that was clicked.
        
        // Get the location of the mouse event and convert it to the collection view coordinates.
        let location = coverCollectionView.convertPoint(theEvent.locationInWindow, fromView: nil)
        
        // The the index from the location
        if let idxPath = coverCollectionView.indexPathForItemAtPoint(location) {

            // Get the frame of the item use it to make a new frame in the collection view coordinates
            let itemFrame = coverCollectionView.frameForItemAtIndex(idxPath.item)
            let newPos = self.view.convertPoint(itemFrame.origin, fromView: coverCollectionView)
            let newFrame = CGRectMake(newPos.x, newPos.y-itemFrame.size.height, itemFrame.size.width, itemFrame.size.height)

            // Show the UI inside the frame we've created.
            songUIController!.showInside(!songUIController!.isUIActive(), frame: newFrame)
        }
    }

    public override func mouseMoved(theEvent: NSEvent) {
        
        // Convert the mouse pointer coordinates to the coverCollectionView coordinates. 
        // This does takes scrolling into consideration.
        uncoverSongCover(atLocationInWindow: theEvent.locationInWindow)
    }

    /*:
    Uncover covered song covers.
    Uncovering a song means picking a random song from the covered songs.
    
    The way we randomize the songs for display is:
    Upon notification of a song added (updateSongs) we add its id to an array of unmapped ids.
    As a new item is requested by the collection view we pick an unmapped song id at
    random and associate it the requested index path so that any subsequent requests for
    that particular index path will result in the same id.
    
    */
    func uncoverSongCover(atLocationInWindow location: NSPoint) {
        let loc = coverCollectionView.convertPoint(location, fromView: nil)
        if let (item, idxPath) = coverAndIdxAtLocation(loc) where idxPath != currentIdxPath {
            dispatch_async(collectionAccessQ){
            // Store it so I can bail out above (Do I really need this?)
            self.currentIdxPath = idxPath
//            print("The item and index is \(item) \(idxPath)")
            
            //: At this point we don't know yet if the cover has been uncovered.
            //: If a songId is found in the mappedSongIds it means it has already been uncovered.
            var songId = self.mappedSongIds[idxPath.item]
            
            // Not yet uncovered. So we pick a random song from the unmapped songs.
            if songId == nil {
                // remove a random songId from unmapped and add it to the mapped
                let unmappedCount = UInt32(self.unmappedSongIdArray.count)
                let randIdx = arc4random_uniform(unmappedCount)
                //FIXME: concurrent access here? - consider making safe accessors for the arrays instead
                // This shit is locking/slowing everything down.
                
                    songId = self.unmappedSongIdArray.removeAtIndex(Int(randIdx))
                    self.mappedSongIds[idxPath.item] = songId
                
            }
            
            // Let anyone interested know the user has selected songId
            self.postNotificationOfSelection(songId!, atIndex: idxPath.item)
            }
            item.CoverLabel.stringValue = "fetching art..."
            // At this point we should probably initiate a cover animation.
            
        }
    }
    
    func postNotificationOfSelection(songId: SongIDProtocol, atIndex idx: Int) {
        // 1) Package the context in a data structure.
        // 2) post notification with the context.
        //FIXME: For now we bodge the speed vector.
        let bogusSpeedVector = NSMakePoint(1, 1)
        
        // Get the dimensions in rows and columns of the current cover collection layout.
        let (cols, rows) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()

        // Compute the column and row location of the given index.
        let y = Int(floor(CGFloat(idx / cols)))
        let x = Int(floor(CGFloat(idx - (cols * y))))
        let loc = NSMakePoint(CGFloat(x), CGFloat(y))
        
//        print("cols \(cols) and rows \(rows), x \(x) and y \(y)")
        
        let dims = NSMakePoint(CGFloat(cols), CGFloat(rows))
        let context = TGSongSelectionContext(selectedSongId: songId, speedVector: bogusSpeedVector, selectionPos: loc, gridDimensions: dims, cachingMethod: .Square)
        
        NSNotificationCenter.defaultCenter().postNotificationName("userSelectedSong", object: context)
        
    }
    
    
    func coverAndIdxAtLocation(location: NSPoint) -> (TGCollectionCover, NSIndexPath)? {
        
        if let idxPath = coverCollectionView.indexPathForItemAtPoint(location),
            let cover = coverCollectionView.itemAtIndex(idxPath.item) as? TGCollectionCover {
                return (cover, idxPath)
        }
        return nil
    }
    
    /** Return the songId found at the position in the grid. Nil if not found.
        Not that if a cover at the given grid position hasn't been mapped to a song
        the method will return an empty optional.
    */
    public func songIdFromGridPos(gridPos: NSPoint) -> SongIDProtocol? {
        
        // Ask the flow layout for an index given a grid position.
        let index = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).indexFromGridPos(gridPos)
//        if let index = coverCollectionView.indexPathForItemAtPoint(gridPos) {
            return mappedSongIds[index]
//        } else {
//            return nil
//        }
    }
    
    func boundsChanged(theEvent: NSEvent) {
        // if the song ui is not showing allow scrolling
        // scrolling should also be able to select songs so call uncoverSong.
        //print("Scrollage")
    }
    /*: 
        Called when a new song with songId is added.
        Adds the new songId to the unmapped songs and inserts it into the coverCollectionView
        as a covered album cover so the user can see the collection grow as songs are loaded.
        This method can be called async'ly off the main thread so we must be careful about 
        concurrency issues with accessing the unmappedSongIdArray and incrementing the songCount, etc.
        This is done via an access queue.
    */
    func updateSongs(notification: NSNotification) {
        if let songId = notification.object as? SongIDProtocol {
            // Internally (from methods) it's ok to mutate the array.
            // How can we know if the songIDProtocol object is value or reference type?
            // And so how can we know if the unmappedSongIdArray is value or reference based?
            //FIXME:
            // queue the access to the collection up serially.
            dispatch_async(collectionAccessQ) {
                self.unmappedSongIdArray.append(songId)

                // The next empty index is the same as the songCount (number of songs in collection).
                let newIndexPath = NSIndexPath(forItem: self.songCount, inSection: 0)
                self.songCount += 1
                
                // insertItemsAtIndexPaths wants a set, so we make a set.
                let indexPaths: Set<NSIndexPath> = [newIndexPath]
                
                // collection view flips if we do this off the main queue, so The Dude abides.
                // crashes with an EXC_BAD_ACCESS if we scroll down to catch up with the songs being added.
                // It doesn't matter that the item index is 0 or the last (songCount) it still throws
                // (and this is probably significant) when I scroll to the bottom - is this an animation thing?
                // Enabling zombie objects in the scheme reveals that the crash occurs in the animation code with the 
                // error: "*** -[UIViewAnimationContext completionHandler]: message sent to deallocated instance". 
                // This smells like another Apple bug.
                dispatch_sync(dispatch_get_main_queue()){
                    //print("idxPaths \(indexPaths) and songCount = \(self.songCount)")
                    self.coverCollectionView.insertItemsAtIndexPaths(indexPaths)
               }
            }
        }
    }
    
    
    /**:
        Called when a song with songId has loaded its cover art.
    */
    func updateCovers(notification: NSNotification) {
//        print("Cover update")
      // We should call the cover fade-in animation from here.
/* This is not working in b3
        // Not sure this is the best way – O(n), but for now it works.
        // Traverse all the mapped songs dictionary looking for a match with songId.
        // If a match is found we reload only the item at the given index.
        // For the default nine item grid it is probably just as fast to just reload all 
        // the visible items, but it doesn't scale well if we decided to allow arbitrary
        // sizes of grids.
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
*/
        dispatch_async(dispatch_get_main_queue()){
            self.coverCollectionView.reloadData()
        }
    }
}

/*
//MARK: TGSongTimelineViewControllerProtocol methods
extension TGCoverDisplayViewController: TGSongTimelineViewControllerDelegate {
    
    public func userCreatedNewSweetSpot(sender: AnyObject!) {
        print("user created new sweet spot")
    }
    
    public func userSelectedExistingSweetSpot(sender: AnyObject!) {
        print("user selected existing sweet spot")
    }
    
    public func userSelectedSweetSpotMarkerAtIndex(ssIndex: UInt) {
        print("user selected sweet spot marker at index")
    }
    

}
*/
//MARK: TGSongUIPopupProtocol methods
extension TGCoverDisplayViewController: TGSongUIPopupProtocol {
    
    func songUITimelineButtonWasPressed() {
        
        // The button's coords are relative to its's view so we need to convert.
        let bDims = songUIController!.timelineButton.frame
        let location = self.view.convertPoint(bDims.origin, fromView: songUIController!.view)
        // <ake a new frame.
        let popupBounds = NSMakeRect(location.x, location.y, bDims.width, bDims.height)

//        songTimelineController?.toggleTimelinePopoverRelativeToBounds(popupBounds, ofView: self.view)
    songTimelineController?.togglePopoverRelativeToBounds(popupBounds, ofView: self.view)
    }
    
    func songUIPlusButtonWasPressed() {
        print("Go plus")
    }
    
    func songUIGearButtonWasPressed() {
        print("Go gear")
    }
    
    func songUIInfoButtonWasPressed() {
        print("Go info")
    }
}

//MARK: NSCollectionViewDataSource methods
extension TGCoverDisplayViewController: NSCollectionViewDataSource {

    //    public func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
    //        return 1
    //    }

    public func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return songCount
    }
    
    public func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
//print("Datasource request for \(indexPath)")
        let item = collectionView.makeItemWithIdentifier("Cover", forIndexPath: indexPath) as! TGCollectionCover
        item.CoverLabel.stringValue = ""
        
        
        var image: NSImage?
        // If the indexpath is not associated with a song, pick a random unassigned
        // song and associate them, then return the item.
        // Find the referenced image and connect it to the item

        if let songId = mappedSongIds[indexPath.item],
            let song = delegate?.getSong(songId) {
                
            if let artId = song.artID {
                image = delegate?.getArt(artId)
            }
            // If we couldn't find any art set the image to no cover rather than the back cover.
            if image == nil {
                image = NSImage(named: "noCover")
            }
        }
        
        if image == nil {
            // Set the image to a back cover.
            image = NSImage(named: "songImage")
        }
        
        let obj = CoverImage(image: image!)
        
        item.representedObject = obj
        item.view.layer?.cornerRadius = 4

        return item
    }
    
//    public func collectionView(collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> NSView {
//        return NSView()
//    }
    
}

extension TGCoverDisplayViewController : TimelinePopoverViewControllerDelegate {

    func getSongDuration(songId : SongIDProtocol) -> NSNumber? {
        return delegate?.getSongDuration(songId)
    }
    
    func getSweetSpots(songId: SongIDProtocol) -> Set<SweetSpot>? {
        return delegate?.getSweetSpots(songId)
    }
    
    func userSelectedSweetSpot(index : Int) {
        delegate?.userSelectedSweetSpot(index)
    }
}