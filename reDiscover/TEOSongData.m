//
//  TEOSongData.m
//  reDiscover
//
//  Created by Teo Sartori on 21/04/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import "TEOSongData.h"


@implementation TEOSongData

@dynamic album;
@dynamic artist;
@dynamic sweetSpotArray;
@dynamic urlString;
@dynamic uuid;
@dynamic year;
@dynamic fingerprint;
@dynamic title;
@dynamic genre;
@dynamic selectedSweetSpot;
//@dynamic artID;
@dynamic songReleases;

+ (instancetype)insertItemWithURLString:(NSString*)URLString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    TEOSongData* songData = [NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                               inManagedObjectContext:managedObjectContext];
    songData.album             = nil;//@"dunno";
    songData.artist            = nil;//@"dunno";
    songData.sweetSpotArray    = nil;
    songData.urlString         = URLString;
    songData.uuid              = nil;
    songData.year              = [NSNumber numberWithInteger:0];
    songData.genre             = nil;//@"dunno";
    songData.title             = nil;//@"dunno";
    songData.fingerprint       = nil;
    songData.selectedSweetSpot = [NSNumber numberWithInteger:0];
//    songData.artID             = [NSNumber numberWithInteger:-1];
    songData.songReleases      = nil;
    
    return songData;
}

+ (NSString*)entityName {
    return @"TEOSongData";
}
@end
