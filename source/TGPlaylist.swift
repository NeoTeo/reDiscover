//
//  TGPlaylist.swift
//  reDiscover
//
//  Created by teo on 28/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//
import Cocoa

/**
@interface TGPlaylist : NSObject <NSTableViewDataSource> {
NSMutableArray *songList;
//    NSUInteger posInPlaylist;
}

@property NSUInteger posInPlaylist;
//@property id<TGPlaylistDelegate> delegate;
@property id<TGSongPoolDelegate> delegate;


- (void)addSong:(id<SongId>)aSongID atIndex:(NSUInteger)index;
- (void)removeSongAtIndex:(NSUInteger)index;
- (void)removeSong:(id<SongId>)aSong;
- (id<SongId>)getNextSongIDToPlay;
- (void)storeWithName:(NSString *)theName;
- (NSUInteger)songsInPlaylist;
- (id<SongId>)songIDAtIndex:(NSUInteger)index;
@end
*/

protocol PlaylistDelegate {
    func getSong(_ songId : SongId) -> TGSong?
}

class TGPlaylist : NSObject, NSTableViewDataSource {
    
    /// A list of song ids.
    var songList = [SongId]()
    var positionInPlaylist = 0
    
    //var songPoolAPI : SongPoolAccessProtocol?
    var delegate : PlaylistDelegate?
    
    override init() {
        super.init()
    }
    
    func songsInPlaylist() -> Int {
        return songList.count
    }
    
    func getSongId(atIndex index : Int) -> SongId? {
        
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
        songList.remove(at: index)
    }
    
    func removeSong(_ songId : SongId) {
        
//        if let idx = songList.indexOf( { SongId.isEqual($0) }) {
        if let idx = songList.index( where: { songId == $0 }) {
            songList.remove(at: idx)
        }
    }
    
    /** Adding to the song list is not a concurrent task so no need to them queue up.
        (for now)
    */
    func addSong(withId songId : SongId, atIndex index : Int) {
        guard index <= songList.count else {
            print("ERROR: TGPlaylist addSong index is out of bounds.")
            return
        }
        
        songList.insert(songId, at: index)
    }
    
    func getNextSongIdToPlay() -> SongId? {
        let songCount = songList.count
        guard songCount > 0 else { return nil }
        
        /// Increment the position in the playlist and wrap it to the song count.
        positionInPlaylist = (positionInPlaylist + 1) % songCount
       
        return songList[positionInPlaylist]
    }
    
    func store(withName fileName : String) {
        
        let paths = NSSearchPathForDirectoriesInDomains( .documentDirectory,
            .userDomainMask,
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
            
            guard let song = delegate?.getSong(songId) else { continue }
            
            let songData = song.metadataDict()

            guard let songDuration = songData["Duration"],
                  let artist = songData["Artist"],
                  let title = songData["Title"] else {
                continue
            }
            
            content += "\(m3uExtInf)\(songDuration),\(artist) - \(title)\n"
        }
        
        print("The playlist content is \(content)")
        try! content.write(toFile: fullPath, atomically: false, encoding: String.Encoding.utf8)
    }
}
