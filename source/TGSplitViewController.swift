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
    private var playlistPanelCtrlr: TGPlaylistViewController!
    private var coversPanelCtrlr: TGCoverDisplayViewController!
    private var infoPanelCtrlr: TGSongInfoViewController!
    private var sweetSpotController : SweetSpotController!
    private var objectController: NSObjectController?

    private var songMetadataUpdater : SongMetadataUpdater?
    
    var theURL: NSURL?
    
    var theSongPool : SongPoolAccessProtocol!
    
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

        /// Ensure we have an URL from the drop view.
        guard theURL != nil else { fatalError("No URL. Exiting.") }

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
        
        /// Not sure we really need a progress bar in the playlist but keep for now.
        // Bind the playlist controller's progress indicator value parameter with
        // the song pool's playheadPos via the timeline value transformer.
        playlistPanelCtrlr.playlistProgress?.bind(  "value",
                                                    toObject: self as AnyObject,
                                                    withKeyPath: "playheadPos",
                                                    options: [NSValueTransformerNameBindingOption : "TimelineTransformer"])
        
        // Bind the timeline nsslider (timelineBar) to observe the requestedPlayheadPosition 
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
        timeline.cell?.bind(    "currentPlayheadPositionInPercent",
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
        songMetadataUpdater = SongMetadataUpdater(delegate: theSongPool)
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

        let prevPriority = coverCollectionSVI.holdingPriority
        print("Before toggle, coverCollectionSVI holding priority: \(coverCollectionSVI.holdingPriority)")
        coverCollectionSVI.holdingPriority = 501

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
                songAudioCacher.dumpCacheToLog()

                guard let songId = currentlyPlayingSongId else { break }
                
                theSongPool.debugLogSongWithId(songId)

            default:
                break
            }
        }
    }
    
    func userSelectedSong(context : SongSelectionContext) {
        let songId = context.selectedSongId
        let speedVector = context.speedVector
        
        if fabs(speedVector.y) > 2 {
            print("Speed cutoff enabled")
            return
        }
        
        cacheWithContext(context)
        requestSongPlayback(songId)
    }
    
    func userSelectedSongInContext(notification: NSNotification) {
        let theContext = notification.object as! SongSelectionContext
        userSelectedSong(theContext)
    }
    
    func cacheWithContext(cacheContext : SongSelectionContext) {
        
        /// Cache songs using the context
        songAudioCacher.cacheWithContext(cacheContext)
        
        /// Update the last requestedSongId.
        lastRequestedSongId = cacheContext.selectedSongId
        
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
        guard let song = theSongPool.songForSongId(songId) else { return }
        
        let startTime = SweetSpotController.selectedSweetSpotForSong(song)
        //delegate!.requestSongPlayback(songId, withStartTimeInSeconds: startTime)
        requestSongPlayback(songId, withStartTimeInSeconds: startTime)
    }
    
    func requestSongPlayback(songId : SongId, withStartTimeInSeconds time : NSNumber?) {
        
        lastRequestedSongId = songId
        
        songAudioCacher.performWhenPlayerIsAvailableForSongId(songId) { player in
            
            guard (self.lastRequestedSongId != nil) && (self.lastRequestedSongId! == songId) else { return }
            
            self.setSongPlaybackObserver(player)
            let song = self.theSongPool.songForSongId(songId)
            let startTime = time ?? SweetSpotController.selectedSweetSpotForSong(song!) ?? NSNumber(double: 0)
            
            self.songAudioPlayer.playAtTime(startTime.doubleValue)
            self.currentlyPlayingSongId = songId
            
            let duration = song?.duration() ?? CMTimeGetSeconds(self.songAudioPlayer.songDuration)
//            guard let duration = song?.duration() else {
//                fatalError("Song has no duration!")
//            }
            /// Only update currentSongDuration if valid.
            if duration != 0 {
                self.currentSongDuration = duration
            }
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
        /// MARK : Make sure we're not creating a retain cycle.
        let timerObserver = { [weak self, weak songPlayer] (time : CMTime) -> () in
            /// FIXME : When songPlayer is nil it might be a sign that we're not properly 
            /// sync'ing ! Fix
            let currentPlaybackTime = songPlayer!.currentTime()
            self!.songDidUpdatePlayheadPosition(NSNumber(double: CMTimeGetSeconds(currentPlaybackTime)))
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
    
//    func setPlayhead(position : NSNumber) {
//        print("setPlayHead")
//        playheadPos = position
//    }


    func songDidUpdatePlayheadPosition(playheadPosition : NSNumber) {
        ///self.setValue(playheadPosition, forKey: "playheadPos")
        /// Will this work for KVO?
        /** Do on the main thread to avoid upsetting CoreAnimation.
            playheadPos property is bound to playlistProgress (which is an NSView).
        
        */
        dispatch_sync(dispatch_get_main_queue()){
            self.playheadPos = playheadPosition
        }
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
            let song = theSongPool.songForSongId(songId) {
                infoPanel.setDisplayStrings(withDisplayStrings: song.metadataDict())
                
                /// update the currentSongDuration
                currentSongDuration = song.duration()
        }
    }
    
    func songCoverWasUpdated(notification: NSNotification) {
        
        let songId = notification.object as! SongId
        

        if songId == lastRequestedSongId,
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
        if let playingSongId = currentlyPlayingSongId,
            let sweetSpots = getSweetSpots(playingSongId) {
                
            let sweetSpotTime = sweetSpots[(sweetSpots.startIndex.advancedBy(index))]
            requestedPlayheadPosition = sweetSpotTime
            theSongPool.addSong(withChanges: [.SelectedSS : sweetSpotTime], forSongId: playingSongId)
        }
    }
    
    public func userPressedPlus() {
        /// Figure out which song is currently selected
        if let selectedSongId = currentlyPlayingSongId {
            playlistPanelCtrlr.addToPlaylist(songWithId: selectedSongId)
        }
    }
}

extension TGSplitViewController : SongAudioCacherDelegate {
    func getSongURL(songId : SongId) -> NSURL? {
        return theSongPool.getUrl(songId)
    }
    
    func getSongId(gridPos : NSPoint) -> SongId? {
        return coversPanelCtrlr.songIdFromGridPos(gridPos)
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
        guard let coords = coversPanelCtrlr.getCoverCoordinates(songId) else { return }
        print("playlist selected song at \(coords)")
        
        let bogusSpeedVector = NSMakePoint(1, 1)
        
        // Get the dimensions in rows and columns of the current cover collection layout.
        let dims = coversPanelCtrlr.getGridDimensions()
        let context = TGSongSelectionContext(selectedSongId: songId, speedVector: bogusSpeedVector, selectionPos: coords, gridDimensions: dims, cachingMethod: .Square)
        
        //userSelectedSong(context)
        /// Ensure song is cached.
        cacheWithContext(context)
        
        /// Play back song from beginning, not from sweet spot.
        requestPlayback(songId, startTimeInSeconds: 0)
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