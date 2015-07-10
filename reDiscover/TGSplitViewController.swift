//
//  TGSplitViewController.swift
//  reDiscover
//
//  Created by Teo on 09/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

final public class TGSplitViewController: NSSplitViewController {
 
    @IBOutlet weak var playlistSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var coverCollectionSVI: NSSplitViewItem!
    @IBOutlet weak var songInfoSVI: NSSplitViewItem!
    
    var theURL: NSURL?
    // Would rather use the Static version
    var theSongPool: TGSongPool?
}


extension TGSplitViewController {
    
    public override func viewDidAppear() {
        print("TGSplitView did appear. Let's have a look at the views.")
        view.printAllSubviews()
        
        print("playlist \(playlistSplitViewItem.viewController)")
        print("coverCollection \(coverCollectionSVI.viewController)")
        print("songInfo \(songInfoSVI.viewController)")
        
        // make this the first responder.
        self.view.window?.makeFirstResponder(self)
        
        theSongPool = TGSongPool()
        theSongPool!.loadFromURL(theURL)
    }
    
    func setupNotifications() {
        
    }
    
    public override func keyDown(theEvent: NSEvent) {

        let string = theEvent.characters!
        // Could also use interpretKeyEvents
        for character in string.characters {
            switch character {
            case "[":
                print("Left panel")
                playlistSplitViewItem.animator().collapsed = !playlistSplitViewItem.collapsed
            case "]":
                print("Right panel")
                songInfoSVI.animator().collapsed = !songInfoSVI.collapsed
            default:
                break
            }
        }
    }
    
}

extension NSView {
    
    func printAllSubviews() {
        Swift.print("This view is: \(self)")
        for sv in self.subviews {
            sv.printAllSubviews()
        }
    }
}