//
//  TeoSongData.swift
//  reDiscover
//
//  Created by teo on 03/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

class TEOSongData : NSManagedObject {
    @NSManaged var album : String?
    @NSManaged var artist : String?
    @NSManaged var sweetSpots : NSArray?
}
/**
@interface TEOSongData : NSManagedObject

@property (nonatomic, retain) NSString*         album;
@property (nonatomic, retain) NSString*         artist;
@property (nonatomic, retain) NSArray*          sweetSpots;
@property (nonatomic, retain) NSString*         urlString;
@property (nonatomic, retain) NSString*         uuid;
@property (nonatomic, retain) NSNumber*         year;
@property (nonatomic, retain) NSString*         fingerprint;
@property (nonatomic, retain) NSString*         title;
@property (nonatomic, retain) NSString*         genre;
@property (nonatomic, retain) NSNumber*         selectedSweetSpot;
//@property (nonatomic, retain) NSNumber * artID;
@property (nonatomic, retain) NSData*           songReleases;

+ (instancetype)insertItemWithURLString:(NSString*)URLString
inManagedObje

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
ctContext:(NSManagedObjectContext *)managedObjectContext;

@end
*/