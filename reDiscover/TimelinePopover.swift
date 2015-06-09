//
//  TimelinePopover.swift
//  reDiscover
//
//  Created by Teo on 08/06/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol TimelinePopover {
    
}

class songTimelinePopover : NSViewController, TimelinePopover {
    
    @IBOutlet var thePopover: NSPopover?
    @IBOutlet var timelineBar: NSSlider?
    
    override func awakeFromNib() {
        let trackingRect = self.view.frame
        let trackingArea = NSTrackingArea(rect: trackingRect,options: [.MouseEnteredAndExited, .ActiveInKeyWindow], owner: timelineBar?.cell, userInfo: nil)
        
        self.view.addTrackingArea(trackingArea)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTimelineSweetspots:", name: "SweetspotsUpdated", object: nil)
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension songTimelinePopover {
    func updateTimelineSweetspots(notification: NSNotification) {
        if let songId = notification.object as? SongIDProtocol,
        let theCell = timelineBar?.cell as? TGTimelineSliderCell,
        let theSong = SongPool.songForSongId(songId) {
 //           let songDuration = theSong.
        }
        
        
    }
}