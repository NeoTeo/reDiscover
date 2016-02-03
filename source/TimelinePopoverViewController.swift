//
//  TimelinePopoverViewController.swift
//  reDiscover
//
//  Created by Teo on 08/06/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

protocol TimelinePopoverViewControllerDelegate {
    func getSongDuration(songId : SongId) -> NSNumber?
    func getSweetSpots(songId: SongId) -> Set<SweetSpot>?
    func userSelectedSweetSpot(index : Int)
}

public class TimelinePopoverViewController : NSViewController {
    

    var delegate : TimelinePopoverViewControllerDelegate?
    
    @IBOutlet var thePopover: NSPopover!
    @IBOutlet var timelineBar: NSSlider?
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension TimelinePopoverViewController {
    
    public override func awakeFromNib() {
        
        let trackingRect = self.view.frame
        let trackingArea = NSTrackingArea(rect: trackingRect,options: [.MouseEnteredAndExited, .ActiveInKeyWindow], owner: timelineBar?.cell, userInfo: nil)
        
        self.view.addTrackingArea(trackingArea)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTimelineSweetSpots:", name: "SweetSpotsUpdated", object: nil)
    }
    
    func updateTimelineSweetSpots(notification: NSNotification) {
        
        if let songId = notification.object as? SongId {
            setCurrentSongId(songId)
        }
    }
    
    func setCurrentSongId(songId: SongId) {
        
        let theCell = timelineBar?.cell as! TGTimelineSliderCell
        theCell.theController = self
        
//        let songDuration = SongPool.durationForSongId(songId)
        /// We get the duration straight from the song.
        let songDuration = delegate?.getSongDuration(songId) ?? NSNumber(double: 0)
        print("Song with id \(songId) has duration \(songDuration)")
        if let songSweetSpots = delegate?.getSweetSpots(songId) {
            theCell.makeMarkers(songSweetSpots, duration: songDuration)
        }
    }
    
    func togglePopoverRelativeToBounds(theBounds: CGRect, ofView theView: NSView) {
        guard let pop = thePopover else { return }
        
        if pop.shown {
            pop.close()
        } else {
            
            pop.showRelativeToRect(theBounds, ofView: theView, preferredEdge: .MaxY)
        }
    }
    
    public func userSelectedExistingSweetSpot(sender: AnyObject!) {
        print("user selected existing sweet spot")
        delegate?.userSelectedSweetSpot(sender.tag())
//        let playingSongId = delegate?.currentlyPlayingSongId()
//        let songSweetspots = delegate?.getSweetSpots(playingSongId!)
//        //mySet[mySet.startIndex.advancedBy(2)]
//        let selectedSweetSpotIndex = sender.tag()
//        if let sweetSpotTime = songSweetspots?[(songSweetspots?.startIndex.advancedBy(selectedSweetSpotIndex))!] {
//            setRequestedPlayheadPosition(sweetSpotTime)
//
//            SongPool.addSong(withChanges: [.SelectedSS : sweetSpotTime], forSongId: playingSongId)
//        }
    }

}