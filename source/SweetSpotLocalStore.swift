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
	func markSweetSpotAsUploaded(uuid : String, sweetSpot : SweetSpot)
	func sweetSpotHasBeenUploaded(theSS: Double, song : TGSong) -> Bool
}


class TGSweetSpotLocalStore : SweetSpotLocalStore {
	
	private var uploadedSweetSpots: Dictionary<String,UploadedSSData> = [String:UploadedSSData]()
	private var uploadedSweetSpotsMOC: NSManagedObjectContext?

	
	init() {
		
		setupUploadedSweetSpotsMOC()
		initUploadedSweetSpots()
	}

	/** Set up the Core Data persistent store for sweet spots that have already been uploaded to the server.
	*/
	private func setupUploadedSweetSpotsMOC() {
		
		if  let modelURL = NSBundle.mainBundle().URLForResource("uploadedSS", withExtension: "momd"),
			let mom = NSManagedObjectModel(contentsOfURL: modelURL) {
				
				uploadedSweetSpotsMOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
				uploadedSweetSpotsMOC?.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
				
				do {
					// Build the URL where to store the data.
					let documentsDirectory = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true).URLByAppendingPathComponent("uploadedSS.xml")
					
					
					try uploadedSweetSpotsMOC?.persistentStoreCoordinator?.addPersistentStoreWithType(NSXMLStoreType,configuration: nil,URL: documentsDirectory, options: nil)
				} catch {
					print("SweetSpotServerIO init error: \(error)")
				}
		}
	}


	private func initUploadedSweetSpots() {
		
		let fetchRequest = NSFetchRequest(entityName: "UploadedSSData")
		uploadedSweetSpotsMOC?.performBlockAndWait() {
			do {
				let fetchedArray = try self.uploadedSweetSpotsMOC?.executeFetchRequest(fetchRequest)
				
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


	func markSweetSpotAsUploaded(uuid : String, sweetSpot : SweetSpot) {
	
		var uploadedSS = uploadedSweetSpots[uuid]
		
		if uploadedSS == nil {
			// The song has no existing sweetspots so we create a new set with the sweet spot.
			uploadedSS = UploadedSSData.insert(uuid, inContext: uploadedSweetSpotsMOC!) as? UploadedSSData
			uploadedSS?.sweetSpots = NSArray(object: sweetSpot) as [AnyObject]
		} else {

			// The song already has a set of sweetspots so we need to add to it.
			let existingSS = NSMutableArray(array: uploadedSS!.sweetSpots!)
			existingSS.addObject(sweetSpot)
			uploadedSS!.sweetSpots = existingSS.copy() as! NSArray as [AnyObject]
		}

		// Add the new data to the dictionary
		uploadedSweetSpots[uuid] = uploadedSS!
	}
	
	func storeUploadedSweetSpotsDictionary() {
		
		precondition(uploadedSweetSpotsMOC != nil)
		
		if uploadedSweetSpotsMOC!.hasChanges {
			uploadedSweetSpotsMOC!.performBlockAndWait() {
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
	
	func sweetSpotHasBeenUploaded(theSS: Double, song : TGSong) -> Bool {
		if	let songUUID = song.UUId,
			let ssData = uploadedSweetSpots[songUUID] as UploadedSSData?,
			let sweetSpots = ssData.sweetSpots as NSArray? {
				
				return sweetSpots.containsObject(theSS)
		}
		return false
	}
}