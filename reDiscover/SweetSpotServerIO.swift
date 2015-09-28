//
//  SweetSpotServerIO.swift
//  reDiscover
//
//  Created by Teo on 15/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa
    //MARK: Move the core data functions to a separate class.
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

//    let opQueue: NSOperationQueue?
    // The delegate to communicate with song pool
    // Should this be lazy?
    
    // The location of the SweetSpotServer. For now it's just localhost.
    private static let hostNameAndPort = "localhost:6969"
    
    private static var uploadedSweetSpots: Dictionary<String,UploadedSSData> = [String:UploadedSSData]()
    private static var uploadedSweetSpotsMOC: NSManagedObjectContext?
    
//    override init() {
//
//        super.init()
//        
//        
//        setupUploadedSweetSpotsMOC()
//        initUploadedSweetSpots()
//    }
    
    /**
    REFACTOR - This needs to work for a static class
    
    Set up the Core Data persistent store for sweet spots that have already been uploaded to the server.
    */
    static func setupUploadedSweetSpotsMOC() {
        var error: NSError?
        
        if  let modelURL = NSBundle.mainBundle().URLForResource("uploadedSS", withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOfURL: modelURL) {

            uploadedSweetSpotsMOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            uploadedSweetSpotsMOC?.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
            
            do {
                // Build the URL where to store the data.
                let documentsDirectory = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("uploadedSS.xml")


                try uploadedSweetSpotsMOC?.persistentStoreCoordinator?.addPersistentStoreWithType(NSXMLStoreType,configuration: nil,URL: documentsDirectory, options: nil)
            } catch let error1 as NSError {
                error = error1
            }
            if error != nil {
                print("SweetSpotServerIO init error: \(error)")
            }
        }
    }
    
    
    static func initUploadedSweetSpots() {

        let fetchRequest = NSFetchRequest(entityName: "UploadedSSData")
//MARK: Enable this when the wipwip work is done
        /*
        let async = NSAsynchronousFetchRequest(fetchRequest: fetchRequest){
            (result:NSAsynchronousFetchResult!) -> Void in

            if let fetchedArray = result.finalResult {
                for ss in fetchedArray {
                    let ssData = ss as UploadedSSData
                    self.uploadedSweetSpots[ssData.songUUID] = ssData
                    println("The ssData songUUID is \(ssData.songUUID) and its sweetspots \(ssData.sweetSpots)")
                }
                println("initUploadedSweetSpots done. Loaded \(self.uploadedSweetSpots.count)")
            }
        }
        uploadedSweetSpotsMOC?.performBlock {
            let results = self.uploadedSweetSpotsMOC?.executeRequest(async, error: &error) as NSAsynchronousFetchResult
            if error != nil {
                println(error?.localizedDescription ?? "Unknown error.")
                return
            }
        }
*/
  
        uploadedSweetSpotsMOC?.performBlockAndWait(){
            do {
                let fetchedArray = try self.uploadedSweetSpotsMOC?.executeFetchRequest(fetchRequest)
                
                for ssData in fetchedArray as! [UploadedSSData] {
                    //let ssData = ss as! UploadedSSData
                    self.uploadedSweetSpots[ssData.songUUID] = ssData
                    print("The ssData songUUID is \(ssData.songUUID) and its sweetspots \(ssData.sweetSpots)")
                }
                
                print("initUploadedSweetSpots done. Loaded \(self.uploadedSweetSpots.count)")
            } catch {
                fatalError("Failed to upload SweetSpots \(error)")
            }
        }
  
    }
    
    static func initMOC() {
        setupUploadedSweetSpotsMOC()
        initUploadedSweetSpots()
    }
    
    static func storeUploadedSweetSpotsDictionary() {
        if uploadedSweetSpotsMOC == nil {
            initMOC()
            assert(uploadedSweetSpotsMOC != nil, "Error: no sweetspot MOC")
        }
        
        if uploadedSweetSpotsMOC!.hasChanges {
            uploadedSweetSpotsMOC!.performBlockAndWait() {
//                var error: NSError?
                //assert(self.uploadedSweetSpotsMOC!.save(), "Error saving uploaded sweet spots MOC. \(error)")
                do {
                    try self.uploadedSweetSpotsMOC!.save()
                } catch {
                    fatalError("Error saving uploaded sweet spots MOC. \(error)")
                }
            }
        }
    }
    
    
    static func sweetSpotHasBeenUploaded(theSS: Double, theSongID: SongIDProtocol) -> Bool {
//        if  let songUUID = delegate?.UUIDStringForSongID(theSongID),
        if let songUUID = SongUUID.getUUIDForSongId(theSongID),
            let ssData = uploadedSweetSpots[songUUID] as UploadedSSData?,
            let sweetSpots = ssData.sweetSpots as NSArray? {
                
            return sweetSpots.containsObject(theSS)
        }
        return false
    }
    
    //MARK: Below here belongs in the sweetspotserver class
    static func uploadSweetSpotsForSongID(songID: SongIDProtocol) -> Bool {
        // First get the song's uuid
//        let songUUID = delegate?.UUIDStringForSongID(songID)
        guard let songUUID = SongUUID.getUUIDForSongId(songID) else {
            print("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return false
        }
        
        if let song = SongPool.songForSongId(songID),
            sweetSpots = SweetSpotController.sweetSpots(forSong: song) as Set<SweetSpot>? {
            for sweetSpot in sweetSpots {
                if sweetSpotHasBeenUploaded(sweetSpot as Double, theSongID: songID) {
                    print("Has been uploaded")
                    continue
                }

                let requestIDURL = NSURL(string: "http://\(hostNameAndPort)/submit?songUUID=\(songUUID.utf8)&songSweetSpot=\(sweetSpot as Double)")
                if requestIDURL == nil { return false }
                
                print("this is a sweetSpot upload url \(requestIDURL!)")
                
                let requestData = NSData(contentsOfURL: requestIDURL!)
                if requestData == nil {
                    print("ERROR: No data returned from SweetSpotServer.")
                    return false
                }
                do {
                    let requestJSON = try NSJSONSerialization.JSONObjectWithData(requestData!, options: NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    
                    if let status = requestJSON.objectForKey("status") as! String? {
                        if (status == "ok") != nil {
                            print("Upload to SweetSpotServer returned OK")
                            
                            var uploadedSS = uploadedSweetSpots[songUUID]
                            if uploadedSS == nil {
                                // The song has no existing sweetspots so we create a new set with the sweet spot.
                                uploadedSS = UploadedSSData.insertItemWithSongUUIDString(songUUID, inManagedObjectContext: uploadedSweetSpotsMOC) as UploadedSSData
                                uploadedSS?.sweetSpots = NSArray(object: sweetSpot) as [AnyObject]
                            } else {
                                // The song already has a set of sweetspots so we need to add to it.
    //                            var existingSS = uploadedSS!.sweetSpots.mutableCopy() as NSMutableArray
                                let existingSS = NSMutableArray(array: uploadedSS!.sweetSpots)
                                existingSS.addObject(sweetSpot)
                                uploadedSS!.sweetSpots = existingSS.copy() as! NSArray as [AnyObject]
                            }
                            
                            // Add the new data to the dictionary
                            uploadedSweetSpots[songUUID] = uploadedSS!
                            
                        }
                    }
                } catch {
                    print("oh arses")
                    return false
                }
                
            }
        }
        return true;
    }
    
//    func uploadSweetSpotForSongID(sweetSpot: NSNumber, songID: SongIDProtocol) -> Bool {
//        return true;
//    }
    
    /** 
    The async nature of this method (has to IO with an external server) means it 
    never actually returns the sweet spots but relies on a adding the song with 
    the new sweet spots to the song pool which is gross.
    */
    /** FIXME: REFACTOR
    Turn this sucker into a sync method that does what it says on the tin or at
    least a method that takes a continuation (completion closure)
    The problem is that I don't have a good concept of how to deal with song changes
    in indeterminate order which they will be when they depend on external IO.
    Eg.
    1) I fire off an async request A for reading meta data for a song.
    2) I fire off an async request B for reading sweet spots of a song.
    3) B returns with some sweet spots so I make a new song with the sweet spots
    4) A returns with meta data so I make a new song with the meta data but because
        I'm using the old song captured at the creation of the closure it will not
        have the sweet spots that were added in step 3.
    
    Solution: Don't use songs but song ids and look up the song at the time the
    closure is called - eg 4) make a new song with the song we get from the id which
    will contain the sweet spots added in step 3 and the new meta data.
    */
    static func requestSweetSpotsForSongID(songID: SongIDProtocol) -> NSArray? {

        guard let songUUID = SongUUID.getUUIDForSongId(songID) else { return nil }
        guard let theURL = NSURL(string: "http://\(hostNameAndPort)/lookup?songUUID=\(songUUID.utf8)") else { return nil }

        let request = NSURLRequest(URL: theURL)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            guard let song = SongPool.songForSongId(songID) else { return }
            if data != nil {
                do {
                    let requestJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    
                    if let status = requestJSON.objectForKey("status") as! String? {
                        if (status == "ok") == nil { return }
                            
                        guard let result: AnyObject? = requestJSON.objectForKey("result") else { return }
                        
                        // Use the line above to avoid the line below.
                        if result! is NSDictionary {
                            let resultDict = result as! NSDictionary
                            let serverSweetSpots = resultDict["sweetspots"] as! [SweetSpot]//NSArray
                            if serverSweetSpots.count > 0 {
                                print("the serverSweetSpots has \(serverSweetSpots.count) elements")
                                print("the song id is \(songID )")
                                
                                // If the song already has sweet spots add the server's sweet spots to them.
                                var songSS: Set<SweetSpot>? = SweetSpotController.sweetSpots(forSong: song)
                                var newSSSet: Set<SweetSpot>?
                                if songSS != nil {
                                    for ss in serverSweetSpots {
                                        songSS!.insert(ss)
                                    }
                                    newSSSet = songSS
                                } else {
                                    newSSSet = Set<SweetSpot>(serverSweetSpots)
                                }
                                
                                /// If a sweet spot is already selected, use it
                                /// otherwise pick the first from the new set.
                                var newSelectedSS = song.selectedSweetSpot
                                if newSelectedSS == nil {
                                    newSelectedSS = newSSSet!.first
                                }
                                
                                SongPool.addSong(withChanges: [.SweetSpots : newSSSet!, .SelectedSS : newSelectedSS!], forSongId: songID)
                            }
                        }
                    }
                } catch {
                    print("JSONSerialization failed \(error)")
                    return
                }
            }
        }

        task.resume()
        return nil;
    }
}
