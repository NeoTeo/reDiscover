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
    static func managedObjectContext(_ modelName: String) -> NSManagedObjectContext? {
        
        var moc: NSManagedObjectContext?
        
        if let modelURL = Bundle.main().urlForResource(modelName, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) {
                
            moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            moc!.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
                
            do {
            
            let docPath = try! FileManager.default().urlForDirectory(FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask,
                appropriateFor: nil,
                create: true).appendingPathComponent("reDiscoverdb_v2.sqlite")
                
            
                try moc!.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: docPath,
                    options: nil)
            } catch {
                print("Error in managedObjectContext \(error)")
            }
            
        }
        
        return moc
    }
    
    static func fetchSongsMetaData(_ context: NSManagedObjectContext) -> [String : SongMetaData]? {
        
        // FIXME: this is not wired up properly anymore
        /*
        let fetchRequest = NSFetchRequest<SongMetaData>()
        var songsMetaData: [String : SongMetaData]?
        
        context.performAndWait {
            let fetchedArray: [AnyObject]?
            do {
                fetchedArray = try context.fetch(fetchRequest)
            } catch {
                fatalError("Error while fetching SongMetaData: \(error)")
            }
            songsMetaData = [:]
            for songData in fetchedArray as! [SongMetaData] {
                songsMetaData![songData.generatedMetaData.URLString] = songData
            }
        }
        
        return songsMetaData
         */
        return nil
    }
    
    static func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            context.performAndWait {
                do {
                    try context.save()
                    
                } catch {
                    print("Error saving!")
                }
            }
        }
    }
    
    static func saveContext(_ moc : NSManagedObjectContext, privateMoc : NSManagedObjectContext, wait : Bool) {
        if moc.hasChanges {
            moc.performAndWait {
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
                privateMoc.performAndWait(savePrivate)
            } else {
                privateMoc.perform(savePrivate)
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
