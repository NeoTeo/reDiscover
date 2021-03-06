//
//  TGSplitViewController.swift
//  reDiscover
//
//  Created by Teo on 09/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation


final public class TGSplitViewController: NSSplitViewController {
 
    @IBOutlet weak var playlistSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var coverCollectionSVI: NSSplitViewItem!
    @IBOutlet weak var songInfoSVI: NSSplitViewItem!
    
    // Shadow the above SplitViewItems' viewControllers because...?
    private var playlistPanelCtrlr : TGPlaylistViewController!
    private var coversPanelCtrlr : TGCoverDisplayViewController!
    private var infoPanelCtrlr : TGSongInfoViewController!
    private var sweetSpotController : SweetSpotController!
    private var objectController : NSObjectController?

    private var songMetadataUpdater : SongMetadataUpdater?
    
    var theURL: NSURL?
    
    var theSongPool : SongPoolAccessProtocol!
    
    private var playbackController = TGSongPlaybackController()
}

extension TGSplitViewController {
    
    /** This view appears as a consequence of a segue from the drop view controller.
        Since the initial window is closed and a new one is created to hold this 
        view we must set it up from here.
    */
    public override func viewDidAppear() {

        /// Ensure we have an URL from the drop view.
        precondition(theURL != nil)

        guard let win = self.view.window else { fatalError("No Window. Exiting.") }
        
        /// Make our window key, frontmost, first responder and main.
        win.makeKeyAndOrderFront(self)
        win.makeFirstResponder(self)
        win.makeMainWindow()
        
        /// Instantiate a song pool. 
        theSongPool = SongPool()
        guard theSongPool != nil else { fatalError() }
        
        connectControllers()

        theSongPool.load(theURL!)
        
        /// Sets up all the notifications we want to listen out for.
        registerNotifications()
        
        setupBindings()
    }
    
    
    /**
        Set up KVO bindings between elements that need to know when songs are playing
        and how far along they are.
    */
    func setupBindings() {

        if objectController == nil {
            objectController = NSObjectController(content: playbackController as AnyObject?)
        }
        
        // Bind the timeline value transformer's maxDuration with the song pool's currentSongDuration.
        let transformer = TGTimelineTransformer()
        
        NSValueTransformer.setValueTransformer(transformer, forName: "TimelineTransformer")
        
        transformer.bind(   "maxDuration",
                            toObject: playbackController as AnyObject,
                            withKeyPath: "currentSongDuration",
                            options: nil)
        
        /** Not sure we really need a progress bar in the playlist but keep for now.
			Also, could have done this via objectController like the other two but
			want to keep this to remind me you can bind directly between two dynamic 
			objects.
		*/
        // Bind the playlist controller's progress indicator value parameter with
        // the song pool's playheadPos via the timeline value transformer.
        playlistPanelCtrlr.playlistProgress?.bind(  "value",
                                                    toObject: playbackController as AnyObject,
                                                    withKeyPath: "playheadPos",
                                                    options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
		
        // Bind the timeline NSSlider (timelineBar) to observe the requestedPlayheadPosition
        // of the currently playing song via the objectcontroller using the TimelineTransformer.
        guard let timeline = coversPanelCtrlr.songTimelineController?.timelineBar else{
            fatalError("TimelineBar missing. Cannot continue.")
        }
        
        timeline.bind(  "value",
                        toObject: objectController!,
                        withKeyPath: "selection.requestedPlayheadPosition",
                        options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
        
        // Bind the selection's (the songpool) playheadPos with the timeline bar
        // cell's currentPlayheadPositionInPercent so we can animate the bar.
        timeline.cell?.bind(	"currentPlayheadPositionInPercent",
                                toObject: objectController!,
                                withKeyPath: "selection.playheadPos",
                                options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
    }

    
    func registerNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(   self,
                                                            selector: "songCoverWasUpdated:",
                                                            name: "songCoverUpdated",
                                                            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(   self,
                                                            selector: "songMetaDataWasUpdated:",
                                                            name: "songMetaDataUpdated",
                                                            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(   self,
                                                            selector: "userSelectedSongInContext:",
                                                            name: "userSelectedSong",
                                                            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(   self,
                                                            selector: "songDidStartUpdating:",
                                                            name: "songDidStartUpdating",
                                                            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(   self,
                                                            selector: "userCreatedSweetSpot:",
                                                            name: "UserCreatedSweetSpot",
                                                            object: nil)

    }
    
    // Make sure dependent controllers can access each other
    //FIXME: Find better way for this - 
    // eg make the methods that the playlist controller needs available as class methods in SongPool.
    func connectControllers() {
        
        playlistPanelCtrlr              = playlistSplitViewItem.viewController as! TGPlaylistViewController
        coversPanelCtrlr                = coverCollectionSVI.viewController as! TGCoverDisplayViewController
        infoPanelCtrlr                  = songInfoSVI.viewController as! TGSongInfoViewController
        
        sweetSpotController             = SweetSpotController()
        sweetSpotController.delegate    = self

        playbackController.delegate     = self
        
        /// FIXME : Make SweetSpotServerIO use delegate
//        SweetSpotServerIO.songPoolAPI   = theSongPool
        coversPanelCtrlr.delegate       = self
        playlistPanelCtrlr.delegate     = self
        
        /// The song pool handles the song metadata updater's requirements
        songMetadataUpdater             = SongMetadataUpdater(delegate: self) //theSongPool)
    }
    
    private func setupPanels() {
        
        // Start off with the side panels collapsed.
        /// TODO: briefly animate the panels to show they exist, highlighting the
        /// buttons that will toggle them.
        playlistSplitViewItem.collapsed = true
        songInfoSVI.collapsed           = true
        
    }
    
    func togglePanel(panelID: Int) {
        
        /** First temporarily set the coverCollectionSplitViewItem's holding priority,
            which should be set < 500 so that it can be resized by a window resize,
            to > 500 (which is the window resize threshold) so that the expanding side
            panels resize the window rather than the central view. 
            Alas, this setting seems to be ignored.
         */

        /// debug
        print("Before toggle, coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
        let prevPriority                    = coverCollectionSVI.holdingPriority

        coverCollectionSVI.holdingPriority = 501

        /// debug
        for item in self.splitViewItems {
            print("holding priority for item \(item): \(item.holdingPriority)")
        }
        
        let splitViewItem = self.splitViewItems[panelID]
        
        // Anchor the appropriate window edge before letting the splitview animate.
        let anchor: NSLayoutAttribute = (panelID == 0) ? .Trailing : .Leading
        
        self.view.window?.setAnchorAttribute(anchor, forOrientation: .Horizontal)
        
        splitViewItem.animator().collapsed = !splitViewItem.collapsed
        
        /// return the coverCollectionSplitViewItem's holding priority to its previous value
        coverCollectionSVI.holdingPriority = prevPriority
        print("Done toggle, coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
    }

    public override func keyDown(theEvent: NSEvent) {

        let string = theEvent.characters!
        
        // Could also use interpretKeyEvents
        for character in string.characters {
            
            switch character {
                
            case "[":
                
                print("Left panel")
                togglePanel(0)
                
            case "]":
                
                print("Right panel")
                togglePanel(2)
                
            case "d":
                
                print("Dump debug")
                playbackController.dumpCacheToLog()

                guard let songId = playbackController.getCurrentlyPlayingSongId() else { break }
                
                theSongPool.debugLogSongWithId(songId)

			case "s":
				print("Save!")
				sweetSpotController.storeSweetSpots()
				
			case "u":
				print("upload sweet spots")
				guard let songId = playbackController.getCurrentlyPlayingSongId() else { break }
				sweetSpotController.promoteSelectedSweetSpot(songId)
				sweetSpotController.uploadSweetSpots(songId)
				
            default:
                break
            }
        }
    }
    
    func userSelectedSong(context : SongSelectionContext) {
        
        let songId      = context.selectedSongId
        let speedVector = context.speedVector
        
        if fabs(speedVector.y) > 2 {
            print("Speed cutoff enabled")
            return
        }
        
        /// do this as part of the requestSongPlayback
        // cacheWithContext(context)

        playbackController.refreshCache(context)
        playbackController.requestSongPlayback(songId)
        
        //// Request updated data for the selected song.
        songMetadataUpdater?.requestUpdatedData(forSongId: context.selectedSongId)

    }
    
    func userSelectedSongInContext(notification: NSNotification) {
        let theContext = notification.object as! SongSelectionContext
        userSelectedSong(theContext)
    }
    
    func requestPlayback(songId: SongId, startTimeInSeconds: NSNumber) {
        /** FIXME : Just do this directly once we're sure everyone is calling
            requestPlayback instead of requestSongPlayback
        */
        playbackController.requestSongPlayback(songId, withStartTimeInSeconds: startTimeInSeconds)
    }
    
    /** This is called when the TGTimelineSliderCell detects that the user has let
        go of the sweet spot slider and thus wants to create a new sweet spot at the
        corresponding time. The song is always the TGSongPool's currentlyPlayingSongId and the
        time is the TGSongPool's requestedPlayheadPosition.
    */
    func userCreatedSweetSpot(notification: NSNotification) {
        
        if let ssTime = playbackController.requestedPlayheadPosition,
            let songId = playbackController.getCurrentlyPlayingSongId() {
        
            sweetSpotController.addSweetSpot(atTime: ssTime, forSongId: songId)
        }
    }
    
    // Notification when a song starts loading/caching. Allows us to update UI to show activity.
    func songDidStartUpdating(notification: NSNotification) {

        if let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let coverImage = SongArt.getFetchingCoverImage() {
            infoPanel.setCoverImage(coverImage)
        }

    }
    // Called when the song metadata is updated and will in turn call the info panel
    // and playback controller to update their data.
    func songMetaDataWasUpdated(notification: NSNotification) {
        
        let songId = notification.object as! SongId
        if songId == playbackController.getRequestedSongId(),
            let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let song = theSongPool.songForSongId(songId) {
                
                infoPanel.setDisplayStrings(withDisplayStrings: song.metadataDict())
                playbackController.updateCurrentSongDuration(song.duration())
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        
        let songId = notification.object as! SongId
        
        if songId == playbackController.getRequestedSongId(),
            let song = theSongPool.songForSongId(songId){
                let infoPanel = songInfoSVI.viewController as! TGSongInfoViewController
                if let artId = song.artID,
                    let art = SongArt.getArt(forArtId: artId) {
                        
                    infoPanel.setCoverImage(art)
                } else {
                    
                    infoPanel.setCoverImage(SongArt.getNoCoverImage()!)
                }
        }
    }
}

extension TGSplitViewController : CoverDisplayViewControllerDelegate {
 
    /// For TGCoverDisplayViewController
    public func getSong(songId : SongId) -> TGSong? {
        
        return theSongPool.songForSongId(songId)
    }
    
    public func getArt(artId : String) -> NSImage? {
        
        /// Static access for now
        return SongArt.getArt(forArtId: artId)
    }
 
    /// For TimelinePopoverViewControllerDelegate
    public func getSongDuration(songId : SongId) -> NSNumber? {
        
        return theSongPool.songForSongId(songId)?.duration()
    }
    
    public func getSweetSpots(songId : SongId) -> Set<SweetSpot>? {
        
        return theSongPool.songForSongId(songId)?.sweetSpots
    }
    
    public func userSelectedSweetSpot(index : Int) {
        
        if let playingSongId = playbackController.getCurrentlyPlayingSongId(),
            let sweetSpots = getSweetSpots(playingSongId) {
                
            let sweetSpotTime = sweetSpots[(sweetSpots.startIndex.advancedBy(index))]
            playbackController.requestedPlayheadPosition = sweetSpotTime
            theSongPool.addSong(withChanges: [.SelectedSS : sweetSpotTime], forSongId: playingSongId)
        }
    }
    
    public func userPressedPlus() {
        
        /// Figure out which song is currently selected
        if let selectedSongId = playbackController.getCurrentlyPlayingSongId() {
			
            playlistPanelCtrlr.addToPlaylist(songWithId: selectedSongId)
        }
    }
}

extension TGSplitViewController : SweetSpotControllerDelegate {
    
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId) {
		
        theSongPool.addSong(withChanges: changes, forSongId: songId)
    }    
}

extension TGSplitViewController : PlaylistViewControllerDelegate {
    
    /// All required methods already declared in the main class.
    func selectIndirectly(songId : SongId) {
        
        guard let coords    = coversPanelCtrlr.getCoverCoordinates(songId) else { return }
        let speedVector     = NSMakePoint(1, 1)
        
        // Get the dimensions in rows and columns of the current cover collection layout.
        let dims			= coversPanelCtrlr.getGridDimensions()
        let context			= TGSongSelectionContext(	selectedSongId: songId,
														speedVector: speedVector,
														selectionPos: coords,
														gridDimensions: dims,
														cachingMethod: .Square)
        
        /// Ask playback controller to refresh the cache and play back the song.
        playbackController.refreshCache(context)
        playbackController.requestSongPlayback(songId, withStartTimeInSeconds: 0)
		
		/// Ask for updated metadata.
        songMetadataUpdater?.requestUpdatedData(forSongId: context.selectedSongId)
    }
}

extension TGSplitViewController : SongPlaybackControllerDelegate {
	
    func getUrl(songId : SongId) -> NSURL? {
		
        return theSongPool.getUrl(songId)
    }
    
    func getSongId(gridPos : NSPoint) -> SongId? {
		
        return coversPanelCtrlr.songIdFromGridPos(gridPos)
    }
}

extension TGSplitViewController : SongMetadataUpdaterDelegate {
	func sendSweetSpotsRequest(songId: SongId) {
		return sweetSpotController.requestSweetSpots(songId)
	}
	
	func isCached(songId : SongId) -> Bool {
		return playbackController.isCached(songId)
	}
}