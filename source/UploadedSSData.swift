//
//  UploadedSSData.swift
//  reDiscover
//
//  Created by teo on 09/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import CoreData

/*
@interface UploadedSSData : NSManagedObject

@property (nonatomic, retain) NSArray* sweetSpots;
@property (nonatomic, retain) NSString* songUUID;

+ (instancetype)insertItemWithSongUUIDString:(NSString*)songUUID inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;


@end
*/
class UploadedSSData : NSManagedObject {
    @NSManaged var sweetSpots : NSArray?
    @NSManaged var songUUID : String?
}

extension UploadedSSData {
	
    class func insert(songUuid : String, inContext context : NSManagedObjectContext) -> AnyObject? {
		
        if let ssData = NSEntityDescription.insertNewObjectForEntityForName("UploadedSSData", inManagedObjectContext: context) as? UploadedSSData {
            
            ssData.songUUID = songUuid
            ssData.sweetSpots = nil
            
            return ssData
        }
        
        return nil
    }
}
/*
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

*/