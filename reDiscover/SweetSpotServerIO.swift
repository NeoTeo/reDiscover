//
//  SweetSpotServerIO.swift
//  reDiscover
//
//  Created by Teo on 15/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

/**
    The SweetSpotServerIO class handles communication with the sweet spot web server.

    It maintains a locally persisted store, uploadedSweetSpots, of all the songs whose sweet spots have already been 
    uploaded to the server in order to avoid re-sending them.

    The uploadedSweetSpots is a dictionary of song ids and the sweet spots of that song that have been succesfully
    uploaded to the server. It is written out whenever the application quits (currently saving is manual) and loaded back
    in on application start, before the application attempts to import whatever song urls the user has passed in.
    When TGSongPool loads a song url and sweet spots are found, it is checked, using the song's uuid, against the 
    uploadedSweetSpots and any sweet spots not in there will be uploaded to the server.
*/
class SweetSpotServerIO: NSObject {

    let opQueue: NSOperationQueue?
    // The delegate to communicate with song pool
    var delegate: SongPoolAccessProtocol?
    // Should this be lazy?
    
    // The location of the SweetSpotServer. For now it's just localhost.
    let hostNameAndPort = "localhost:6969"
    
    var uploadedSweetSpots: Dictionary<String,UploadedSSData> = [String:UploadedSSData]()
    var uploadedSweetSpotsMOC: NSManagedObjectContext?
    
    override init() {
        super.init()
        
        // Start an asynchronous operation queue
        opQueue = NSOperationQueue()
        
        setupUploadedSweetSpotsMOC()
        initUploadedSweetSpots()
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
    }
    
    
    func initUploadedSweetSpots() {
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "UploadedSSData")
        
