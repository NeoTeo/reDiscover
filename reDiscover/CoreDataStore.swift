//
//  CoreDataStore.swift
//  reDiscover
//
//  Created by Teo on 14/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

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
    static func managedObjectContext(name: String) -> NSManagedObjectContext? {
        if let modelURL = NSBundle.mainBundle().URLForResource(name, withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOfURL: modelURL) {
                
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            let privateMOC: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                
            privateMOC.persistentStoreCoordinator = coordinator
            
            let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            var error: NSError?
            let documentDir = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: true, error: &error)
            let docPath = documentDir?.URLByAppendingPathComponent("reDiscoverdb_v2.sqlite")
                
            moc.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: docPath,
                options: nil, error: &error)
                
            if error != nil {
                println("Error in managedObjectContext \(error)")
                return nil
            }
            
            return moc
        }
        
        return nil
    }
    
    static func fetchSongMetaData(context: NSManagedObjectContext) -> [String : SongMetaData]? {
        
        let fetchRequest = NSFetchRequest(entityName: "SongMetaData")
        var error: NSError?
        var songMetaData: [String : SongMetaData]?
        
        context.performBlockAndWait {
            let fetchedArray = context.executeFetchRequest(fetchRequest, error: &error)
            if error != nil {
                println("Error while fetching SongMetaData: \(error?.localizedDescription)")
                return
            }
            songMetaData = [:]
            for songData in fetchedArray as! [SongMetaData] {
                songMetaData![songData.generatedMetaData.URLString] = songData
            }
        }
        
        return songMetaData
    }
}