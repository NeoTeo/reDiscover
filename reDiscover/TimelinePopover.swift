//
//  TimelinePopover.swift
//  reDiscover
//
//  Created by Teo on 08/06/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol TimelinePopoverDelegateProtocol {
    //unc userCreatedNewSweetSpot
}

class SongTimelinePopover : NSViewController, TimelinePopoverDelegateProtocol {
    
    var delegate: TimelinePopoverDelegateProtocol?
    
    @IBOutlet var thePopover: NSPopover?
    @IBOutlet var timelineBar: NSSlider?
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension SongTimelinePopover {
    
    override func awakeFromNib() {
        
        let trackingRect = self.view.frame
        let trackingArea = NSTrackingArea(rect: trackingRect,options: [.MouseEnteredAndExited, .ActiveInKeyWindow], owner: timelineBar?.cell, userInfo: nil)
        
        self.view.addTrackingArea(trackingArea)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTimelineSweetSpots:", name: "SweetspotsUpdated", object: nil)
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
        let songSweetSpots = SongPool.sweetSpotsForSongId(songId)
        
        theCell.makeMarkersFromSweetSpots(songSweetSpots as [AnyObject], forSongDuration: songDuration)
    }
    
    func togglePopoverRelativeToBounds(theBounds: CGRect, ofView theView: NSView) {
        guard let pop = thePopover else { return }
        
        if pop.shown {
            pop.close()
        } else {
            
            pop.showRelativeToRect(theBounds, ofView: theView, preferredEdge: .MaxY)
        }
    }
}