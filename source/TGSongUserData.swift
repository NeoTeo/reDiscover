//
//  TGSongUserData.swift
//  reDiscover
//
//  Created by teo on 03/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import CoreData

/**
@interface TGSongUserData : NSManagedObject

@property (nonatomic, strong) NSString *songURL;
@property (nonatomic, strong) NSString *songUUID;
@property (nonatomic, strong) NSString *songFingerPrint;
@property (nonatomic) float songUserSweetSpot;
@property (nonatomic, strong) NSData *songSweetSpots;
@end

@implementation TGSongUserData

// Tell the compiler the setters and getters for the following properties are created dynamically at runtime.
@dynamic songURL, songFingerPrint, songUUID, songUserSweetSpot,songSweetSpots;

@end

*/

class TGSongUserData : NSManagedObject {
    @NSManaged dynamic var songURL : String?
    @NSManaged var songUUID : String?
    @NSManaged var songFingerPrint : String?
    @NSManaged var songUserSweetSpot : Float
    @NSManaged var songSweetSpots : NSData?
}