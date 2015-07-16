//
//  TGSplitViewController.swift
//  reDiscover
//
//  Created by Teo on 09/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

final public class TGSplitViewController: NSSplitViewController, TGMainViewControllerDelegate {
 
    @IBOutlet weak var playlistSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var coverCollectionSVI: NSSplitViewItem!
    @IBOutlet weak var songInfoSVI: NSSplitViewItem!
    
    // Shadow the above SplitViewItems' viewControllers
    private var playlistPanelCtrlr: TGPlaylistViewController!
    private var coversPanelCtrlr: TGCoverDisplayViewController!
    private var infoPanelCtrlr: TGSongInfoViewController!
    
    private var objectController: NSObjectController?
    
    var theURL: NSURL?
    // Would rather use the Static version
    var theSongPool: TGSongPool?
}


extension TGSplitViewController {
    
    public override func viewDidAppear() {
//        print("TGSplitView did appear. Let's have a look at the views.")
//        view.printAllSubviews()
//        
//        print("playlist \(playlistSplitViewItem.viewController)")
//        print("coverCollection \(coverCollectionSVI.viewController)")
//        print("songInfo \(songInfoSVI.viewController)")
        connectControllers()
        
        // make this the first responder.
        self.view.window?.makeFirstResponder(self)
        
        theSongPool = TGSongPool()
        theSongPool!.loadFromURL(theURL)
        //FIXME: I'd rather this was done by making CoverViewController provide the functionality as class methods.
        theSongPool!.delegate = self
        
        registerNotifications()
        
        setupBindings()
    }
    
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

    }
    
    // Make sure dependent controllers can access each other
    //FIXME: Find better way for this - 
    // eg make the methods that the playlist controller needs available as class methods in SongPool.
    func connectControllers() {
        playlistPanelCtrlr = playlistSplitViewItem.viewController as! TGPlaylistViewController
        coversPanelCtrlr = coverCollectionSVI.viewController as! TGCoverDisplayViewController
        infoPanelCtrlr = songInfoSVI.viewController as! TGSongInfoViewController
        
        playlistPanelCtrlr.songPoolAPI = theSongPool
//        playlistPanelCtrlr.delegate = self

    }
    
    public override func keyDown(theEvent: NSEvent) {

        let string = theEvent.characters!
        // Could also use interpretKeyEvents
        for character in string.characters {
            switch character {
            case "[":
                print("Left panel")
                playlistSplitViewItem.animator().collapsed = !playlistSplitViewItem.collapsed
            case "]":
                print("Right panel")
                songInfoSVI.animator().collapsed = !songInfoSVI.collapsed
            case "d":
                print("Dump debug")
                theSongPool?.debugLogCaches()
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
        theSongPool?.requestSongPlayback(songId)
    }

    // Notification when a song starts loading/caching. Allows us to update UI to show activity.
    func songDidStartUpdating(notification: NSNotification) {
//        let songId = notification.object as! SongID
        let infoPanel = songInfoSVI.viewController as! TGSongInfoViewController
        infoPanel.setSongCoverImage(SongArt.getFetchingCoverImage())

    }
    // Called when the song metadata is updated and will in turn call the info panel
    // to update its data.
    func songMetaDataWasUpdated(notification: NSNotification) {
        let songId = notification.object as! SongID
        if songId.isEqual(theSongPool?.lastRequestedSongId()),
            let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController {
            infoPanel.setSong(theSongPool?.songDataForSongID(songId))
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        let songId = notification.object as! SongID
        if songId.isEqual(theSongPool?.lastRequestedSongId()),
            let song = theSongPool?.songForID(songId){
                let infoPanel = songInfoSVI.viewController as! TGSongInfoViewController
                if let art = SongArt.artForSong(song) {
                    infoPanel.setSongCoverImage(art)
                } else {
                    infoPanel.setSongCoverImage(SongArt.getNoCoverImage())
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