        uploadedSweetSpotsMOC?.performBlockAndWait(){
            if let fetchedArray = self.uploadedSweetSpotsMOC?.executeFetchRequest(fetchRequest, error: &error) {
                if error != nil {
                    println(error?.localizedDescription ?? "Unknown error.")
                    return
                }
                
//                self.uploadedSweetSpots = [String:UploadedSSData]()
                for ss in fetchedArray {
                    let ssData = ss as UploadedSSData
                    self.uploadedSweetSpots[ssData.songUUID] = ssData
                    println("The ssData songUUID is \(ssData.songUUID) and its sweetspots \(ssData.sweetSpots)")
                }
                
                println("initUploadedSweetSpots done. Loaded \(self.uploadedSweetSpots.count)")
            }
        }
    }
    
    
    func storeUploadedSweetSpotsDictionary() {
        if uploadedSweetSpotsMOC == nil {
            println("ERROR: uploaded sweet spots managed object context is nil.")
            return
        }
        
        if uploadedSweetSpotsMOC!.hasChanges {
            uploadedSweetSpotsMOC!.performBlockAndWait() {
                var error: NSError?
                assert(self.uploadedSweetSpotsMOC!.save(&error), "Error saving uploaded sweet spots MOC. \(error)")
            }
        }
    }
    
    
    func sweetSpotHasBeenUploaded(theSS: Double, theSongID: SongIDProtocol) -> Bool {
        if let songUUID = delegate?.UUIDStringForSongID(theSongID) {
            if let ssData = uploadedSweetSpots[songUUID] as UploadedSSData? {
                if let sweetSpots = ssData.sweetSpots as NSArray? {
                    return sweetSpots.containsObject(theSS)
                }
            }
        }
        return false
    }
    
    func uploadSweetSpotsForSongID(songID: SongIDProtocol) -> Bool {
        // First get the song's uuid
        let songUUID = delegate?.UUIDStringForSongID(songID)
        if songUUID == nil {
            println("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return false
        }
        if let sweetSpots = delegate?.sweetSpotsForSongID(songID) {
            for sweetSpot in sweetSpots {
                if sweetSpotHasBeenUploaded(sweetSpot as Double, theSongID: songID) {
                    println("Has been uploaded")
                    continue
                }

                let requestIDURL = NSURL(string: "http://\(hostNameAndPort)/submit?songUUID=\(songUUID!.utf8)&songSweetSpot=\(sweetSpot as Double)")
                if requestIDURL == nil { return false }
                
                println("this is a sweetSpot upload url \(requestIDURL!)")
                
                let requestData = NSData(contentsOfURL: requestIDURL!)
                if requestData == nil {
                    println("ERROR: No data returned from SweetSpotServer.")
                    return false
                }
                
                let requestJSON = NSJSONSerialization.JSONObjectWithData(requestData!, options: NSJSONReadingOptions.MutableContainers , error: nil) as NSDictionary?
                
                if requestJSON == nil {
                    println("Error serializing JSON data.")
                    return false
                }
                
                if let status = requestJSON!.objectForKey("status") as String? {
                    if (status == "ok") != nil {
                        println("Upload to SweetSpotServer returned OK")
                        
                        var uploadedSS = uploadedSweetSpots[songUUID!]
                        if uploadedSS == nil {
                            // The song has no existing sweetspots so we create a new set with the sweet spot.
                            uploadedSS = UploadedSSData.insertItemWithSongUUIDString(songUUID!, inManagedObjectContext: uploadedSweetSpotsMOC) as UploadedSSData
                            uploadedSS?.sweetSpots = NSArray(object: sweetSpot)
                        } else {
                            // The song already has a set of sweetspots so we need to add to it.
//                            var existingSS = uploadedSS!.sweetSpots.mutableCopy() as NSMutableArray
                            var existingSS = NSMutableArray(array: uploadedSS!.sweetSpots)
                            existingSS.addObject(sweetSpot)
                            uploadedSS!.sweetSpots = existingSS.copy() as NSArray
                        }
                        
                        // Add the new data to the dictionary
                        uploadedSweetSpots[songUUID!] = uploadedSS!
                        
                    }
                }
                
            }
        }
        return true;
    }
    
//    func uploadSweetSpotForSongID(sweetSpot: NSNumber, songID: SongIDProtocol) -> Bool {
//        return true;
//    }
    
    func requestSweetSpotsForSongID(songID: SongIDProtocol) -> NSArray? {
        let songUUID = delegate?.UUIDStringForSongID(songID)
        if songUUID == nil {
            println("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return nil
        }
        
        let theURL = NSURL(string: "http://\(hostNameAndPort)/lookup?songUUID=\(songUUID!.utf8)")
        if theURL == nil { return nil }
        
        let theRequest = NSURLRequest(URL: theURL!)
        
        NSURLConnection.sendAsynchronousRequest(theRequest, queue: opQueue!, completionHandler: {
                (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data != nil {
                
                let requestJSON = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers , error: nil) as NSDictionary?
                
                if requestJSON == nil {
                    println("Error serializing JSON data.")
                    return
                }
                
                if let status = requestJSON!.objectForKey("status") as String? {
                    if (status == "ok") == nil { return }
                        
                    let result: AnyObject? = requestJSON!.objectForKey("result")
                    if result == nil { return }
                    
                    // if result == nil || result! is NSDictionary) == false { return }
                    // Use the line above to avoid the line below.
                    if result! is NSDictionary {
                        let resultDict = result as NSDictionary
                        let serverSweetSpots = resultDict["sweetspots"] as NSArray
                        if serverSweetSpots.count > 0 {
                            println("the serverSweetSpots has \(serverSweetSpots.count) elements")
                            println("the song id is \(songID )")
                            
                            if let songSS = self.delegate?.sweetSpotsForSongID(songID) {
                                let mutableSS = NSMutableArray(array: songSS)
                            
                                for ss in serverSweetSpots {
                                    mutableSS.addObject(ss)
                                }
                            
                                self.delegate?.replaceSweetSpots(mutableSS as NSArray, forSongID: songID)
                                // The index really doesn't matter. The sweet spots are in a set which isn't sorted.
                                self.delegate?.setActiveSweetSpotIndex(0, forSongID: songID)
                            }
                        }
                    }
                }
            }
        })
        
        return nil;
    }
}
