//
//  TimelinePopoverViewController.swift
//  reDiscover
//
//  Created by Teo on 08/06/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

protocol TimelinePopoverViewControllerDelegate {
    func getSongDuration(_ songId : SongId) -> NSNumber?
    func getSweetSpots(_ songId: SongId) -> Set<SweetSpot>?
    func userSelectedExistingSweetSpot(_ index : Int)
}


public class TimelinePopoverViewController : NSViewController {
    
    var delegate : TimelinePopoverViewControllerDelegate?
    
    @IBOutlet var thePopover: NSPopover!
    @IBOutlet var timelineBar: NSSlider?
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension TimelinePopoverViewController {
    
    public override func awakeFromNib() {
        
        let trackingRect = self.view.frame
        let trackingArea = NSTrackingArea(rect: trackingRect,options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: timelineBar?.cell, userInfo: nil)
        
        self.view.addTrackingArea(trackingArea)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimelinePopoverViewController.updateTimelineSweetSpots(_:)), name: NSNotification.Name("SweetSpotsUpdated"), object: nil)
    }
    
    func updateTimelineSweetSpots(_ notification: Notification) {
        
        if let songId = notification.object as? SongId {
            setCurrentSongId(songId)
        }
    }
    
    func setCurrentSongId(_ songId: SongId) {
        
        let theCell = timelineBar?.cell as! TGTimelineSliderCell
        theCell.theController = delegate
        
//        let songDuration = SongPool.durationForSongId(songId)
        /// We get the duration straight from the song.
        let songDuration = delegate?.getSongDuration(songId) ?? NSNumber(value: 0)
        print("Song with id \(songId) has duration \(songDuration)")
        if let songSweetSpots = delegate?.getSweetSpots(songId) {
            theCell.makeMarkers(songSweetSpots, duration: songDuration)
        }
    }
    
    func hideTimeline() {
        thePopover?.close()
    }
    
    func togglePopoverRelativeToBounds(_ theBounds: CGRect, ofView theView: NSView) {
        guard let pop = thePopover else { return }
        
        if pop.isShown {
            pop.close()
        } else {
            
            pop.show(relativeTo: theBounds, of: theView, preferredEdge: .maxY)
        }
    }
    
    public func userSelectedExistingSweetSpot(_ sender: AnyObject!) {
        print("user selected existing sweet spot")
        delegate?.userSelectedExistingSweetSpot(sender.tag)
    }

}
