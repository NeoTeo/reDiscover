//
//  SweetSpotLocalStore.swift
//  reDiscover
//
//  Created by teo on 13/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa


protocol SweetSpotLocalStore {
	func storeUploadedSweetSpotsDictionary()
	func markSweetSpotAsUploaded(_ uuid : String, sweetSpot : SweetSpot)
	func sweetSpotHasBeenUploaded(_ theSS: Double, song : TGSong) -> Bool
}

/**
	The TGSweetSpotLocalStore handles the local storage of the sweet spots that 
	have already been uploaded to the sweet spot server.

	The uploadedSweetSpots is a dictionary of song ids and the sweet spots of that
	song that have been succesfully uploaded to the server. It is written out whenever
	the application quits (currently saving is manual) and loaded back in on application
	start, before the application attempts to import whatever song urls the user
	has passed in.

	When the song pool loads a song url and sweet spots are found, it is checked,
	using the song's uuid, against the uploadedSweetSpots and any sweet spots not
	in there will be uploaded to the server.
*/
class TGSweetSpotLocalStore : SweetSpotLocalStore {
	
	private var uploadedSweetSpots: Dictionary<String,UploadedSSData> = [String:UploadedSSData]()
	private var uploadedSweetSpotsMOC: NSManagedObjectContext?

	
	init() {
		
		setupUploadedSweetSpotsMOC()
		initUploadedSweetSpots()
	}

	/** 
		Set up the Core Data persistent store for sweet spots that have already 
		been uploaded to the server.
	*/
	private func setupUploadedSweetSpotsMOC() {
		
		guard let modelURL = Bundle.main().urlForResource("uploadedSS", withExtension: "momd"),
			let mom = NSManagedObjectModel(contentsOf: modelURL) else {
				return
		}
		
		uploadedSweetSpotsMOC = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		uploadedSweetSpotsMOC?.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
		
		do {
			// Build the URL where to store the data.
			let documentsDirectory = try! FileManager.default().urlForDirectory(.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("uploadedSS.xml")
			
			
			try uploadedSweetSpotsMOC?.persistentStoreCoordinator?.addPersistentStore(ofType: NSXMLStoreType,configurationName: nil,at: documentsDirectory, options: nil)
		} catch {
			print("SweetSpotServerIO init error: \(error)")
		}
	}


	private func initUploadedSweetSpots() {
		
        precondition(uploadedSweetSpotsMOC != nil)
        //let fetchRequest = NSFetchRequest(entityName: "UploadedSSData")
        let request:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "UploadedSSData")

		uploadedSweetSpotsMOC!.performAndWait() {
			do {
                let fetchedArray = try self.uploadedSweetSpotsMOC!.fetch(request)
				
				for ssData in fetchedArray as! [UploadedSSData] where ssData.songUUID != nil {
					
					self.uploadedSweetSpots[ssData.songUUID!] = ssData
					print("The ssData songUUID is \(ssData.songUUID) and its sweetspots \(ssData.sweetSpots)")
				}
				
				print("initUploadedSweetSpots done. Loaded \(self.uploadedSweetSpots.count)")
			} catch {
				fatalError("Failed to upload SweetSpots \(error)")
			}
		}
	}


	func markSweetSpotAsUploaded(_ uuid : String, sweetSpot : SweetSpot) {
	
		var uploadedSS = uploadedSweetSpots[uuid]
		
		if uploadedSS == nil {
			// The song has no existing sweetspots so we create a new set with the sweet spot.
			uploadedSS = UploadedSSData.insert(uuid, inContext: uploadedSweetSpotsMOC!) as? UploadedSSData
			uploadedSS?.sweetSpots = NSArray(object: sweetSpot) as [AnyObject]
		} else {

			// The song already has a set of sweetspots so we need to add to it.
			let existingSS = NSMutableArray(array: uploadedSS!.sweetSpots!)
			existingSS.add(sweetSpot)
			uploadedSS!.sweetSpots = existingSS.copy() as! NSArray as [AnyObject]
		}

		// Add the new data to the dictionary
		uploadedSweetSpots[uuid] = uploadedSS!
	}
	
	func storeUploadedSweetSpotsDictionary() {
		
		precondition(uploadedSweetSpotsMOC != nil)
		
		if uploadedSweetSpotsMOC!.hasChanges {
			uploadedSweetSpotsMOC!.performAndWait() {
				do {
					try self.uploadedSweetSpotsMOC!.save()
				} catch {
					fatalError("Error saving uploaded sweet spots MOC. \(error)")
				}
			}
		}
	}

//	static func sweetSpotHasBeenUploaded(theSS: Double, theSongID: SongId) -> Bool {

}

//extension TGSweetSpotLocalStore {
//	
//	static func getUploadedSweetSpots(songUuid : String) -> [String : UploadedSSData] {
//		return uploadedSweetSpots
//	}
//	
//	static func setUploadedSweetSpots(songUuid : String, sweetSpot : UploadedSSData) {
//		
//	}
//}

extension TGSweetSpotLocalStore : SweetSpotControllerLocalStoreDelegate {
	
	func sweetSpotHasBeenUploaded(_ theSS: Double, song : TGSong) -> Bool {
		if	let songUUID = song.UUId,
			let ssData = uploadedSweetSpots[songUUID] as UploadedSSData?,
			let sweetSpots = ssData.sweetSpots as NSArray? {
				
				return sweetSpots.contains(theSS)
		}
		return false
	}
}
