//
//  CoverArtArchiveWebFetcher.swift
//  reDiscover
//
//  Created by Matteo Sartori on 05/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation

@objc

protocol SongPoolAccessProtocol {
    func UUIDStringForSongID(songID: AnyObject) -> NSString
}

@objc

class CoverArtArchiveWebFetcher : NSObject {

    var delegate: SongPoolAccessProtocol?
    
    @objc func requestCoverArtForSong(songID: AnyObject, imageHandler: AnyObject) {
        // See if the song has an UUID
//        - (NSString *)UUIDStringForSongID:(id)songID;

        let songUUID = delegate?.UUIDStringForSongID(songID)
        
        
        if songUUID != nil {
            println("We have an ID \(songUUID)")
        } else {
            println(":( No ID")
        }
    }
    
}


/* 
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

-(NSString*)testicle {
return @"Testicles";
}

-(void)requestAlbumArtFromWebForSong:(TGSong*)song withHandler:(void (^)(NSImage*))imageHandler {
NSImage* theImage;
// At this point we know we have the data.
NSArray* releases = [NSKeyedUnarchiver unarchiveObjectWithData:song.TEOData.songReleases];

NSString* ha = self.testicle;
NSLog(@"%@",ha);

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
NSURL *coverartarchiveURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://coverartarchive.org/release/%@/front",releaseMBID]];
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

*/