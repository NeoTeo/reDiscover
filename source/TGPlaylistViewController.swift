//
//  TGPlaylistController.swift
//  reDiscover
//
//  Created by teo on 28/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

public class TGPlaylistViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var playlistTableView: NSTableView!
    @IBOutlet weak var playlistProgress: NSProgressIndicator!

    
    private var playlist : TGPlaylist!
    
    public override func awakeFromNib() {
        if playlist == nil {
            playlist = TGPlaylist()
            
            playlistTableView.setDelegate(self)
            playlistTableView.setDataSource(self)
        }
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func storePlaylist(withName fileName : String) {
        
    }
    
    func addToPlaylist(songWithId songId : SongIDProtocol) {
        
    }
    
    func removeFromPlaylist(songWithId songId : SongIDProtocol) {
        
    }
    
    func getNextSongIdToPlay() -> SongIDProtocol? {
        return nil
    }
}

/// TGPlaylistDelegate methods ?
//extension TGPlaylistViewController {
//    
//    func songData(forSongId songId : SongIDProtocol) -> NSDictionary {
//        
//    }
//}

/// NSTableViewDataSource delegate methods
extension TGPlaylistViewController {
    
    public func numberOfRowsInTableView(tableview : NSTableView) -> Int {
        return 0
    }
    
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil
    }
}

/// NSTableViewDelegate methods
extension TGPlaylistViewController {
    
    public func tableViewSelectionDidChange(notification: NSNotification) {
        
    }
}
