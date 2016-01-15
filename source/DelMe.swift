//
//  DelMe.swift
//  reDiscover
//
//  Created by Teo on 15/01/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Foundation

//
//  FingerPrinter.swift
//  reDiscover
//
//  Created by Teo on 13/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

@objc protocol OldFingerPrinter {
    func fingerprint(forSongId songId: SongIDProtocol) -> String?
}