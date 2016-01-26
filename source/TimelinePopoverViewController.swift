//
//  TimelinePopoverViewController.swift
//  reDiscover
//
//  Created by Teo on 08/06/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol TimelinePopoverDelegateProtocol {
    //func userCreatedNewSweetSpot
}

public class TimelinePopoverViewController : NSViewController {//, TimelinePopoverDelegateProtocol {
    
    var delegate: TimelinePopoverDelegateProtocol?
    
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
        
        if let songId = notification.object as? SongID {
            setCurrentSongId(songId)
        }
    }
    
    func setCurrentSongId(songId: SongID) {
        let theCell = timelineBar?.cell as! TGTimelineSliderCell
        theCell.theController = self
        let songDuration = SongPool.durationForSongId(songId)
        
        if let songSweetSpots = SweetSpotController.sweetSpots(forSongId: songId) {
            theCell.makeMarkersFromSweetSpots(songSweetSpots, forSongDuration: songDuration)
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
    }

}