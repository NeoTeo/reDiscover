//
//  SongMetaData.swift
//  reDiscover
//
//  Created by Teo on 12/05/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

/**
SongMetaData collects all the metadata associated with a song. 
Currently that is SongCommonMetaData and SongRediscoverMetaData.
*/
class SongMetaData {
    let commonMetaData: SongCommonMetaData
    let generatedMetaData: SongGeneratedMetaData
    
    init(common: SongCommonMetaData, genMetaData: SongGeneratedMetaData) {
        commonMetaData = common
        generatedMetaData = genMetaData
        
    }
}