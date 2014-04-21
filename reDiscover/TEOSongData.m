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
@dynamic url;
@dynamic uuid;
@dynamic year;
@dynamic fingerprint;
@dynamic title;
@dynamic genre;
@dynamic selectedSweetSpot;
@dynamic artID;

+ (instancetype)insertItemWithURLString:(NSString*)URLString
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    TEOSongData* songData = [NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                               inManagedObjectContext:managedObjectContext];
    songData.url        = URLString;
    songData.album      = @"dunno";
    songData.artist     = @"dunno";
    songData.genre      = @"dunno";
    songData.title      = @"dunno";
    
    return songData;
}

+ (NSString*)entityName {
    return @"TEOSongData";
}
@end
