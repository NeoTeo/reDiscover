//
//  TGTimelineSliderCell.swift
//  reDiscover
//
//  Created by teo on 25/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa

//typealias SweetSpot = NSNumber //Float

class TGTimelineSliderCell : NSSliderCell {
    
    enum TimelineBarSize {
        case small
        case normal
        case big
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

    required init(coder aDecoder: NSCoder) {
        playheadPositionInPercent   = 0
        currentSongDuration         = 0
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
    
        print("TGTimelineSliderCell awakeFromNib")
        
        guard let controlView = controlView else {
            print("ERROR: TGTimelineSliderCell awakeFromNib found no controlView!")
            return
        }
        
        var frameHeight = Int(controlView.frame.height)
        let frameSize   = controlView.frame.size
        
        /// Ensure the frame height is even.
        if frameHeight % 2 != 0 { frameHeight += 1 }
        let halfFrameHeight = frameHeight / 2
        
        /// Setting the rect of the bar here since I can't seem to get it from the superclass
        barRect = NSRect(   x: 0,
                            y: CGFloat(halfFrameHeight - TimelineBarHeight / 2),
                        width: frameSize.width,
                       height: CGFloat(TimelineBarHeight))
        
        /// Allow control view to draw subviews' layers into its own.
        controlView.canDrawSubviewsIntoLayer = true
        
        sweetSpotsView      = NSView(frame: NSRect(x: 0,
                                                   y: 2,
                                               width: frameSize.width,
                                              height: frameSize.height))
        
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
    func mouseEntered(_ theEvent : NSEvent) {
        resizeTimeline(.big)
    }
    
    /** Return the timeline bar and all the sweet spot controls  to their normal 
        sizes when the then mouse pointer leaves the slider cell area.
    */
    func mouseExited(_ theEvent : NSEvent) {
        resizeTimeline(.normal)
    }

    func resizeTimeline(_ size : TimelineBarSize) {
        
        var halfSweetSpot = CGFloat(SweetSpotMarkerHeight / 2)
        var barFrame      = barRect
        
        switch size   {
        case .big:
            halfSweetSpot = -halfSweetSpot
            barFrame      = NSRectFromCGRect(barRect!.insetBy(dx: 0, dy: -4))
        default:
            break
        }
        
        /** Setting the view's animator frame uses AppKit animation (on main thread)
        rather than Core Animation on a bg thread.
        */
        for spot in sweetSpotsView.subviews {
            spot.animator().frame  = NSRectFromCGRect(spot.frame.insetBy(dx: halfSweetSpot, dy: halfSweetSpot))
        }
        
        timelineBarView.animator().frame = barFrame!
    }
    
    /// FIXME: Change to makeMarkers(sweetSpots : Set<SweetSpot>, duration : NSNumber)
    func makeMarkers(_ sweetSpots: Set<SweetSpot>, duration: NSNumber) {

        guard duration.doubleValue != 0 else {
            print("Dropping out of makeMarkersFromSweetSpots because song duration is 0.")
            return
        }

        /// Adding and removing subviews needs to happen on the main thread.
        DispatchQueue.main.async {
            var spotIndex = 0

            /// Clear out the existing sweet spot markers from the sweetSpotsView
            self.sweetSpotsView.subviews.forEach { $0.removeFromSuperview() }
            
            /// Add the new sweet spot markers
            for ss in sweetSpots {
                
                guard ss != 0 else {
                    print("Sweet spot is 0. Skipping.")
                    continue
                }
                
                let ssXPos = self.barRect!.width / CGFloat(duration.doubleValue) * CGFloat(ss.doubleValue)
                
                if ssXPos.isNaN || ssXPos.isInfinite {
                    print("ERROR: Something is wrong with sweet spot duration.")
                    fatalError()
                }
                
                /** Each sweet spot is a control that calls userSelectedExistingSweetSpot
                    when clicked. */
                //print("Setting sweet spot marker at position \(ssXPos)")
                let val = CGFloat(self.SweetSpotMarkerHeight)
                let aSSControl = TGSweetSpotControl(frame: NSRect(x: ssXPos,
                                                                  y: val,
                                                              width: val,
                                                             height: val))

                aSSControl.tag    = spotIndex//sweetSpots.indexOf(<#T##member: SweetSpot##SweetSpot#>)
                aSSControl.target = self.theController
                // FIXME: figure out what's to be called.
                aSSControl.action = Selector("userSelectedExistingSweetSpot:")
                aSSControl.image  = self.knobImage
                
                self.sweetSpotsView.addSubview(aSSControl)
                
                spotIndex         = spotIndex + 1
            }
        }
    }
    
    /** When the slider is released we notify that the user wants to create a sweet spot */
    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        print("Done tracking!")
        NotificationCenter.default().post(name: Notification.Name(rawValue: "UserCreatedSweetSpot"), object: nil)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        drawKnob()
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        knobImageView.frame = knobRect
    }
    
}

