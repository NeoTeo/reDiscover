//
//  TEOSongData.h
//  reDiscover
//
//  Created by Teo Sartori on 21/04/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TEOSongData : NSManagedObject

@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSData * sweetSpotArray;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSString * fingerprint;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) NSNumber * selectedSweetSpot;
@property (nonatomic, retain) NSNumber * artID;

+ (instancetype)insertItemWithURLString:(NSString*)URLString
                 inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
