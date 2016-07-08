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
    func getSong(_ songId : SongId) -> TGSong?
    func getArt(_ artId : String) -> NSImage?
    
    /// For TimelinePopoverViewControllerDelegate
    func getSongDuration(_ songId : SongId) -> NSNumber?
    func getSweetSpots(_ songId : SongId) -> Set<SweetSpot>?
    func userSelectedSweetSpot(_ index : Int)
    
    func userPressedPlus()
}

public class TGCoverDisplayViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var coverCollectionView: CoverCollectionView!
    
    private var unmappedSongIdArray: [SongId] = []
    private var mappedSongIds: [Int:SongId] = [:]
	
	/// The set of uncovered songs.
	private var uncoveredSongIds = Set<SongId>()
	
    private var songCount = 0

    private var currentTrackingArea: NSTrackingArea?
    private var currentIdxPath: IndexPath?
    private var songUIController: TGSongUIPopupController?
    public var songTimelineController: TimelinePopoverViewController?
    
    var delegate : CoverDisplayViewControllerDelegate?
    
    private var collectionAccessQ: DispatchQueue = DispatchQueue(label: "collectionAccessQ", attributes: DispatchQueueAttributes.serial)
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(TGCoverDisplayViewController.updateSongs(_:)), name: "NewSongAdded" as NSNotification.Name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TGCoverDisplayViewController.updateCovers(_:)), name: "songCoverUpdated" as NSNotification.Name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TGCoverDisplayViewController.boundsChanged(_:)), name: NSNotification.Name.NSScrollViewDidLiveScroll, object: nil)
    }
    
    public override func viewWillLayout() {
        currentTrackingArea = replaceTrackingArea(currentTrackingArea, fromView: self.view)
    }
    
    func replaceTrackingArea(_ oldTrackingArea: NSTrackingArea?, fromView theView: NSView) -> NSTrackingArea {
        if let oldTA = oldTrackingArea {
            theView.removeTrackingArea(oldTA)
        }
        let trackingRect = NSRect(x: 0, y: 0, width: theView.frame.width, height: theView.frame.height)
        let newTrackingArea = NSTrackingArea(rect: trackingRect, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        
        theView.addTrackingArea(newTrackingArea)

        return newTrackingArea
    }
    
    func initializeTimelinePopover() {

        songTimelineController = TimelinePopoverViewController(nibName: "TGSongTimelineView", bundle: nil)
        
        songTimelineController!.delegate = self
        // wake that view
        let _ = songTimelineController?.view
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
    
    override public func mouseDown(_ theEvent: NSEvent) {

        // Show the UI for the item that was clicked.
        
        // Get the location of the mouse event and convert it to the collection view coordinates.
        let location = coverCollectionView.convert(theEvent.locationInWindow, from: nil)
        
        // The the index from the location
        if let idxPath = coverCollectionView.indexPathForItem(at: location) {

            // Get the frame of the item use it to make a new frame in the collection view coordinates
            let itemFrame = coverCollectionView.frameForItem(at: (idxPath as NSIndexPath).item)
            
            let newPos = self.view.convert(itemFrame.origin, from: coverCollectionView)
            
            let newFrame = CGRect(  x: newPos.x,
                                    y: newPos.y - itemFrame.size.height,
                                width: itemFrame.size.width,
                               height: itemFrame.size.height)

            // Show the UI inside the frame we've created.
            songUIController!.showInside(!songUIController!.isUIActive(), frame: newFrame)
        }
    }

    public override func mouseMoved(_ theEvent: NSEvent) {
        
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
        
        let loc = coverCollectionView.convert(location, from: nil)
        
        if let (item, idxPath) = coverAndIdxAtLocation(loc) where idxPath != currentIdxPath {
			/** FIXME: How much of this (beside uncoveredSongIds access and mapIndexToCover
				need to be run asyncly? */
            collectionAccessQ.async{
                
                // Store it so I can bail out above (Do I really need this?)
                self.currentIdxPath = idxPath

				guard let songId = self.mapIndexToCover((idxPath as NSIndexPath).item) else {
					fatalError("uncoverSongCover missing song id!")
				}
				
				self.uncoveredSongIds.insert(songId)
                // Let anyone interested know the user has selected songId
                self.postNotificationOfSelection(songId, atIndex: (idxPath as NSIndexPath).item)
            }
            
            /// selecting a new song should hide the song UI.
            self.hideSongUI()
            
            item.CoverLabel.stringValue = "fetching art..."
            // At this point we should probably initiate a cover animation.
            
        }
    }
	
	/** 
		This method assigns a new songId to a given cover grid index and returns
		the songId. If it was already mapped the songId is returned.
	*/
	func mapIndexToCover(_ index : Int) -> SongId? {
		
        /// The cacher can ask for grid indexes greater than the number of songs.
        guard index < songCount else { return nil }
        
		var songId = self.mappedSongIds[index]

		if songId == nil {
			
			let unmappedCount = UInt32(self.unmappedSongIdArray.count)
		
			 if unmappedCount > 0 {
			
				// Remove a random songId from unmapped and add it to the mapped.
				let randIdx		  = Int(arc4random_uniform(unmappedCount))
			print("randIdx = \(randIdx)")
				songId = self.unmappedSongIdArray.remove(at: randIdx)
				self.mappedSongIds[index] = songId
                print("mapped index \(index) to songId \(songId)")
			}
		}
		
		return songId
	}
	
    func postNotificationOfSelection(_ songId: SongId, atIndex idx: Int) {
		
		
        // 1) Package the context in a data structure.
        // 2) post notification with the context.
        //FIXME: For now we bodge the speed vector.
        let bogusSpeedVector = NSPoint(x: 1, y: 1)
        
        // Get the dimensions in rows and columns of the current cover collection layout.
        let (cols, rows) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()

        // Compute the column and row location of the given index.
        let y       = Int(floor(CGFloat(idx / cols)))
        let x       = Int(floor(CGFloat(idx - (cols * y))))
        let loc     = NSPoint(x: CGFloat(x), y: CGFloat(y))
        let dims    = NSPoint(x: CGFloat(cols), y: CGFloat(rows))
        let context = TGSongSelectionContext(
                        selectedSongId: songId,
                           speedVector: bogusSpeedVector,
                          selectionPos: loc,
                        gridDimensions: dims,
                         cachingMethod: .square)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "userSelectedSong"), object: context)
        
    }
    
    
    func coverAndIdxAtLocation(_ location: NSPoint) -> (TGCollectionCover, IndexPath)? {
        
        if let idxPath = coverCollectionView.indexPathForItem(at: location),
            let cover = coverCollectionView.item(at: (idxPath as NSIndexPath).item) as? TGCollectionCover {
                return (cover, idxPath)
        }
        return nil
    }
    
    public func getGridDimensions() -> NSPoint {
        let (cols, rows) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()
        return NSPoint(x: CGFloat(cols), y: CGFloat(rows))
    }
    
    /** Return the coordinates (column, row) of the songId in the song grid.
    */
    public func getCoverCoordinates(_ songId : SongId) -> NSPoint? {
        
        // Get the dimensions in rows and columns of the current cover collection layout.
        let (cols, rows) = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).colsAndRowsFromLayout()
        for row in 0..<rows {
            for col in 0..<cols {
                
                let curPos = NSPoint(x: CGFloat(col), y: CGFloat(row))
                
                if songIdFromGridPos(curPos) == songId {
                    return curPos
                }
            }
        }
        return nil
    }
    
    /** 
		Return the songId found at the position in the grid. 
		If resolvingIsAllowed is true the grid position is resolved to a songId
		if one isn't found in the mappedSongIds. Nil is returned otherwise.
    */
	public func songIdFromGridPos(_ gridPos: NSPoint, resolvingIsAllowed : Bool = false) -> SongId? {
        
        // Ask the flow layout for an index given a grid position.
        let index = (coverCollectionView.collectionViewLayout as! NSCollectionViewFlowLayout).indexFromGridPos(gridPos)
        
        /// Catch indices from grid positions with no songs on.
        guard index < songCount else { return nil }
        
		var songId = mappedSongIds[index]
		
		if songId == nil && resolvingIsAllowed {
			songId = mapIndexToCover(index)
		}
		return songId
    }
    
    /** Called when the user scrolls the cover view. We use this to hide the song
        UI if it is showing. */
    func boundsChanged(_ theEvent: NSEvent) {
        hideSongUI()
    }
    
    func hideSongUI() {
        /// Hide the UI.
        songUIController?.showUI(false)
        
        // Hide timeline
        songTimelineController?.hideTimeline()
    }
    /*: 
        Called when a new song with songId is added.
        Adds the new songId to the unmapped songs and inserts it into the coverCollectionView
        as a covered album cover so the user can see the collection grow as songs are loaded.
        This method can be called async'ly off the main thread so we must be careful about 
        concurrency issues with accessing the unmappedSongIdArray and incrementing the songCount, etc.
        This is done via an access queue.
    */
    func updateSongs(_ notification: Notification) {
        if let songId = notification.object as? SongId {
            // Internally (from methods) it's ok to mutate the array.
            // How can we know if the SongId object is value or reference type?
            // And so how can we know if the unmappedSongIdArray is value or reference based?
            //FIXME:
            // queue the access to the collection up serially.
            collectionAccessQ.async {
                self.unmappedSongIdArray.append(songId)

                // The next empty index is the same as the songCount (number of songs in collection).
                let newIndexPath = NSIndexPath(forItem: self.songCount, inSection: 0) as IndexPath
                
//                let newIndexPath = IndexPath(index: self.songCount)
                
//                let newIndexPath = IndexPath(forItem: self.songCount, inSection: 0)
                self.songCount += 1
                
                // insertItemsAtIndexPaths wants a set, so we make a set.
                let indexPaths: Set<IndexPath> = [newIndexPath]
                
                // collection view flips if we do this off the main queue, so The Dude abides.
                // crashes with an EXC_BAD_ACCESS if we scroll down to catch up with the songs being added.
                // It doesn't matter that the item index is 0 or the last (songCount) it still throws
                // (and this is probably significant) when I scroll to the bottom - is this an animation thing?
                // Enabling zombie objects in the scheme reveals that the crash occurs in the animation code with the 
                // error: "*** -[UIViewAnimationContext completionHandler]: message sent to deallocated instance". 
                // This smells like another Apple bug.
                DispatchQueue.main.sync{
                    //print("idxPaths \(indexPaths) and songCount = \(self.songCount)")
                    self.coverCollectionView.insertItems(at: indexPaths)
               }
            }
        }
    }
    
    
    /**:
        Called when a song with songId has loaded its cover art.
    */
    func updateCovers(_ notification: Notification) {
//        print("Cover update")
      // We should call the cover fade-in animation from here.
/* This is not working properly
        // Not sure this is the best way – O(n), but for now it works.
        // Traverse all the mapped songs dictionary looking for a match with songId.
        // If a match is found we reload only the item at the given index.
        // For the default nine item grid it is probably just as fast to just reload all 
        // the visible items, but it doesn't scale well if we decided to allow arbitrary
        // sizes of grids.
        if let songId = notification.object as? SongId {
            let mappedSongIdArray = mappedSongIds.filter { $1 == songId }.map { return $0.0 }
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
        DispatchQueue.main.async{
            self.coverCollectionView.reloadData()
        }
    }
}

// MARK: TGSongUIPopupProtocol methods
extension TGCoverDisplayViewController: TGSongUIPopupProtocol {
    
    func songUITimelineButtonWasPressed() {
        
        // The button's coords are relative to its's view so we need to convert.
        let bDims       = songUIController!.timelineButton.frame
        let location    = self.view.convert(bDims.origin,from: songUIController!.view)
        
        // Make a new frame.
        let popupBounds = NSRect(   x: location.x,
                                    y: location.y,
                                width: bDims.width,
                               height: bDims.height)

        songTimelineController?.togglePopoverRelativeToBounds(popupBounds, ofView: self.view)
    }
    
    func songUIPlusButtonWasPressed() {
        delegate?.userPressedPlus()
        print("Go plus")
    }
    
    func songUIGearButtonWasPressed() {
        print("Go gear")
    }
    
    func songUIInfoButtonWasPressed() {
        print("Go info")
    }
}

// MARK: NSCollectionViewDataSource methods
extension TGCoverDisplayViewController: NSCollectionViewDataSource {


    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return songCount
    }
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = collectionView.makeItem(withIdentifier: "Cover", for: indexPath) as! TGCollectionCover
        item.CoverLabel.stringValue = ""

		var image : NSImage?
		
        if let songId = mappedSongIds[(indexPath as NSIndexPath).item] where uncoveredSongIds.contains(songId),
            let song = delegate?.getSong(songId) {
		
            if let artId = song.artID {
                image = delegate?.getArt(artId)
            }
		
            // The song has been uncovered but could find no cover art.
            if image == nil {
				/** FIXME: Change this to display a generic blank cover and display
				the song title, album and artist on top.
				*/

                image = NSImage(named: "noCover")
            }
        } else {
            // Set the image to an uncovered / back cover.
            image = NSImage(named: "songImage")
        }
		
		if let _ = mappedSongIds[(indexPath as NSIndexPath).item] {
			image?.lockFocus()
			let cImage = NSImage(named: "cached")
			cImage!.draw(at: item.view.frame.origin, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
			image?.unlockFocus()
		}
		
        let obj = CoverImage(image: image!)
        
        item.representedObject = obj
        item.view.layer?.cornerRadius = 4

        return item
    }
}

extension TGCoverDisplayViewController : TimelinePopoverViewControllerDelegate {

    func getSongDuration(_ songId : SongId) -> NSNumber? {
        return delegate?.getSongDuration(songId)
    }
    
    func getSweetSpots(_ songId: SongId) -> Set<SweetSpot>? {
        return delegate?.getSweetSpots(songId)
    }
    
    func userSelectedExistingSweetSpot(_ index : Int) {
        delegate?.userSelectedSweetSpot(index)
    }
}
