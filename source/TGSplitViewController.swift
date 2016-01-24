//
//  TGSplitViewController.swift
//  reDiscover
//
//  Created by Teo on 09/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

final public class TGSplitViewController: NSSplitViewController {
 
    @IBOutlet weak var playlistSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var coverCollectionSVI: NSSplitViewItem!
    @IBOutlet weak var songInfoSVI: NSSplitViewItem!
    
    // Shadow the above SplitViewItems' viewControllers because...?
    private var playlistPanelCtrlr: TGPlaylistViewController!
    private var coversPanelCtrlr: TGCoverDisplayViewController!
    private var infoPanelCtrlr: TGSongInfoViewController!
    
    private var objectController: NSObjectController?
    
    var theURL: NSURL?
    // Would rather use the Static version
    var theSongPool: TGSongPool?
}


extension TGSplitViewController {
    
    /** This view appears as a consequence of a segue from the drop view controller.
        Since the initial window is closed and a new one is created to hold this 
        view we must set it up from here.
    */
    public override func viewDidAppear() {
//        print("TGSplitView did appear. Let's have a look at the views.")
//        view.printAllSubviews()
//        
//        print("playlist \(playlistSplitViewItem.viewController)")
//        print("coverCollection \(coverCollectionSVI.viewController)")
//        print("songInfo \(songInfoSVI.viewController)")
        connectControllers()
        self.view.window?.makeKeyAndOrderFront(self)
        // make this the first responder.
        self.view.window?.makeFirstResponder(self)
                print("This window: \(self.view.window)")
        print("Is this the window visible \(self.view.window?.visible)")
        print("Does this window have a title bar? \(self.view.window?.hasTitleBar)")
        print("Could this window be a main window? \(self.view.window?.canBecomeMainWindow)")
        self.view.window?.makeMainWindow()
        print("Is this the main window? \(self.view.window?.mainWindow)")
        if let layoutAttribute = self.view.window?.anchorAttributeForOrientation(.Horizontal) {
            print("Horizontal anchor? \(layoutAttribute.rawValue)")
        }
        
        /// Figure out what this window's content hugging priority and 
        /// content compression resistance priorities are.
        print("This view is \(self.view)")
        print("This view's horizontal compression resistance: \(self.view.contentCompressionResistancePriorityForOrientation(.Horizontal))")
        print("This view's horizontal hugging priority: \(self.view.contentHuggingPriorityForOrientation(.Horizontal))")

        theSongPool = TGSongPool()
        theSongPool!.loadFromURL(theURL)
        theSongPool!.coverDisplayAccessAPI = coversPanelCtrlr
        //FIXME: I'd rather this was done by making CoverViewController provide the functionality as class methods.
//        theSongPool!.delegate = self
        
        registerNotifications()
        
        setupBindings()
    }
    
    
    /**
        Set up KVO bindings between elements that need to know when songs are playing
        and how far along they are.
    */
    func setupBindings() {
        
        if objectController == nil {
            objectController = NSObjectController(content: theSongPool)
        }
        // Bind the timeline value transformer's maxDuration with the song pool's currentSongDuration.
        let transformer = TGTimelineTransformer()
        NSValueTransformer.setValueTransformer(transformer, forName: "TimelineTransformer")
        transformer.bind("maxDuration", toObject: theSongPool!, withKeyPath: "currentSongDuration", options: nil)
        
        // Bind the playlist controller's progress indicator value parameter with
        // the song pool's playheadPos via the timeline value transformer.
        playlistPanelCtrlr.playlistProgress?.bind("value",
            toObject: theSongPool!,
            withKeyPath: "playheadPos",
            options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
        
        // Bind the timeline nsslider (timelineBar) to observe the requestedPlayheadPosition 
        // of the currently playing song via the objectcontroller using the TimelineTransformer.
        coversPanelCtrlr.songTimelineController?.timelineBar?.bind("value",
            toObject: objectController!,
            withKeyPath: "selection.requestedPlayheadPosition",
            options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
        
        // Bind the selection's (the songpool) playheadPos with the timeline bar
        // cell's currentPlayheadPositionInPercent so we can animate the bar.
        coversPanelCtrlr.songTimelineController?.timelineBar?.cell?.bind("currentPlayheadPositionInPercent",
            toObject: objectController!,
            withKeyPath: "selection.playheadPos",
            options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
    }
    
    func registerNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songCoverWasUpdated:", name: "songCoverUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songMetaDataWasUpdated:", name: "songMetaDataUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userSelectedSongInContext:", name: "userSelectedSong", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songDidStartUpdating:", name: "songDidStartUpdating", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userCreatedSweetSpot:", name: "UserCreatedSweetSpot", object: nil)

    }
    
    // Make sure dependent controllers can access each other
    //FIXME: Find better way for this - 
    // eg make the methods that the playlist controller needs available as class methods in SongPool.
    func connectControllers() {
        playlistPanelCtrlr = playlistSplitViewItem.viewController as! TGPlaylistViewController
        coversPanelCtrlr = coverCollectionSVI.viewController as! TGCoverDisplayViewController
        infoPanelCtrlr = songInfoSVI.viewController as! TGSongInfoViewController
        
        playlistPanelCtrlr.songPoolAPI = theSongPool
    }
    
    private func setupPanels() {
        // Start off with the side panels collapsed.
        /// TODO: briefly animate the panels to show they exist, highlighting the
        /// buttons that will toggle them.
        playlistSplitViewItem.collapsed = true
        songInfoSVI.collapsed           = true
        
    }
    
    func togglePanel(panelID: Int) {
        
        /** First temporarily set the coverCollectionSplitViewItem's holding priority
            to > 500 (which is the window resize threshold) so that the expanding side
            panels resize the window rather than the central view.
    */

        let prevPriority = coverCollectionSVI.holdingPriority
        print("Before toggle, coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
        coverCollectionSVI.holdingPriority = 502

        print("coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
        let splitViewItem = self.splitViewItems[panelID]
        
        // Anchor the appropriate window edge before letting the splitview animate.
        let anchor: NSLayoutAttribute = (panelID == 0) ? .Trailing : .Leading
        
        self.view.window?.setAnchorAttribute(anchor, forOrientation: .Horizontal)
        
        splitViewItem.animator().collapsed = !splitViewItem.collapsed
        
        /// return the coverCollectionSplitViewItem's holding priority to its previous value
        coverCollectionSVI.holdingPriority = prevPriority
        print("Done toggle, coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
    }

//    private func toggleSidebar(sender: AnyObject?) {
//        <#code#>
//    }
    public override func keyDown(theEvent: NSEvent) {

        let string = theEvent.characters!
        // Could also use interpretKeyEvents
        for character in string.characters {
            switch character {
            case "[":
                print("Left panel")
                //playlistSplitViewItem.animator().collapsed = !playlistSplitViewItem.collapsed
                togglePanel(0)
            case "]":
                print("Right panel")
//                songInfoSVI.animator().collapsed = !songInfoSVI.collapsed
                togglePanel(2)
            case "d":
                print("Dump debug")
                theSongPool?.debugLogCaches()
                case "t":
                print("Toggle sidebar")
                toggleSidebar(self)
            default:
                break
            }
        }
    }
    
    func userSelectedSongInContext(notification: NSNotification) {
        let theContext = notification.object as! SongSelectionContext
        let songId = theContext.selectedSongId
        let speedVector = theContext.speedVector
        
        if fabs(speedVector.y) > 2 {
            print("Speed cutoff enabled")
            return
        }
        
        theSongPool?.cacheWithContext(theContext)
        //theSongPool?.requestSongPlayback(songId)
        SongPool.requestSongPlayback(songId)
    }

    /** This is called when the TGTimelineSliderCell detects that the user has let
        go of the sweet spot slider and thus wants to create a new sweet spot at the
        corresponding time. The song is always the TGSongPool's currentlyPlayingSongId and the
        time is the TGSongPool's requestedPlayheadPosition.
    */
    func userCreatedSweetSpot(notification: NSNotification) {
        if let ssTime = theSongPool?.requestedPlayheadPosition(),
            let songId = theSongPool?.currentlyPlayingSongId() {
            SweetSpotController.addSweetSpot(atTime: ssTime, forSongId: songId)
        }
    }
    
    // Notification when a song starts loading/caching. Allows us to update UI to show activity.
    func songDidStartUpdating(notification: NSNotification) {
//        let songId = notification.object as! SongID
        if let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let coverImage = SongArt.getFetchingCoverImage() {
            infoPanel.setCoverImage(coverImage)
        }

    }
    // Called when the song metadata is updated and will in turn call the info panel
    // to update its data.
    func songMetaDataWasUpdated(notification: NSNotification) {
        let songId = notification.object as! SongID
        if songId.isEqual(theSongPool?.lastRequestedSongId()),
            let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let song = theSongPool?.songForID(songId) {
                infoPanel.setDisplayStrings(withDisplayStrings: song.metadataDict())
//            infoPanel.setSong(theSongPool?.songDataForSongID(songId))
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        
        let songId = notification.object as! SongID
        
        if songId.isEqual(theSongPool?.lastRequestedSongId()),
            let song = theSongPool?.songForID(songId){
                
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

// Method to comply with the TGMainViewControllerDelegate
extension TGSplitViewController {
    
    public func songIdFromGridPos(pos: NSPoint) -> AnyObject! {
        let coverCtrlr = coverCollectionSVI.viewController as! TGCoverDisplayViewController
        return coverCtrlr.songIdFromGridPos(pos)
    }
}

extension NSView {
    private func _printAllSubviews(indentString: String) {
        Swift.print(indentString+"This view is: \(self)")
        for sv in self.subviews {
            sv._printAllSubviews(indentString+"  ")
        }
    }
    
    public func printAllSubviews() {
        _printAllSubviews("|")
    }
}