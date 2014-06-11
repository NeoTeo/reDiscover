//
//  CoverArtArchiveWebFetcher.swift
//  reDiscover
//
//  Created by Matteo Sartori on 05/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation
import AppKit

@objc

protocol SongPoolAccessProtocol {
    func UUIDStringForSongID(songID: AnyObject) -> NSString
    func releasesForSongID(songID: AnyObject) -> NSData
    func albumForSongID(songID: AnyObject) -> NSString
}

@objc

class CoverArtArchiveWebFetcher : NSObject {

    var delegate: SongPoolAccessProtocol?
    
    @objc func requestCoverArtForSong(songID: AnyObject, imageHandler: (NSImage) -> Void) {
        // See if the song has an UUID
//        - (NSString *)UUIDStringForSongID:(id)songID;

        let songUUID = delegate?.UUIDStringForSongID(songID)
        
        
        if songUUID != nil {
            println("We have an ID \(songUUID)")
            requestAlbumArtFromWebForSong(songID, imageHandler: imageHandler)
            
        } else {
            println(":( No ID")
        }
    }
    
    func requestAlbumArtFromWebForSong(songID: AnyObject, imageHandler: (NSImage) -> Void) {
        var theImage: NSImage?
        let data            = delegate?.releasesForSongID(songID)
        let songAlbum       = delegate?.albumForSongID(songID)
        var releases        = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary[]
        var lenient         = 0
        var foundAlbumArt = false

        var maxLoops = 2
        
        while !foundAlbumArt {
            for release in releases! {
                if release["title"] as? String == songAlbum {
                    
                    let releaseMBID = release["id"] as NSString
                    let coverArtArchiveURL = NSURL.URLWithString("http://coverartarchive.org/release/\(releaseMBID)")
                    // blocks (presumably) until the url returns the data. This means this function should be called on a non-main thread.
                    let result = NSData(contentsOfURL: coverArtArchiveURL) as NSData
                    
                    // skip if this did not return any data
                    if result == nil {
                        continue
                    }

                    let resultJSON: NSDictionary[] = NSJSONSerialization.JSONObjectWithData(result, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary[]
                    
//                    for entry: NSDictionary in resultJSON {
//                        let images = entry["images"] as NSArray
//                        println("The image entry is \(entry)")
//                        
//                    }
                    
                    foundAlbumArt = true;
                }
                println(release["title"])
            }
            
            foundAlbumArt = maxLoops-- == 0
        }
        
        
        // Go through various levels of leniency for album art.
//        var myReleases: AnyObject[] = releases!
        
    }
}


/* 
-(void)requestAlbumArtFromWebForSong:(TGSong*)song withHandler:(void (^)(NSImage*))imageHandler {
    NSImage* theImage;
    // At this point we know we have the data.
    NSArray* releases = [NSKeyedUnarchiver unarchiveObjectWithData:song.TEOData.songReleases];

    int lenient = 0;
    do {
        for (NSDictionary* release in releases) {
        // pick the best one. Eg. compare the release album name with the song's and pick the closest match.
            if (lenient || [song.TEOData.album isEqualToString:[release objectForKey:@"title"]]) {

                NSString* releaseMBID = [release objectForKey:@"id"];

                NSURL *coverartarchiveURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://coverartarchive.org/release/%@",releaseMBID]];

                NSData* result = [[NSData alloc] initWithContentsOfURL:coverartarchiveURL];
                if (result != nil) {

                    NSDictionary *resultJSON = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
                    NSArray* images = [resultJSON objectForKey:@"images"];
                    // Just pick first one for now
                    if ([images count]) {
                        NSDictionary* imageEntry = images[0];
                        NSURL* imageURL = [NSURL URLWithString:[imageEntry objectForKey:@"image"]];
                        NSData *coverartData = [[NSData alloc] initWithContentsOfURL:imageURL];
                        if (coverartData != nil) {
                            NSLog(@"got art for this release: %@",releaseMBID);
                            theImage = [[NSImage alloc] initWithData:coverartData];
                            imageHandler(theImage);
                            return;
                        }
                    }
                }
            }
        }
        NSLog(@"                                                                    Having a lenient go...");

        /* This goes straight to the image url.
        NSURL *coverartarchiveURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http:coverartarchive.org/release/%@/front",releaseMBID]];
        NSData *coverartData = [[NSData alloc] initWithContentsOfURL:coverartarchiveURL];
        if (coverartData != nil) {
            NSLog(@"got art for this release: %@",releaseMBID);
            theImage = [[NSImage alloc] initWithData:coverartData];
            imageHandler(theImage);
            return;
        }
        */
    }while (lenient++ == 0);
    // No luck, so we call the handler with nil.
    imageHandler(nil);
}

-(void)requestCoverArtForSong:(TGSong*)song withHandler:(void (^)(NSImage*))imageHandler {

// If there's no uuid, request one and drop out.
if (song.TEOData.uuid != NULL) {
[self requestAlbumArtFromWebForSong:song withHandler:imageHandler];
} else {
[song setFingerPrintStatus:kFingerPrintStatusRequested];
[self requestFingerPrintForSong:song withHandler:^(NSString* fingerPrint){

[self requestAlbumArtFromWebForSong:song withHandler:imageHandler];
}];
}
}


*/