//
//  FingerPrinter.swift
//  reDiscover
//
//  Created by Teo on 13/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

@objc protocol FingerPrinter {
    func fingerprint(forSongId songId: SongIDProtocol) -> String?
}