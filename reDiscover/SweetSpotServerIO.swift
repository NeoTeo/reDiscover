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

    let opQueue: NSOperationQueue?
    // The delegate to communicate with song pool
    var delegate: SongPoolAccessProtocol?
    // Should this be lazy?
    
    // The location of the SweetSpotServer. For now it's just localhost.
    let hostNameAndPort = "localhost:6969"
    
    var uploadedSweetSpots: Dictionary<String,UploadedSSData> = [String:UploadedSSData]()
    var uploadedSweetSpotsMOC: NSManagedObjectContext?
    
    override init() {
        // Start an asynchronous operation queue
        opQueue = NSOperationQueue()

        super.init()
        
        
        setupUploadedSweetSpotsMOC()
        initUploadedSweetSpots()
    }
    
    /**
    Set up the Core Data persistent store for sweet spots that have already been uploaded to the server.
    */
    func setupUploadedSweetSpotsMOC() {
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
    
    
    func initUploadedSweetSpots() {
        var error: NSError?
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
                if error != nil {
                    print(error?.localizedDescription ?? "Unknown error.")
                    return
                }
                
                for ssData in fetchedArray as! [UploadedSSData] {
                    //let ssData = ss as! UploadedSSData
                    self.uploadedSweetSpots[ssData.songUUID] = ssData
                    print("The ssData songUUID is \(ssData.songUUID) and its sweetspots \(ssData.sweetSpots)")
                }
                
                print("initUploadedSweetSpots done. Loaded \(self.uploadedSweetSpots.count)")
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
        }
  
    }
    
    
    func storeUploadedSweetSpotsDictionary() {
        if uploadedSweetSpotsMOC == nil {
            print("ERROR: uploaded sweet spots managed object context is nil.")
            return
        }
        
        if uploadedSweetSpotsMOC!.hasChanges {
            uploadedSweetSpotsMOC!.performBlockAndWait() {
                var error: NSError?
                //assert(self.uploadedSweetSpotsMOC!.save(), "Error saving uploaded sweet spots MOC. \(error)")
            }
        }
    }
    
    
    func sweetSpotHasBeenUploaded(theSS: Double, theSongID: SongIDProtocol) -> Bool {
        if  let songUUID = delegate?.UUIDStringForSongID(theSongID),
            let ssData = uploadedSweetSpots[songUUID] as UploadedSSData?,
            let sweetSpots = ssData.sweetSpots as NSArray? {
                
            return sweetSpots.containsObject(theSS)
        }
        return false
    }
    
    //MARK: Below here belongs in the sweetspotserver class
    func uploadSweetSpotsForSongID(songID: SongIDProtocol) -> Bool {
        // First get the song's uuid
        let songUUID = delegate?.UUIDStringForSongID(songID)
        if songUUID == nil {
            print("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return false
        }
        if let sweetSpots = delegate?.sweetSpotsForSongID(songID) as NSArray? {
            for sweetSpot in sweetSpots {
                if sweetSpotHasBeenUploaded(sweetSpot as! Double, theSongID: songID) {
                    print("Has been uploaded")
                    continue
                }

                let requestIDURL = NSURL(string: "http://\(hostNameAndPort)/submit?songUUID=\(songUUID!.utf8)&songSweetSpot=\(sweetSpot as! Double)")
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
                            
                            var uploadedSS = uploadedSweetSpots[songUUID!]
                            if uploadedSS == nil {
                                // The song has no existing sweetspots so we create a new set with the sweet spot.
                                uploadedSS = UploadedSSData.insertItemWithSongUUIDString(songUUID!, inManagedObjectContext: uploadedSweetSpotsMOC) as UploadedSSData
                                uploadedSS?.sweetSpots = NSArray(object: sweetSpot) as [AnyObject]
                            } else {
                                // The song already has a set of sweetspots so we need to add to it.
    //                            var existingSS = uploadedSS!.sweetSpots.mutableCopy() as NSMutableArray
                                var existingSS = NSMutableArray(array: uploadedSS!.sweetSpots)
                                existingSS.addObject(sweetSpot)
                                uploadedSS!.sweetSpots = existingSS.copy() as! NSArray as [AnyObject]
                            }
                            
                            // Add the new data to the dictionary
                            uploadedSweetSpots[songUUID!] = uploadedSS!
                            
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
    
    func requestSweetSpotsForSongID(songID: SongIDProtocol) -> NSArray? {
        let songUUID = delegate?.UUIDStringForSongID(songID)
        if songUUID == nil {
            print("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return nil
        }
        
        let theURL = NSURL(string: "http://\(hostNameAndPort)/lookup?songUUID=\(songUUID!.utf8)")
        if theURL == nil { return nil }
        
        let theRequest = NSURLRequest(URL: theURL!)
        NSURLConnection.sendAsynchronousRequest(theRequest, queue: opQueue!, completionHandler: {
                (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            if data != nil {
                do {
                    let requestJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    
                    if let status = requestJSON.objectForKey("status") as! String? {
                        if (status == "ok") == nil { return }
                            
                        let result: AnyObject? = requestJSON.objectForKey("result")
                        if result == nil { return }
                        
                        // if result == nil || result! is NSDictionary) == false { return }
                        // Use the line above to avoid the line below.
                        if result! is NSDictionary {
                            let resultDict = result as! NSDictionary
                            let serverSweetSpots = resultDict["sweetspots"] as! NSArray
                            if serverSweetSpots.count > 0 {
                                print("the serverSweetSpots has \(serverSweetSpots.count) elements")
                                print("the song id is \(songID )")
                                
                                // If the song already has sweet spots add the server's sweet spots to them.
                                if let songSS = self.delegate?.sweetSpotsForSongID(songID) {
                                    let mutableSS = NSMutableArray(array: songSS)
                                
                                    for ss in serverSweetSpots {
                                        mutableSS.addObject(ss)
                                    }
                                
                                    self.delegate?.replaceSweetSpots(mutableSS as NSArray as! [AnyObject], forSongID: songID)
                                    
                                } else {
                                    self.delegate?.replaceSweetSpots(serverSweetSpots as! [AnyObject], forSongID: songID)
                                }
                                
                                // Set the first sweet spot to be the active one.
    //                            self.delegate?.setActiveSweetSpotIndex(0, forSongID: songID)
                            }
                        }
                    }
                } catch {
                    print("JSONSerialization failed \(error)")
                    return
                }
            }
        })
        
        return nil;
    }
}
