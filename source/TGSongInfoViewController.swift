//
//  TGSongInfoViewController.swift
//  reDiscover
//
//  Created by teo on 16/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

class TGSongInfoViewController : NSViewController {
    
    @IBOutlet weak var titleLabel : NSTextField!
    @IBOutlet weak var artistLabel : NSTextField!
    @IBOutlet weak var albumLabel : NSTextField!
    @IBOutlet weak var albumCover : NSImageView!
    @IBOutlet weak var scrollTitleView : ScrollingTextView!
    
    var noCoverImage : NSImage!
    
    override func awakeFromNib() {
        
        noCoverImage        = NSImage(named: "noCover")!
        
        albumCover.image    = noCoverImage
    }
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }
    
    /** Update the labels displaying the song information */
    func setDisplayStrings(withDisplayStrings displayStrings : NSDictionary) {
        
        print("setDisplayStrings called")
        /// update the info labels on the main queue as CoreAnimation requires
        dispatch_async(dispatch_get_main_queue()) {
            print("setDisplayStrings actually being updated.")
            self.titleLabel.stringValue     = displayStrings.objectForKey("Title") as! String
            self.artistLabel.stringValue    = displayStrings.objectForKey("Artist") as! String
            self.albumLabel.stringValue     = displayStrings.objectForKey("Album") as! String
            
            /// Set up the scrolling text.
            self.scrollTitleView.setText(self.titleLabel.stringValue)
            self.scrollTitleView.setSpeed(0.01)
        }
    }
    
    /** Update the cover image on the info panel */
    func setCoverImage(coverImage : NSImage?) {
        
        let image = coverImage == nil ? noCoverImage : coverImage!

        /**
        setSongCoverImage might get called by a separate thread and since
        Core Anim doesn't like working on non-main treads, we need to ensure that
        setImage is called on the main thread.
        */
        dispatch_async(dispatch_get_main_queue()) {
            self.crossFadeToImage(image)
        }
    }

    func crossFadeToImage(newImage : NSImage) {
        
        /// Early out if albumCover has no layer
        if albumCover.layer == nil { return }
        
        NSAnimationContext.currentContext().allowsImplicitAnimation = true
        let newCoverImageView = NSImageView(frame: albumCover.frame)
        newCoverImageView.wantsLayer = true
        newCoverImageView.image = newImage
        newCoverImageView.alphaValue = 0
        
        self.view.addSubview(newCoverImageView)
        
        newCoverImageView.layer?.opacity = 1
        albumCover.layer?.opacity = 0
        
        albumCover.removeFromSuperview()
        albumCover = newCoverImageView
    }
}