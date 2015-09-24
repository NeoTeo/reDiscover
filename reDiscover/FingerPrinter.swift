//
//  FingerPrinter.swift
//  reDiscover
//
//  Created by Teo on 13/08/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

//@objc
protocol FingerPrinter {
    func fingerprint(forSongId songId: SongIDProtocol) -> String?
}


struct FingerPrinterWrapper : FingerPrinter {
    static private let fingerPrinter = TGFingerPrinter()
    func fingerprint(forSongId songId: SongIDProtocol) -> String? {
        return fingerprint(forSongId: songId)
    }
}