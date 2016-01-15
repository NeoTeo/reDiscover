//
//  UploadedSSData.m
//  reDiscover
//
//  Created by Teo on 11/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

#import "UploadedSSData.h"

@implementation UploadedSSData

@dynamic sweetSpots;
@dynamic songUUID;


+ (instancetype)insertItemWithSongUUIDString:(NSString*)songUUID inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    UploadedSSData* ssData = [NSEntityDescription insertNewObjectForEntityForName:@"UploadedSSData" inManagedObjectContext:managedObjectContext];
    
    ssData.songUUID = songUUID;
    ssData.sweetSpots = nil;//[[NSSet alloc] init];
    
    return ssData;
}

@end
