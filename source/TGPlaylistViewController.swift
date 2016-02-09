//
//  TGPlaylistController.swift
//  reDiscover
//
//  Created by teo on 28/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa

protocol PlaylistViewControllerDelegate {
    func getSong(songId : SongId) -> TGSong?
    func requestPlayback(songId: SongId, startTimeInSeconds: NSNumber)
    func selectIndirectly(songId : SongId)
}

public class TGPlaylistViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var playlistTableView: NSTableView!
    @IBOutlet weak var playlistProgress: NSProgressIndicator!

    
    private var playlist : TGPlaylist!
    
    var delegate : PlaylistViewControllerDelegate?
    
    public override func awakeFromNib() {
        if playlist == nil {
            playlist = TGPlaylist()
            
            playlist.delegate = self
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
        playlist.store(withName: fileName)
    }
    
    func addToPlaylist(songWithId songId : SongId) {
        playlist.addSong(withId: songId, atIndex: 0)
        /// TODO: Consider reloading only the changed row
        playlistTableView.reloadData()
    }
    
    func removeFromPlaylist(songWithId songId : SongId) {
        playlist.removeSong(songId)
        playlistTableView.reloadData()
    }
    
    func getNextSongIdToPlay() -> SongId? {
        return playlist.getNextSongIdToPlay()
    }
}

/// TGPlaylistDelegate methods ?
//extension TGPlaylistViewController {
//    
//    func songData(forSongId songId : SongId) -> NSDictionary {
//        
//    }
//}

/// NSTableViewDataSource delegate methods
extension TGPlaylistViewController {
    
    public func numberOfRowsInTableView(tableview : NSTableView) -> Int {
        return playlist.songsInPlaylist()
    }
    
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let resultCell  = tableView.makeViewWithIdentifier("SongCell", owner: self) as? TGPlaylistCellView,
            let id = playlist.getSongId(atIndex: row),
            let song = delegate?.getSong(id) else {
                return nil
        }
        
        let songData = song.metadataDict()
        guard songData.count > 0 else { return nil }
        
        resultCell.titleLabel.stringValue   = songData["Title"] as! String
        resultCell.albumLabel.stringValue   = songData["Album"] as! String
        resultCell.artistLabel.stringValue  = songData["Artist"] as! String
        
        return resultCell
    }
}

/// NSTableViewDelegate methods
extension TGPlaylistViewController {
    
    public func tableViewSelectionDidChange(notification: NSNotification) {
        let selectedRow = playlistTableView.selectedRow
        if selectedRow >= 0 {
            playlist.positionInPlaylist = selectedRow
            
            if let songId = playlist.getSongId(atIndex: selectedRow) {
                //delegate?.requestPlayback(songId, startTimeInSeconds: 0)
                delegate?.selectIndirectly(songId)
            }
            playlistTableView.deselectRow(selectedRow)
            /// FIXME: Not sure the responder should be self. Used to be _delegate
            self.view.window?.makeFirstResponder(self)
        }
    }
    
    /// Ensure the row height is sufficient.
    public func tableView(tableView: NSTableView,heightOfRow row: Int) -> CGFloat {
        return 67
    }
}

extension TGPlaylistViewController : PlaylistDelegate {
    func getSong(songId : SongId) -> TGSong? {
        return delegate?.getSong(songId)
    }
}
