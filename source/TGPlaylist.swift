//
//  TGPlaylist.swift
//  reDiscover
//
//  Created by teo on 28/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

/**
@interface TGPlaylist : NSObject <NSTableViewDataSource> {
NSMutableArray *songList;
//    NSUInteger posInPlaylist;
}

@property NSUInteger posInPlaylist;
//@property id<TGPlaylistDelegate> delegate;
@property id<TGSongPoolDelegate> delegate;


- (void)addSong:(id<SongIDProtocol>)aSongID atIndex:(NSUInteger)index;
- (void)removeSongAtIndex:(NSUInteger)index;
- (void)removeSong:(id<SongIDProtocol>)aSong;
- (id<SongIDProtocol>)getNextSongIDToPlay;
- (void)storeWithName:(NSString *)theName;
- (NSUInteger)songsInPlaylist;
- (id<SongIDProtocol>)songIDAtIndex:(NSUInteger)index;
@end
*/

class TGPlaylist : NSObject, NSTableViewDataSource {
    
    /// A list of song ids.
    var songList = [SongIDProtocol]()
    var positionInPlaylist = 0
    
    override init() {
        super.init()
    }
    
    func songsInPlaylist() -> Int {
        return songList.count
    }
    
    func getSongId(atIndex index : Int) -> SongIDProtocol? {
        
        guard index < songList.count else {
            print("ERROR: TGPlaylist getSongId index is out of bounds.")
            return nil
        }
        return songList[index]
    }
    
    func removeSong(atIndex index : Int) {
        guard index < songList.count else {
            print("ERROR: TGPlaylist getSongId index is out of bounds.")
            return
        }
        songList.removeAtIndex(index)
    }
    
    func removeSong(songId : SongIDProtocol) {
        
        if let idx = songList.indexOf( { songId.isEqual($0) }) {
            songList.removeAtIndex(idx)
        }
    }
    
    /** Adding to the song list is not a concurrent task so no need to them queue up.
        (for now)
    */
    func addSong(withId songId : SongIDProtocol, atIndex index : Int) {
        guard index < songList.count else {
            print("ERROR: TGPlaylist addSong index is out of bounds.")
            return
        }
        
        songList.insert(songId, atIndex: index)
    }
    
    func getNextSongIdToPlay() -> SongIDProtocol? {
        let songCount = songList.count
        guard songCount > 0 else { return nil }
        
        /// Increment the position in the playlist and wrap it to the song count.
        positionInPlaylist = (positionInPlaylist + 1) % songCount
       
        return songList[positionInPlaylist]
    }
    
    func store(withName fileName : String) {
        
        let paths = NSSearchPathForDirectoriesInDomains( .DocumentDirectory,
            .UserDomainMask,
            true)
        let documentsDirectory = paths[0]
        let fullPath = "\(documentsDirectory)/\(fileName).m3u"
        print("The playlist file url is: \(fullPath)")
        let m3uHeader = "#EXTM3U\n"
        let m3uExtInf = "#EXTINF:"
        
        /// Build the content.
        /// Start with the header.
        var content = m3uHeader
        
        for songId in songList {
            
            guard let song = SongPool.songForSongId(songId) else { continue }
            
            let songData = song.metadataDict()

            let songDuration    = songData["Duration"]
            let url             = songData["SongURL"]?.absoluteString
            let artist          = songData["Artist"]
            let title           = songData["Title"]
            
            let info            = "\(m3uExtInf)\(songDuration),\(artist) - \(title)\n"
            
            content += info + url!
        }
        
        print("The playlist content is \(content)")
        try! content.writeToFile(fullPath, atomically: false, encoding: NSUTF8StringEncoding)
    }
}