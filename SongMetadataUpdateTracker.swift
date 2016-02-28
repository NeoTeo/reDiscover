//
//  SongMetadataUpdateTracker.swift
//  reDiscover
//
//  Created by teo on 28/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongMetadataUpdateTracker {
	mutating func markUpdate(songId : SongId)
	func lastUpdate(songId : SongId) -> NSDate?
	func secondsSinceUpdate(songId : SongId) -> NSTimeInterval
	
	var minUpdateInterval : NSTimeInterval { get }
}

struct TGSongMetadataUpdateTracker : SongMetadataUpdateTracker {

	/// The update interval is an hour.
	let minUpdateInterval : NSTimeInterval = 3600

	private var updates = [SongId : NSDate]()
	private var updatesAccessQ: dispatch_queue_t = dispatch_queue_create("updatesQ", DISPATCH_QUEUE_SERIAL)
	
	private func synchronized(f: Void -> Void) {
		//guard updatesAccessQ != nil else { fatalError("No updatesAccessQ") }
		dispatch_sync(updatesAccessQ, f)
	}

	/// access queue to make this thread safe.
	mutating func markUpdate(songId : SongId) {
		synchronized {
			self.updates[songId] = NSDate()
		}
	}
	
	func lastUpdate(songId : SongId) -> NSDate? {
		return updates[songId]
	}
	
	func secondsSinceUpdate(songId : SongId) -> NSTimeInterval {
		guard let lastUpdate = updates[songId] else { return minUpdateInterval }
		let diff = NSDate().timeIntervalSinceDate(lastUpdate)
		return diff
	}
	
}