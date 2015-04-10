//
//  CoverArtController.swift
//  reDiscover
//
//  Created by Teo on 16/03/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation
import AVFoundation

@objc enum DefaultImage: Int {
    case None
    case Blank
    case Fetching
}
//
class SongArtCache : NSObject {
    typealias HashToImageDict = [String : NSImage]
    
    private let coverArtById: HashToImageDict

    // Three class variables that always contain the same images.
    private static var noCoverImage: NSImage?
    private static var blankCoverImage: NSImage?
    private static var fetchingCoverImage: NSImage?
    
    override init() {
        var defaultCache = HashToImageDict()
        coverArtById = defaultCache
    }
    
    init(startCache: HashToImageDict) {
        coverArtById = startCache
    }

    static func getNoCoverImage() -> NSImage? {
        if noCoverImage == nil {
            noCoverImage = NSImage(named: "noCover")
        }
        return noCoverImage
    }

    static func getBlankCoverImage() -> NSImage? {
        if blankCoverImage == nil {
            blankCoverImage = NSImage(named: "songImage")
        }
        return blankCoverImage
    }

    static func getFetchingCoverImage() -> NSImage? {
        if fetchingCoverImage == nil {
            fetchingCoverImage = NSImage(named: "songImage")
        }
        return fetchingCoverImage
    }

    func addImage(image: NSImage?) -> SongArtCache {

        if let img = image {
            var tmpCache = coverArtById
            tmpCache[img.hashId] = img
            return SongArtCache(startCache: tmpCache)
        }
        
        // If nothing was added we just return the same cache
        return self
    }
    
    func artForSong(song: TGSongProtocol) -> NSImage? {
        // Return art that is already in the cache.
        if let id = song.artID,
            art = coverArtById[id] {
            return art
        }
        
        // No artID means we need to try different ways of finding it.
        let arts = SongMetaData.getCoverArtForSong(song)
        println("I hope i gots lots of arts: \(arts.count)")
        return nil
    }    
}

//struct SongArtCache {
//    var coverArtById = [Int : NSImage](minimumCapacity: 25)
//        let noCoverHash: Int?
//    let defaultCoverHash: Int?
//    let fetchingCoverHash: Int?
//if  let noCoverImage = NSImage(named: "noCover"),
//    let defaultCoverImage = NSImage(named: "songImage"),
//    let fetchingCoverImage = NSImage(named: "fetchingArt")
//{
//    noCoverHash = noCoverImage.hash
//    defaultCoverHash = defaultCoverImage.hash
//    fetchingCoverHash = fetchingCoverImage.hash
//    
//    defaultCache[noCoverHash!] = noCoverImage
//    defaultCache[defaultCoverHash!] = defaultCoverImage
//    defaultCache[fetchingCoverHash!] = fetchingCoverImage
//} else {
//    noCoverHash = nil
//    defaultCoverHash = nil
//    fetchingCoverHash = nil
//    println("Error! Missing a default image")
//}
//
//
//
//}

/*
// So funcs with side effect can hardly be called functional...
extension SongArtCache {
    
    func requestImageForSong(song: Song,artHandler: (NSImage?)->Void ) {
        if let id = song.artId {
            artHandler(coverArtById[id])
            return
        }
        
        self.fetchCoverArtFromSong(song) { images in
            if images != nil {
                
                // For now just use the first image.
                let coverArt = images![0] as NSImage
                let artId = coverArt.hash
                
                // If the image is not already in the local art cache, add it.
                if(self.coverArtById[artId] == nil) {
                    // Cannot mutate the dictionary (unless I declare this function as mutating).
                    // It is ok to mutate the dictionary, because the dictionary itself is a value type.
                    // This means anyone else who accesses it (which is noone outside this struct anyway) will be accessing their own copy.
                    // Even so, I want to change this to take the dictionary as an argument.
                    //self.coverArtById[artId] = coverArt
                }
                
            } else {
                
            }
        }
    }
    
    func fetchCoverArtFromSong(song: Song, imageHandler: ([NSImage]?)->Void) {
        let songAsset = AVURLAsset(URL: NSURL(string: song.urlString) , options: nil)
        
        songAsset.loadValuesAsynchronouslyForKeys(["commonMetadata"]) {
            // This closure is called when the loadValues has completed.
            
            //MARK: Not sure it's necessary to do this next bit async'ly but for now I'll keep it.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                
                // The as! is a forced failable cast new in Swift 1.2 that makes it explicit that the cast may fail
                // and will produce a runtime error if it does.
                if let imagedata: [AVMetadataItem]! = AVMetadataItem.metadataItemsFromArray(songAsset.commonMetadata, withKey: AVMetadataCommonIdentifierArtwork, keySpace: AVMetadataKeySpaceCommon) as! [AVMetadataItem]! {
                    var images = [NSImage]()
                    
                    // Populate the images array with however many images were returned.
                    for mdItem: AVMetadataItem in imagedata {
                        if let image = NSImage(data: mdItem.value().copyWithZone(nil) as! NSData) {
                            images.append(image)
                        }
                        
                        // Let the image handler take it from here.
                        imageHandler(images)
                    }
                    
                }
                
                // No images :(
                imageHandler(nil)
            }
        }
    }
}
*/