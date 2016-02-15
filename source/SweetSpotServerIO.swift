//
//  SweetSpotServerIO.swift
//  reDiscover
//
//  Created by Teo on 15/09/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

protocol SweetSpotServerIODelegate {

	func addSong(withChanges changes: [SongProperty : AnyObject], forSongId songId: SongId)
	func sweetSpotHasBeenUploaded(theSS: Double, song : TGSong) -> Bool
	func markSweetSpotAsUploaded(uuid : String, sweetSpot : SweetSpot)
}
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

	static var delegate : SweetSpotServerIODelegate?

    // Should this be lazy?
    private static var hostName = "192.168.5.9" /// currently the server addr.
    private static var hostPort = "6969"
    
    // The location of the SweetSpotServer. For now it's just localhost.
    private static let hostNameAndPort = hostName+":"+hostPort //"localhost:6969"
	
    static var songPoolAPI : SongPoolAccessProtocol?


//    static func uploadSweetSpotsForSongID(songId : SongId) -> Bool {
    static func uploadSweetSpots(song: TGSong) -> Bool {	
		precondition(delegate != nil)
		
        // First get the song's uuid
        guard let songUuid = song.UUId else {
            print("uploadSweetSpotsForSongID ERROR: song has no UUID")
            return false
        }
        
        /// songForSongId is static so we need to access it through the type. (change to use delegate)
        guard let sweetSpots = SweetSpotController.sweetSpots(forSong: song) as Set<SweetSpot>? else {
			return false
		}
		
		for sweetSpot in sweetSpots {
		
			if delegate!.sweetSpotHasBeenUploaded(sweetSpot as Double, song: song) {
				print("Has been uploaded")
				continue
			}

			guard let requestIDURL = NSURL(string: "http://\(hostNameAndPort)/submit?songUUID=\(songUuid.utf8)&songSweetSpot=\(sweetSpot as Double)") else { return false }
			
			print("this is a sweetSpot upload url \(requestIDURL)")
			
			guard let requestData = NSData(contentsOfURL: requestIDURL) else {
				print("ERROR: No data returned from SweetSpotServer.")
				return false
			}
		
			do {
				let requestJSON = try NSJSONSerialization.JSONObjectWithData(
											requestData,
											options: NSJSONReadingOptions.MutableContainers ) as! NSDictionary
				
				if let status = requestJSON.objectForKey("status") as! String? {
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
    static func requestSweetSpotsForSongID(songID: SongId) -> NSArray? {
        let envVars = NSProcessInfo.processInfo().environment
        if let _ = envVars["NO_SSSERVER"] {
            self.mock(songID)
            return nil
        }
        
        guard let song = songPoolAPI?.songForSongId(songID),
            let songUUID = song.UUId else { return nil }
        guard let theURL = NSURL(string: "http://\(hostNameAndPort)/lookup?songUUID=\(songUUID.utf8)") else { return nil }

        let request = NSURLRequest(URL: theURL)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            guard let song = songPoolAPI?.songForSongId(songID) else { return }
            if data != nil {
                do {
                    let requestJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    
                    if let status = requestJSON.objectForKey("status") as! String? {
                        if (status == "ok") == nil { return }
                            
                        guard let result: AnyObject? = requestJSON.objectForKey("result") else { return }
                        
                        // Use the line above to avoid the line below.
                        if result! is NSDictionary {
							
                            let resultDict		 = result as! NSDictionary
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
                                
                                songPoolAPI?.addSong(withChanges: [.SweetSpots : newSSSet!, .SelectedSS : newSelectedSS!], forSongId: songID)
                                
                                // Let any listeners know we've updated the sweetspots of songID
                                NSNotificationCenter.defaultCenter().postNotificationName("SweetSpotsUpdated", object: songID)
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
    
    /** Mock fetch sweetspots and selected sweet spot when there is not network connection.
    */
    static func mock(songId: SongId) {
        let newSSs : Set<SweetSpot> = [30, 60, 120, 240]
        let selectedSS : SweetSpot = 60
        
        songPoolAPI?.addSong(withChanges: [.SweetSpots : newSSs, .SelectedSS : selectedSS], forSongId: songId)
        
        // Let any listeners know we've updated the sweetspots of songID
        NSNotificationCenter.defaultCenter().postNotificationName("SweetSpotsUpdated", object: songId)

    }
}
