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
    
    var theURL: NSURL?
    // Would rather use the Static version
    var theSongPool: TGSongPool?
}


extension TGSplitViewController {
    
    public override func viewDidAppear() {
        print("TGSplitView did appear. Let's have a look at the views.")
        view.printAllSubviews()
        
        print("playlist \(playlistSplitViewItem.viewController)")
        print("coverCollection \(coverCollectionSVI.viewController)")
        print("songInfo \(songInfoSVI.viewController)")
        
        // make this the first responder.
        self.view.window?.makeFirstResponder(self)
        
        theSongPool = TGSongPool()
        theSongPool!.loadFromURL(theURL)
        
        registerNotifications()
        connectControllers()
    }
    
    func setupBindings() {
        let transformer = NSValueTransformer(forName: "TimelineTransformer")
        transformer?.bind("maxDuration", toObject: theSongPool!, withKeyPath: "currentSongDuration", options: nil)
        
        
    }
    
    func registerTransformer() {
        NSValueTransformer.setValueTransformer(TGTimelineTransformer(), forName: "TimelineTransformer")
    }
    
    func registerNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songCoverWasUpdated:", name: "songCoverUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "songMetaDataWasUpdated:", name: "songMetaDataUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userSelectedSongInContext:", name: "userSelectedSong", object: nil)
    }
    
    // Make sure dependent controllers can access each other
    //FIXME: Find better way for this
    func connectControllers() {
        let plistCtrlr = playlistSplitViewItem.viewController as! TGPlaylistViewController
        plistCtrlr.songPoolAPI = theSongPool
//        plistCtrlr.delegate = self
        
        //let infoCtrlr = playlistSplitViewItem.viewController as! TGSongInfoViewController

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
    
    //FIXME:
    // This notification should be caught by the info view itself!
    func songMetaDataWasUpdated(notification: NSNotification) {
        let songId = notification.object as! SongID
        if songId.isEqual(theSongPool?.lastRequestedSongId()) {
            print("song info update")
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        print("song cover update")
    }
}

extension NSView {
    
    func printAllSubviews() {
        Swift.print("This view is: \(self)")
        for sv in self.subviews {
            sv.printAllSubviews()
        }
    }
}