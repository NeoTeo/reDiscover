//
//  SweetSpotServerIO.swift
//  reDiscover
//
//  Created by Teo on 15/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

protocol SweetSpotServerIODelegate {

	func getSong(_ songId : SongId) -> TGSong?
	func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
	
	func sweetSpots(forSong song: TGSong) -> Set<SweetSpot>?
	func sweetSpotHasBeenUploaded(_ theSS: Double, song : TGSong) -> Bool
	func markSweetSpotAsUploaded(_ uuid : String, sweetSpot : SweetSpot)
}

/**
    The SweetSpotServerIO class handles communication with the sweet spot web server.

    To avoid re-sending sweetspots it maintains a locally persisted store, accessed
	via its delegate, of all the songs whose sweet spots have already been uploaded 
	to the server.
*/
class SweetSpotServerIO: NSObject {

	var delegate : SweetSpotServerIODelegate?
	
	private var hostName : String!
	private var hostPort : String!
	private let hostNameAndPort : String!

	override init() {
		
		hostName = "127.0.0.1"
		hostPort = "6969"

		/// During dev we get the host ip from the environment variables
		let envVars = ProcessInfo.processInfo.environment
		if let serverIp = envVars["SERVER_IP"] {
			hostName = serverIp
		}
		
		hostNameAndPort = hostName+":"+hostPort
	}


    func uploadSweetSpots(_ song: TGSong) -> Bool {
		
		precondition(delegate != nil)
		
        // First get the song's uuid
        guard let songUuid = song.UUId else {
            print("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return false
        }
		
//        guard let sweetSpots = SweetSpotController.sweetSpots(forSong: song) as Set<SweetSpot>? else {
        guard let sweetSpots = delegate?.sweetSpots(forSong: song) as Set<SweetSpot>? else {
			return false
		}
		
		for sweetSpot in sweetSpots {
		
			if delegate!.sweetSpotHasBeenUploaded(sweetSpot as Double, song: song) {
				print("Has been uploaded")
				continue
			}

			guard let requestIDURL = URL(string: "http://\(hostNameAndPort)/submit?songUUID=\(songUuid.utf8)&songSweetSpot=\(sweetSpot as Double)") else { return false }
			
			print("this is a sweetSpot upload url \(requestIDURL)")
			
			guard let requestData = try? Data(contentsOf: requestIDURL) else {
				print("ERROR: No data returned from SweetSpotServer.")
				return false
			}
		
			do {
				let requestJSON = try JSONSerialization.jsonObject(
											with: requestData,
											options: JSONSerialization.ReadingOptions.mutableContainers ) as! NSDictionary
				
				if let status = requestJSON.object(forKey: "status") as! String? {
					if (status == "ok") != nil {
						print("Upload to SweetSpotServer returned OK")
						
						delegate?.markSweetSpotAsUploaded(songUuid, sweetSpot: sweetSpot)
					}
				}
			} catch {
				print("oh arses")
				return false
			}
			
		}
        return true;
    }
	
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
    So, consequently, the returned array will always be nil.
    */
    func requestSweetSpotsForSongID(_ songID: SongId) -> NSArray? {
		
		let envVars = ProcessInfo.processInfo.environment
        if let _ = envVars["NO_SSSERVER"] {
            self.mock(songID)
            return nil
        }
		
        guard let song = delegate?.getSong(songID),let songUUID = song.UUId else {
			return nil
		}
		
        guard let theURL = URL(string: "http://\(hostNameAndPort)/lookup?songUUID=\(songUUID.utf8)") else {
			return nil
		}

        let request = URLRequest(url: theURL)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			
            guard let song = self.delegate?.getSong(songID) else { return }
			
            guard data != nil else { return }
			do {
				let requestJSON = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers ) as! NSDictionary
				
				if let status = requestJSON.object(forKey: "status") as! String? {
                    
					guard status == "ok" else { return }
						
					guard let result = requestJSON.object(forKey: "result") else { return }
					
					// Use the line above to avoid the line below.
					if result is NSDictionary {
						
						let resultDict		 = result as! NSDictionary
						let serverSweetSpots = resultDict["sweetspots"] as! [SweetSpot]//NSArray
						
						if serverSweetSpots.count > 0 {
							
							print("the serverSweetSpots has \(serverSweetSpots.count) elements")
							print("the song id is \(songID )")
							
							// If the song already has sweet spots add the server's sweet spots to them.
							
							var newSSSet: Set<SweetSpot>
							
                            if var songSS = self.delegate?.sweetSpots(forSong: song) {
								
								for ss in serverSweetSpots {
									songSS.insert(ss)
								}
								
								newSSSet = songSS
                                
							} else {
								
								newSSSet = Set<SweetSpot>(serverSweetSpots)
							}
							
							/// If a sweet spot is already selected, use it
							/// otherwise pick the first from the new set.
							var newSelectedSS = song.selectedSweetSpot
							
							if newSelectedSS == nil {
								newSelectedSS = newSSSet.first
							}
							
							self.delegate?.addSong(withChanges: [.sweetSpots : newSSSet as AnyObject, .selectedSS : newSelectedSS!], forSongId: songID)
							// Let any listeners know we've updated the sweetspots of songID
							NotificationCenter.default.post(name: Notification.Name(rawValue: "SweetSpotsUpdated"), object: songID)
						}
					}
				}
			} catch {
				print("JSONSerialization failed \(error)")
				return
			}
        }

        task.resume()
        return nil;
    }
    
    /** Mock fetch sweetspots and selected sweet spot when there is not network connection.
    */
    func mock(_ songId: SongId) {
        let newSSs : Set<SweetSpot> = [30, 60, 120, 240]
        let selectedSS : SweetSpot = 60
        
//        songPoolAPI?.addSong(withChanges: [.SweetSpots : newSSs, .SelectedSS : selectedSS], forSongId: songId)
        delegate?.addSong(withChanges: [.sweetSpots : newSSs as AnyObject, .selectedSS : selectedSS], forSongId: songId)
		
        // Let any listeners know we've updated the sweetspots of songID
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SweetSpotsUpdated"), object: songId)

    }
}
