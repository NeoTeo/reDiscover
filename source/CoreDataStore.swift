//
//  CoreDataStore.swift
//  reDiscover
//
//  Created by Teo on 14/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import CoreData

struct CoreDataStore {
    
}

extension CoreDataStore {
    
    /**
    A MOC whose parent context is nil is considered a root context and is connected directly to the persistent store coordinator.
    If a MOC has a parent context the MOC's fetch and save ops are mediated by the parent context.
    This means the parent context can, on its own private thread, service the requests from various children on different threads.
    Changes to a context are only committed one store up. If you save a child context, changes are pushed to its parent.
    Only when the root context is saved are the changes committed to the store (by the persistent store coordinator associated with the root context).
    A parent context does *not* pull from its children before it saves, so the children must save before the parent.
    */
    static func managedObjectContext(modelName: String) -> NSManagedObjectContext? {
        
        var moc: NSManagedObjectContext?
        
        if let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOfURL: modelURL) {
                
            moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            moc!.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
                
            do {
            
            let docPath = try NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.DocumentDirectory,
                inDomain: NSSearchPathDomainMask.UserDomainMask,
                appropriateForURL: nil,
                create: true).URLByAppendingPathComponent("reDiscoverdb_v2.sqlite")
                
            
                try moc!.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType,
                    configuration: nil,
                    URL: docPath,
                    options: nil)
            } catch {
                print("Error in managedObjectContext \(error)")
            }
            
        }
        
        return moc
    }
    
    static func fetchSongsMetaData(context: NSManagedObjectContext) -> [String : SongMetaData]? {
        
        let fetchRequest = NSFetchRequest(entityName: "SongMetaData")
        var songsMetaData: [String : SongMetaData]?
        
        context.performBlockAndWait {
            let fetchedArray: [AnyObject]?
            do {
                fetchedArray = try context.executeFetchRequest(fetchRequest)
            } catch {
                fatalError("Error while fetching SongMetaData: \(error)")
            }
            songsMetaData = [:]
            for songData in fetchedArray as! [SongMetaData] {
                songsMetaData![songData.generatedMetaData.URLString] = songData
            }
        }
        
        return songsMetaData
    }
    
    static func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            context.performBlockAndWait {
                do {
                    try context.save()
                    
                } catch {
                    print("Error saving!")
                }
            }
        }
    }
    
    static func saveContext(moc : NSManagedObjectContext, privateMoc : NSManagedObjectContext, wait : Bool) {
        if moc.hasChanges {
            moc.performBlockAndWait {
                do {
                    
                    try moc.save()
                    
                } catch {
                    print("CoreDataStore Error: saving MOC \(error)")
                }
            }
        }
        
        if privateMoc.hasChanges {
            let savePrivate = {
                do { try privateMoc.save() } catch {
                    print("CoreDataStore Error: saving PrivateMOC \(error)")
                }
            }

            if wait {
                privateMoc.performBlockAndWait(savePrivate)
            } else {
                privateMoc.performBlock(savePrivate)
            }
        }
    }
    /**
    - (void)saveContext:(BOOL)wait {
        NSManagedObjectContext *moc = self.TEOmanagedObjectContext;
        NSManagedObjectContext *private = [self privateContext];
        
        if (!moc) return;
        if ([moc hasChanges]) {
            [moc performBlockAndWait:^{
                NSError *error = nil;
                NSAssert([moc save:&error], @"Error saving MOC: %@\n%@",
            [error localizedDescription], [error userInfo]);
            }];
        }
        
        void (^savePrivate) (void) = ^{
            NSError *error = nil;
            NSAssert([private save:&error], @"Error saving private moc: %@\n%@",
            [error localizedDescription], [error userInfo]);
        };
        
        if ([private hasChanges]) {
            if (wait) {
                [private performBlockAndWait:savePrivate];
            } else {
                [private performBlock:savePrivate];
            }
        }
    }
    */
}