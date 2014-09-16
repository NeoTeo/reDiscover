//
//  SweetSpotServerIO.swift
//  reDiscover
//
//  Created by Teo on 15/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

class SweetSpotServerIO: NSObject {

    // Should this be lazy?
    var uploadedSweetSpots: Dictionary<String,UploadedSSData>?
    var uploadedSweetSpotsMOC: NSManagedObjectContext?;
    
    override init() {
        super.init()
        setupUploadedSweetSpotsMOC()
//        initUploadedSweetSpots()
    }
    
    /**
    Set up the Core Data persistent store for sweet spots that have already been uploaded to the server.
    */
    func setupUploadedSweetSpotsMOC() {
        var error: NSError?
        
        if let modelURL = NSBundle.mainBundle().URLForResource("uploadedSS", withExtension: "momd") {

            if let mom = NSManagedObjectModel(contentsOfURL: modelURL) {
            
                uploadedSweetSpotsMOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                uploadedSweetSpotsMOC?.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
                
                // Build the URL where to store the data.
                let documentsDirectory = NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true, error: &error)?.URLByAppendingPathComponent("uploadedSS.xml")

                uploadedSweetSpotsMOC?.persistentStoreCoordinator.addPersistentStoreWithType(NSXMLStoreType,configuration: nil,URL: documentsDirectory, options: nil, error: &error)
                
                if error != nil {
                    println("SweetSpotServerIO init error: \(error)")
                }
            }
        }
        //
    }
    
//    func initUploadedSweetSpots()
    
    
    func uploadSweetSpotForSongID(sweetSpot: NSNumber, songID: SongIDProtocol) -> Bool {
        return true;
    }
    
    func requestSweetSpotsForSongID(songID: SongIDProtocol) -> NSSet? {
        var theSweetSpots: NSSet?
        
        return theSweetSpots;
    }
}
