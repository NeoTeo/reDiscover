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


final public class TGSplitViewController: NSSplitViewController, SongPlaybackProtocol {
 
    @IBOutlet weak var playlistSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var coverCollectionSVI: NSSplitViewItem!
    @IBOutlet weak var songInfoSVI: NSSplitViewItem!
    
    // Shadow the above SplitViewItems' viewControllers because...?
    private var playlistPanelCtrlr: TGPlaylistViewController!
    private var coversPanelCtrlr: TGCoverDisplayViewController!
    private var infoPanelCtrlr: TGSongInfoViewController!
    private var sweetSpotController : SweetSpotController!
    private var objectController: NSObjectController?

    private var songMetadataUpdater : SongMetadataUpdater?
    
    var theURL: NSURL?
    // Would rather use the Static version
//    var theSongPool: TGSongPool?
    var theSongPool : SongPoolAccessProtocol?
    
    private var songAudioCacher = TGSongAudioCacher()
    private var songAudioPlayer = TGSongAudioPlayer()

    /// Moved from SongPool
    /** Should these be moved to a song player controller/DJ class that tracks
    what song is currently playing, what is requested, etc. ?
    */
    private var lastRequestedSongId : SongId?
    private var currentlyPlayingSongId : SongId?
    private dynamic var currentSongDuration : NSNumber?
    /** Playhead stuff. Consider moving to separate class/struct */
    private dynamic var playheadPos : NSNumber?
    private dynamic var requestedPlayheadPos : NSNumber?
    dynamic var requestedPlayheadPosition : NSNumber? {
        /**
        This method sets the requestedPlayheadPosition (which represents the position the user has manually set with a slider)
        of the currently playing song to newPosition and sets a sweet spot for the song which gets stored on next save.
        The requestedPlayheadPosition should only result in a sweet spot when the user releases the slider.
        */
        set(newPosition) {
            guard newPosition != nil else { return }
            self.requestedPlayheadPos = newPosition
            songAudioPlayer.currentPlayTime = newPosition!.doubleValue
        }
        
        get {
            return self.requestedPlayheadPos
        }
        
    }
}

extension TGSplitViewController {
    
