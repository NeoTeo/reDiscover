//
//  SongUUID.swift
//  reDiscover
//
//  Created by Teo on 07/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongData {
    
}

struct UUIDData : SongData {
    let uuid: String?
}


class SongUUID : NSObject {

    static func getUUIDForSong(song: TGSong) -> String {
        return song.UUId!
    }
    
    static func songWithNewUUId(song: TGSong, newUUId: String) -> TGSong {
        return Song(songId: song.songID, metadata: song.metadata, urlString: song.urlString,
            sweetSpots: song.sweetSpots, fingerPrint: song.fingerPrint, selectedSS: song.selectedSweetSpot,
            releases: song.songReleases, artId: song.artID, UUId: newUUId)
    }
    
//    func UUIDForSong(song: SongIDProtocol, duration: UInt, fingerprint: String) -> SongUUID? {
    static func lookupUUIDForSong(song: TGSong, duration: UInt, fingerprint: String) -> String {
        let path = "http://api.acoustid.org/v2/lookup?client=8XaBELgH&meta=releases&duration=\(duration)&fingerprint=\(fingerprint)"
        if let
            acoustIdURL = NSURL(string: path),
            acoustiData = NSData(contentsOfURL: acoustIdURL) { //where acoustiData.length != 0 {
            
                if acoustiData.length == 0 {
                    println("UUIDForSong - no acoustic data!")
                    return ""
                }
                if let acoustiJSON = NSJSONSerialization.JSONObjectWithData(acoustiData, options: .MutableContainers, error: nil) as? NSDictionary {
                    if let status = acoustiJSON.objectForKey("status") as? NSString where status.isEqualToString("ok"),
                        let results = acoustiJSON.objectForKey("results") as? NSArray where results.count != 0
                    {
                        let theElement = results.objectAtIndex(0) as? NSDictionary
                        if let uuidString = theElement?.objectForKey("id") as? String {
                            return uuidString
                            //return UUIDData(uuid: uuidString)
                        }
                    }
                }
        }
        return ""
    }
}