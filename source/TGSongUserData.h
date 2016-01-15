//
//  TGSongUserData.h
//  Proto3
//
//  Created by Teo Sartori on 13/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface TGSongUserData : NSManagedObject

@property (nonatomic, strong) NSString *songURL;
@property (nonatomic, strong) NSString *songUUID;
@property (nonatomic, strong) NSString *songFingerPrint;
@property (nonatomic) float songUserSweetSpot;
@property (nonatomic, strong) NSData *songSweetSpots;
@end
