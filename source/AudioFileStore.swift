//
//  AudioFileStore.swift
//  reDiscover
//
//  Created by Teo on 11/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol AudioFileStore {
    static func songURLsFromURL(_ theURL: URL) -> [URL]?;
}

