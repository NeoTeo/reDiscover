//
//  Song.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

protocol TGSSong {
    
}

struct Song : TGSSong {
    let artist:     String
    let title:      String
    let album:      String
    let genre:      String
    let urlString:  String
    let artId:      Int?
}