    /** This view appears as a consequence of a segue from the drop view controller.
        Since the initial window is closed and a new one is created to hold this 
        view we must set it up from here.
    */
    public override func viewDidAppear() {
        theSongPool = SongPool()
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

        guard theURL != nil else { fatalError() }

//        theSongPool = SongPool()
        theSongPool!.load(theURL!)
        /// The song pool controller shouldn't be managing cover panel stuff. 
        /// Move this to this class!
//        theSongPool.coverDisplayAccessAPI = coversPanelCtrlr
        //FIXME: I'd rather this was done by making CoverViewController provide the functionality as class methods.
//        theSongPool!.delegate = self
        songAudioPlayer.setVolume(0.2)
        
        registerNotifications()
        
        setupBindings()
    }
    
    
    /**
        Set up KVO bindings between elements that need to know when songs are playing
        and how far along they are.
    */
    func setupBindings() {
        
        if objectController == nil {
            objectController = NSObjectController(content: self as AnyObject?)
        }
        // Bind the timeline value transformer's maxDuration with the song pool's currentSongDuration.
        let transformer = TGTimelineTransformer()
        NSValueTransformer.setValueTransformer(transformer, forName: "TimelineTransformer")
        transformer.bind("maxDuration", toObject: self as AnyObject, withKeyPath: "currentSongDuration", options: nil)
        
        // Bind the playlist controller's progress indicator value parameter with
        // the song pool's playheadPos via the timeline value transformer.
        playlistPanelCtrlr.playlistProgress?.bind("value",
            toObject: self as AnyObject,
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
        
        sweetSpotController = SweetSpotController()
        sweetSpotController.delegate = self
//        playlistPanelCtrlr.songPoolAPI = theSongPool
        /// Rhe coversPanelCtrlr provides the song audio cacher with a way to map 
        /// a position to a song id.

        
        /// FIXME : For now we handle this but there should be a separate playback controller class
//        playlistPanelCtrlr.songPlaybackController = self
        
        /// FIXME : Make SweetSpotServerIO use delegate
        SweetSpotServerIO.songPoolAPI = theSongPool

        coversPanelCtrlr.delegate = self
        songAudioCacher.delegate = self
        playlistPanelCtrlr.delegate = self
        
        /// The song pool handles the song metadata updater's requirements
        songMetadataUpdater = SongMetadataUpdater(delegate: theSongPool!)
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
        coverCollectionSVI.holdingPriority = 501

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
        
        //theSongPool?.cacheWithContext(theContext)
        //theSongPool?.requestSongPlayback(songId)
        cacheWithContext(theContext)
        requestSongPlayback(songId)
    }
    
    func cacheWithContext(cacheContext : SongSelectionContext) {
        
        /// Cache songs using the context
        songAudioCacher.cacheWithContext(cacheContext)
        
        /// Update the last requestedSongId.
        lastRequestedSongId = cacheContext.selectedSongId
        
        /// FIXME : Move requestUpdatedData and all the funcs it calls out of SongPool 
        /// and into  some other class.
        //// Request updated data for the selected song.
        songMetadataUpdater?.requestUpdatedData(forSongId: lastRequestedSongId!)
    }
    
    func requestPlayback(songId: SongId, startTimeInSeconds: NSNumber) {
        /** FIXME : Just do this directly once we're sure everyone is calling
            requestPlayback instead of requestSongPlayback
        */
        requestSongPlayback(songId, withStartTimeInSeconds: startTimeInSeconds)
    }
    
    /**     Initiate a request to play back the given song.
     
     If the song has a selected sweet spot play the song from there otherwise
     just play the song from the start.
     :params: songID The id of the song to play.
     */
    func requestSongPlayback(songId: SongId) {
        guard let song = theSongPool?.songForSongId(songId) else { return }
        
        let startTime = SweetSpotController.selectedSweetSpotForSong(song)
        //delegate!.requestSongPlayback(songId, withStartTimeInSeconds: startTime)
        requestSongPlayback(songId, withStartTimeInSeconds: startTime)
    }
    
    func requestSongPlayback(songId : SongId, withStartTimeInSeconds time : NSNumber?) {
        
        lastRequestedSongId = songId
        
        songAudioCacher.performWhenPlayerIsAvailableForSongId(songId) { player in
            
            guard (self.lastRequestedSongId != nil) && (self.lastRequestedSongId! == songId) else { return }
            
            self.setSongPlaybackObserver(player)
            let song = self.theSongPool?.songForSongId(songId)
            let startTime = time ?? SweetSpotController.selectedSweetSpotForSong(song!) ?? NSNumber(double: 0)
            
            self.songAudioPlayer.playAtTime(startTime.doubleValue)
            self.currentlyPlayingSongId = songId
            
            let duration = song?.duration() ?? CMTimeGetSeconds(self.songAudioPlayer.songDuration)
//            guard let duration = song?.duration() else {
//                fatalError("Song has no duration!")
//            }
            /** The following crashes at runtime because this is using a reference to
            an instance of this class (self) to set the value of a static
            //self.setValue(duration, forKey: "currentSongDuration")
            
            Presumably the following won't have the desired effects since we want to set the
            currentSongDuration in a KVO compliant fashion. Not sure what that is
            in Swift. It seems you have to add the dynamic keyword to the properties
            you want to observe.
            This and playheadPos are being bound in TGSplitViewController setupBindings()
            I need to change that to refer to these instead of the ObjC properties
            in the songPool.m
            */
            self.currentSongDuration = duration
            self.requestedPlayheadPosition = startTime
        }
    }
    /**
     - (void)requestSongPlayback:(id<SongId>)songID withStartTimeInSeconds:(NSNumber *)time {
     
     id<TGSong> aSong = [self songForID:songID];
     if (aSong == NULL) {
     TGLog(TGLOG_ALL,@"Nope, the requested ID %@ is not in the song pool.",songID);
     return;
     }
     
     lastRequestedSongId = songID;
     
     //NUCACHE
     [songAudioCacher performWhenPlayerIsAvailableForSongId:songID callBack:^(AVPlayer* thePlayer){
     
     if (songID == lastRequestedSongId) {
     
     // Start observing the new player.
     [self setSongPlaybackObserver:thePlayer];
     
     id<TGSong> song = [self songForID:songID];
     
     /** If there's no start time, check the sweet spot server for one.
     If one is found set the startTime to it, else set it to the beginning. */
     NSNumber* startTime = time;
     
     if (startTime == nil) {
     
     // At this point we really ought to make sure we have a song uuid generated from the fingerprint.
     startTime = [SweetSpotController selectedSweetSpotForSong:song];
     if (startTime == nil) {
     startTime = [NSNumber numberWithDouble:0.0];
     }
     }
     
     [songAudioPlayer playAtTime:[startTime floatValue]];
     currentlyPlayingSongId = songID;
     
     TGLog(TGLOG_TMP, @"currentSongDuration %f",CMTimeGetSeconds([songAudioPlayer songDuration]));
     
     [self setValue:[NSNumber numberWithFloat:CMTimeGetSeconds([songAudioPlayer songDuration])] forKey:@"currentSongDuration"];
     
     [self setRequestedPlayheadPosition:startTime];
     }
     }];
     }
     */
    
    func setSongPlaybackObserver(songPlayer : AVPlayer) {
        
        let timerObserver = { (time : CMTime) -> () in
            let currentPlaybackTime = songPlayer.currentTime()
            self.songDidUpdatePlayheadPosition(NSNumber(double: CMTimeGetSeconds(currentPlaybackTime)))
        }
        songAudioPlayer.setSongPlayer(songPlayer, block: timerObserver)
        
        /**
        // Make a weakly retained self and songPlayer for use inside the block to avoid retain cycle.
        __unsafe_unretained typeof(self) weakSelf = self;
        __unsafe_unretained AVPlayer* weakSongPlayer = songPlayer;
        
        void (^timerObserverBlock)(CMTime) = ^void(CMTime time) {
        
        CMTime currentPlaybackTime = [weakSongPlayer currentTime];
        [weakSelf songDidUpdatePlayheadPosition:[NSNumber numberWithDouble:CMTimeGetSeconds(currentPlaybackTime)]];
        };
        [songAudioPlayer setSongPlayer:songPlayer block:timerObserverBlock];
        
        */
    }
    
    func setPlayhead(position : NSNumber) {
        playheadPos = position
        print("Playhead pos: \(playheadPos)")
    }

    func songDidUpdatePlayheadPosition(playheadPosition : NSNumber) {
        ///self.setValue(playheadPosition, forKey: "playheadPos")
        /// Will this work for KVO?
        playheadPos = playheadPosition
    }

    /** This is called when the TGTimelineSliderCell detects that the user has let
        go of the sweet spot slider and thus wants to create a new sweet spot at the
        corresponding time. The song is always the TGSongPool's currentlyPlayingSongId and the
        time is the TGSongPool's requestedPlayheadPosition.
    */
    func userCreatedSweetSpot(notification: NSNotification) {
        if let ssTime = requestedPlayheadPosition,
            let songId = currentlyPlayingSongId {
        
            sweetSpotController.addSweetSpot(atTime: ssTime, forSongId: songId)
        }
    }
    
    // Notification when a song starts loading/caching. Allows us to update UI to show activity.
    func songDidStartUpdating(notification: NSNotification) {
//        let songId = notification.object as! SongId
        if let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let coverImage = SongArt.getFetchingCoverImage() {
            infoPanel.setCoverImage(coverImage)
        }

    }
    // Called when the song metadata is updated and will in turn call the info panel
    // to update its data.
    func songMetaDataWasUpdated(notification: NSNotification) {
        let songId = notification.object as! SongId
        if songId == lastRequestedSongId,
            let infoPanel = songInfoSVI.viewController as? TGSongInfoViewController,
            let song = theSongPool?.songForSongId(songId) {
                infoPanel.setDisplayStrings(withDisplayStrings: song.metadataDict())
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        
        let songId = notification.object as! SongId
        

        if songId == lastRequestedSongId,
            let song = theSongPool?.songForSongId(songId){
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
//extension TGSplitViewController {
//    
//    public func songIdFromGridPos(pos: NSPoint) -> AnyObject! {
//        let coverCtrlr = coverCollectionSVI.viewController as! TGCoverDisplayViewController
//        return coverCtrlr.songIdFromGridPos(pos)
//    }
//}

extension TGSplitViewController : CoverDisplayViewControllerDelegate {
 
    /// For TGCoverDisplayViewController
    public func getSong(songId : SongId) -> TGSong? {
        return theSongPool?.songForSongId(songId)
    }
    
    public func getArt(artId : String) -> NSImage? {
        /// Static access for now
        return SongArt.getArt(forArtId: artId)
    }
 
    /// For TimelinePopoverViewControllerDelegate
    public func getSongDuration(songId : SongId) -> NSNumber? {
        return theSongPool?.songForSongId(songId)?.duration()
    }
    
    public func getSweetSpots(songId : SongId) -> Set<SweetSpot>? {
        return theSongPool?.songForSongId(songId)?.sweetSpots
    }
    
    public func userSelectedSweetSpot(index : Int) {
        if let playingSongId = currentlyPlayingSongId,
            let sweetSpots = getSweetSpots(playingSongId) {
                
            let sweetSpotTime = sweetSpots[(sweetSpots.startIndex.advancedBy(index))]
            requestedPlayheadPosition = sweetSpotTime
            theSongPool?.addSong(withChanges: [.SelectedSS : sweetSpotTime], forSongId: playingSongId)
        }
    }
}

extension TGSplitViewController : SongAudioCacherDelegate {
    func getSongURL(songId : SongId) -> NSURL? {
        return theSongPool?.getUrl(songId)
    }
    
    func getSongId(gridPos : NSPoint) -> SongId? {
        return coversPanelCtrlr.songIdFromGridPos(gridPos)
    }
}

extension TGSplitViewController : SweetSpotControllerDelegate {
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId) {
        theSongPool?.addSong(withChanges: changes, forSongId: songId)
    }    
}

extension TGSplitViewController : PlaylistViewControllerDelegate {
    /// All required methods already declared in the main class.
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