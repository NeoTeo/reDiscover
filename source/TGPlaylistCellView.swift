//
//  TGPlaylistCellView.swift
//  reDiscover
//
//  Created by teo on 28/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

/**
@interface TGPlaylistCellView : NSTableCellView

@property IBOutlet NSTextField *TitleLabel;
@property IBOutlet NSTextField *AlbumLabel;
@property IBOutlet NSTextField *ArtistLabel;

@end
*/

public class TGPlaylistCellView : NSTableCellView {
 
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var albumLabel: NSTextField!
    @IBOutlet weak var artistLabel: NSTextField!
    
    
    public override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
}