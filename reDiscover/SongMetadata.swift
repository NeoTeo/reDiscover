//
//  SongMetadata.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation

class SongMetaData : NSObject {
    
}

extension SongMetaData {

    /** 
    This class method will *synchronously* fetch the cover art it finds in the songAsset's
    metadata.
    
    :param: song A song or nil
    :returns: An array of NSImages or an array of nil if nothing was found.
    */
    static func getCoverArtForSong(song: TGSongProtocol?) -> [NSImage?] {
        if  let sng = song,
            let songAsset = AVURLAsset(URL: NSURL(string: sng.urlString) , options: nil) {
            
                let sema = dispatch_semaphore_create(0)
                
                songAsset.loadValuesAsynchronouslyForKeys(["commonMetadata"]){

                    // Now that the metadata is loaded, signal to continue below.
                    dispatch_semaphore_signal(sema)
                }

                // Wait for the load to complete.
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)

                let artworks = AVMetadataItem.metadataItemsFromArray(songAsset.commonMetadata, withKey: AVMetadataCommonKeyArtwork, keySpace:AVMetadataKeySpaceCommon)

                var retArt = [NSImage?]()
                for aw in artworks {
                    retArt.append(aw as? NSImage)
                }
                return retArt
        }
        
        return [nil]
    }
    
    func loadForSongId(songId: SongIDProtocol) -> Bool {
        return true
    }
}