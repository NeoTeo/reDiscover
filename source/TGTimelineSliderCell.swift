//
//  TGTimelineSliderCell.swift
//  reDiscover
//
//  Created by teo on 25/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

//typealias SweetSpot = NSNumber //Float

class TGTimelineSliderCell : NSSliderCell {
    
    enum TimelineBarSize {
        case Small
        case Normal
        case Big
    }

    let SweetSpotMarkerHeight   = 8
    let TimelineBarHeight       = 8

    private var playheadPositionInPercent: NSNumber
    var currentPlayheadPositionInPercent : NSNumber {
        set {
            playheadPositionInPercent = newValue
            timelineBarView.setPlayheadPositionInPercent(newValue.doubleValue)
            controlView?.needsDisplay = true
        }
        get {
            return playheadPositionInPercent
        }
    }
    
    var currentSongDuration : NSNumber
    var barRect : NSRect?
    
    /// The bar in the timeline popup that shows the playback progressing.
    var timelineBarView : TGTimelineBarView!
    var sweetSpotsView : NSView!
    var knobImage : NSImage!
    var knobImageView : NSImageView!

    /// The sweet spots to show on this slider cell.
    var sweetSpotPositions : [SweetSpot]?
    
    /// This class' controller.
    var theController : AnyObject!

    required init?(coder aDecoder: NSCoder) {
        playheadPositionInPercent    = 0
        currentSongDuration                 = 0
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
    
        print("TGTimelineSliderCell awakeFromNib")
        
        guard let controlView = controlView else {
            print("ERROR: TGTimelineSliderCell awakeFromNib found no controlView!")
            return
        }
        
        var frameHeight = Int(CGRectGetHeight(controlView.frame))
        let frameSize   = controlView.frame.size
        
        /// Ensure the frame height is even.
        if frameHeight % 2 != 0 { frameHeight += 1 }
        let halfFrameHeight = frameHeight / 2
        
        /// Setting the rect of the bar here since I can't seem to get it from the superclass
        barRect = NSMakeRect(   0,
                                CGFloat(halfFrameHeight - TimelineBarHeight / 2),
                                frameSize.width,
                                CGFloat(TimelineBarHeight))
        
        /// Allow control view to draw subviews' layers into its own.
        controlView.canDrawSubviewsIntoLayer = true
        
        sweetSpotsView      = NSView(frame: NSMakeRect(0, 2, frameSize.width, frameSize.height))
        timelineBarView     = TGTimelineBarView(frame: barRect!)
        
        knobImage           = NSImage(named: "ssButton")!
        knobImageView       = NSImageView()
        knobImageView.image = knobImage
        
        controlView.addSubview(timelineBarView)
        controlView.addSubview(sweetSpotsView)
        controlView.addSubview(knobImageView)
    }
    
    /** Grow the timeline bar and all the sweet spot controls when the mouse pointer
        enters the slider cell area.
    */
    func mouseEntered(theEvent : NSEvent) {
        resizeTimeline(.Big)
    }
    
    /** Return the timeline bar and all the sweet spot controls  to their normal 
        sizes when the then mouse pointer leaves the slider cell area.
    */
    func mouseExited(theEvent : NSEvent) {
        resizeTimeline(.Normal)
    }

    func resizeTimeline(size : TimelineBarSize) {
        
        var halfSweetSpot = CGFloat(SweetSpotMarkerHeight / 2)
        var barFrame      = barRect
        
        switch size   {
        case .Big:
            halfSweetSpot = -halfSweetSpot
            barFrame      = NSRectFromCGRect(CGRectInset(barRect!, 0, -4))
        default:
            break
        }
        
        /** Setting the view's animator frame uses AppKit animation (on main thread)
        rather than Core Animation on a bg thread.
        */
        for spot in sweetSpotsView.subviews {
            spot.animator().frame  = NSRectFromCGRect(CGRectInset(spot.frame, halfSweetSpot, halfSweetSpot))
        }
        
        timelineBarView.animator().frame = barFrame!
    }
    
    func makeMarkersFromSweetSpots(sweetSpots: Set<SweetSpot>, forSongDuration duration: NSNumber) {
        
        /// Adding and removing subviews needs to happen on the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            var spotIndex = 0
            /// Clear out the existing sweet spot markers from the sweetSpotsView
            self.sweetSpotsView.subviews.forEach { $0.removeFromSuperview() }
        }
    }
    
    /** When the slider is released we notify that the user wants to create a sweet spot */
    override func stopTracking(lastPoint: NSPoint, at stopPoint: NSPoint, inView controlView: NSView, mouseIsUp flag: Bool) {
        print("Done tracking!")
        NSNotificationCenter.defaultCenter().postNotificationName("UserCreatedSweetSpot", object: nil)
    }
    
    override func drawWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        drawKnob()
    }
    
    override func drawKnob(knobRect: NSRect) {
        knobImageView.frame = knobRect
    }
    
}

