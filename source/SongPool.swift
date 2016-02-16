//
//  SongPool.swift
//  reDiscover
//
//  Created by Teo on 27/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation

typealias SongDictionary = [SongId: Song]

final class SongPool : NSObject, SongPoolAccessProtocol {

    private var songPool: SongDictionary?
    private var songPoolAccessQ: dispatch_queue_t?
    private var serialDataLoad = dispatch_queue_create("serial data load queue", DISPATCH_QUEUE_SERIAL)
	
    /** Utility function allows wrapping code that needs to be sync'd on
        a queue in a block like this:
        synchronized {
            access common stuff...
            ...
        }
    */
    private func synchronized(f: Void -> Void) {
		
        guard songPoolAccessQ != nil else { fatalError("No songPoolAccessQ") }
        dispatch_sync(songPoolAccessQ!, f)
    }

    
    /// Request the song for the given id and return a copy of it.
    func songForSongId(songId: SongId) -> TGSong? {
        return songPool?[songId]
    }
    
    func getUrl(songId: SongId) -> NSURL? {
        guard let song = songForSongId(songId) where (song.urlString != nil) else { return nil }
        return NSURL(string: song.urlString!)
    }
    
    func UUIDStringForSongId(songId: SongId) -> String? {
        guard let song = songForSongId(songId) else { return nil }
        return SongUUID.getUUIDForSong(song)
    }
    
    func songCount() -> Int {
        guard let count = songPool?.count else { return 0 }
        return count
    }

    func load(anUrl: NSURL) -> Bool {
        dispatch_async(serialDataLoad) {
            self.fillSongPoolWithSongURLsAtURL(anUrl)
        }
        return true
    }
	
    /**
        Make and return a dictionary of songs made from any audio URLs found 
        from the given URL.
    */
    func fillSongPoolWithSongURLsAtURL(theURL: NSURL){
//        var allSongs = [SongId: Song]()
        songPool = SongDictionary()
        songPoolAccessQ = dispatch_queue_create("songPool dictionary access queue", DISPATCH_QUEUE_SERIAL)
        
        LocalAudioFileStore.applyAudioURLsToClosure(theURL) { songURL in
            
            //MARK: At this point we want to check if our core data store has info on the song.
            let songString = songURL.absoluteString
            let songId = SongId(string: songString)
            let songCommonMetaData : SongCommonMetaData? = nil//SongCommonMetaData()
            let newSong = Song(songId: songId, metadata: songCommonMetaData, urlString: songString, sweetSpots: nil, fingerPrint: nil, selectedSS: nil, releases: nil, artId: nil, UUId: nil, RelId: nil)
            
            self.addSong(newSong)
            
            NSNotificationCenter.defaultCenter().postNotificationName("NewSongAdded", object: songId)
        }
    }

    func addSong(theSong: TGSong) {
        
        synchronized {
            self.songPool![theSong.songId] = theSong as? Song
        }
    }
    
    func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId) {

        /// FIXME : Do we really need to sync _all_ of this?
        synchronized {
            // First we get the up-to-date song
            let oldSong = self.songForSongId(songId)
            
            // Then we create a new song from the old song and the new metadata (want crash if oldSong is nil)
            let newSong = Song.songWithChanges(oldSong!, changes: changes)
            
            // Then we add that new song to the song pool using the songId
            self.songPool![songId] = newSong as? Song
        }
    }
     
    /*
    So this should just store the data in the song pool and let the sweet spot
    server save its own stuff?
    
    static func storeSongData() {
    
//        save(songPool)
        
        /// We need the MOC and Private MOC to be available
        CoreDataStore.save(
    
        SweetSpotServerIO.storeUpload...etc
    }
    */
    /**
     - (void)storeSongData {
         // REFAC
         [SongPool save:songPoolDictionary];
         
         // TEOSongData test
         [self saveContext:NO];
         
         // uploadedSweetSpots save
         [SweetSpotServerIO storeUploadedSweetSpotsDictionary];
         
         return;
     }
*/
    /**
        Traverse the pool of songs and, for each, compare the metadata fields we want to save with the
        metadata fields of the corresponding core data item. If they differ, update the core data item so
        that it is saved when we call the associated managed object context's save.
    */
    
    /// FIXME : This doesn't do anything yet.
    static func save(pool: NSDictionary) {
//        let myStore = SongMetaDataStoreLocal(metaData:[:])

        for (_,value) in pool {
            let song: Song = value as! Song
            if let cmd = song.metadata {

                let genMD = SongGeneratedMetaData(UUId: song.UUId, URLString: song.urlString!)
                let theMetaData = SongMetaData(common: cmd, genMetaData: genMD)

                print("I gots: \(theMetaData.commonMetaData.title)")
            }
        }
    }
}

extension SongPool : AlbumCollectionDelegate {
    func getSong(songId : SongId) -> TGSong? {
        return songForSongId(songId)
    }
}

extension SongPool {
    
    func debugLogSongWithId(songId: SongId) {
        
        guard let song = getSong(songId) else { return }
            
        print("Song with id \(songId) has: ")
		print("duration \(song.duration())")
		if let sweeties = song.sweetSpots {
			print("sweet spots: ")
			for ss in sweeties {
				print("ss: \(ss)")
			}
		} else {
			print("No sweetspots")
		}
    }
    
    func debugLogCaches() {    }
}