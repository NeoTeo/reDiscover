//
//  AcoustIDWebService.swift
//  reDiscover
//
//  Created by Teo on 29/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

class AcoustIDWebService: NSObject {

    static let acoustIdAPIKey = "QVFHY3iP"
    
    class func dataDict(forFingerprint fingerprint: String, ofDuration duration: UInt) -> NSDictionary? {

        let path = "http://api.acoustid.org/v2/lookup?client=\(acoustIdAPIKey)&meta=releases&duration=\(duration)&fingerprint=\(fingerprint)"

        if let
            acoustIdURL = NSURL(string: path),
            acoustiData = NSData(contentsOfURL: acoustIdURL) where acoustiData.length > 0 {
                
            do {
                if let acoustiJSON = try NSJSONSerialization.JSONObjectWithData(acoustiData, options: .MutableContainers) as? NSDictionary,
                    let status = acoustiJSON["status"] as? NSString where status.isEqualToString("ok"),
                    let results = acoustiJSON["results"] as? NSArray where results.count != 0,
                    let theElement = results.objectAtIndex(0) as? NSDictionary {
                        
                    return theElement
                }
            } catch {
                print("oh arse")
                return nil
            }
        }
        
        return nil
    }

    /**
    Extract all releases from the data dictionary returned by the AcoustId web service and compare it to
    the data in the given song. Return the release that best matches the song data.
    */
    class func bestMatchRelease(forSong song: TGSong, inDictionary dataDict: NSDictionary) -> NSDictionary? {
        var bestRelease: NSDictionary?
        var topScore = 0
        
        if let releases = dataDict["releases"] as? NSArray where releases.count > 0 {
            for release in releases as! [NSDictionary]{
                var releaseScore = 0
                //println("Release: \(release)")
                if let title = release["title"] as? String {
                    if title.lowercaseString == song.metadata?.album.lowercaseString { releaseScore += 1 }
                }
                
                //FIXME: For now just hardwired to US. Make it check for the user's country or some selected setting.
                if let country = release["country"] as? String {
                    if country.lowercaseString == "us" { releaseScore += 1 }
                }
                
                if let date = release["date"] as? NSDictionary,
                    let year = date["year"] as? UInt {
                    if year == song.metadata?.year { releaseScore += 1 }
                }

                // Not currently keeping track of the tracks on the album the song belongs to but when we
                // do this should come in handy
//                if let trackCount = release.objectForKey("track_count") as? NSNumber {
//                    println("Tracks: \(trackCount)")
//                }
                if releaseScore > topScore {
                    topScore = releaseScore
                    bestRelease = release
                }
            }
        }
        
        return bestRelease
    }
}

