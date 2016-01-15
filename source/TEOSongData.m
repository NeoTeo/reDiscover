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
@dynamic sweetSpots;
@dynamic urlString;
@dynamic uuid;
@dynamic year;
@dynamic fingerprint;
@dynamic title;
@dynamic genre;
@dynamic selectedSweetSpot;
@dynamic songReleases;

+ (instancetype)insertItemWithURLString:(NSString*)URLString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    TEOSongData* songData = [NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                               inManagedObjectContext:managedObjectContext];
    songData.album             = nil;
    songData.artist            = nil;
    songData.sweetSpots        = [[NSArray alloc] init];
    songData.urlString         = URLString;
    songData.uuid              = nil;
    songData.year              = [NSNumber numberWithInteger:0];
    songData.genre             = nil;
    songData.title             = nil;
    songData.fingerprint       = nil;
    songData.selectedSweetSpot = nil;
    songData.songReleases      = nil;
    
    return songData;
}

+ (NSString*)entityName {
    return @"TEOSongData";
}
@end
