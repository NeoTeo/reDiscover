//
//  SongMetadataUpdateTracker.swift
//  reDiscover
//
//  Created by teo on 28/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

protocol SongMetadataUpdateTracker {
	mutating func markUpdate(_ songId : SongId)
	func lastUpdate(_ songId : SongId) -> Date?
	func secondsSinceUpdate(_ songId : SongId) -> TimeInterval
	
	var minUpdateInterval : TimeInterval { get }
}

struct TGSongMetadataUpdateTracker : SongMetadataUpdateTracker {

	/// The update interval is an hour.
	let minUpdateInterval : TimeInterval = 3600

	private var updates = [SongId : Date]()
	private var updatesAccessQ: DispatchQueue = DispatchQueue(label: "updatesQ", attributes: DispatchQueueAttributes.serial)
	
	private func synchronized( _ f: @noescape (Void) -> Void) {
		//guard updatesAccessQ != nil else { fatalError("No updatesAccessQ") }
		updatesAccessQ.sync(execute: f)
	}

	/// access queue to make this thread safe.
	mutating func markUpdate(_ songId : SongId) {
		synchronized {
            self.updates[songId] = Date()
		}
	}
	
	func lastUpdate(_ songId : SongId) -> Date? {
		return updates[songId]
	}
	
	func secondsSinceUpdate(_ songId : SongId) -> TimeInterval {
		guard let lastUpdate = updates[songId] else { return minUpdateInterval }
		let diff = Date().timeIntervalSince(lastUpdate)
		return diff
	}
	
}
