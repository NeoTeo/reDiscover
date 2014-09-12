//
//  UploadedSSData.h
//  reDiscover
//
//  Created by Teo on 11/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UploadedSSData : NSManagedObject

@property (nonatomic, retain) NSSet* sweetSpots;
@property (nonatomic, retain) NSString* songUUID;

+ (instancetype)insertItemWithSongUUIDString:(NSString*)songUUID inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;


@end
