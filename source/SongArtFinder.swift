//
//  SongArtFinder.swift
//  reDiscover
//
//  Created by Teo on 11/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Cocoa

/**
The SongArtFinder tries to find the artwork for a given song using a variety of 
different ways:
    - Looks in the metadata via the SongMetaData class.
    - Looks at other songs from the same album.
    - Looks in the directory the song is in.
    - Looks the song up on a web service using the song's UUID.
*/
class SongArtFinder: NSObject {
    
    class func findArtForSong(_ song: TGSong, collection: AlbumCollection) -> NSImage? {

        // No existing artID. Try looking in the metadata.
        let arts = SongCommonMetaData.getCoverArtForSong(song)
        if arts.count > 0 {
            // FIXME: For now just pick the first. We want this to be user selectable.
            return arts[0]
        }

        if let art = findArtForAlbum(forSong: song, inCollection: collection) {
            return art
        }

        if let art = findArtInSongDirectory(song) {
            return art
        }

        if let _ = song.UUId,
            let art = CoverArtArchiveWebFetcher.artForSong(song) {
                return art
        }
        
        return nil
    }
    
    private class func findArtInSongDirectory(_ song: TGSong) -> NSImage? {
        if let urlString = song.urlString, let url = URL(string: urlString) {
//            let dirURL = try! (url as NSURL).filePathURL?.deletingLastPathComponent() {
            let dirURL = url.deletingLastPathComponent()
            let imageURLs = LocalFileIO.imageURLsAtPath(dirURL)
                
            var words = ["scan","album","art","cover","front","fold"]
//            let absString: NSString? = try! dirURL.filePathURL().absoluteString
//            if let albumName = absString.lastPathComponent.removingPercentEncoding {
            if let albumName = url.lastPathComponent.removingPercentEncoding {
                words.append(albumName)
            }
            
            if let matches = imageURLs?.filter(lastURLComponentInMatchWordsFilter(words)), matches.count > 0 {
                return NSImage(contentsOf: matches[0])
            }
        }
        return nil
    }
    
    /**
    This function, given an array of matchWords will return a new lambda function which
    takes an URL and returns true if the last component the URL matches any of the words 
    in the matchWords.
    */
    private class func lastURLComponentInMatchWordsFilter(_ matchWords: [String]) -> (URL) -> Bool {
        
        // Construct a parens wrapped "|" delimited string from the matchWords.
        // This gives "Expression too complex" error. Perhaps a later version of Swift?...
        //var rex = matchWords.reduce("(") { $0 == "(" ? $0 + $1 : $0 + "|" + $1 } + ")"
        let rex = matchWords.reduce("(") { (current, new) in
            if current == "("   { return current + new }
            else                { return current + "|" + new }
        } + ")"
        
        // Return a lambda that returns true if its input matches any of the matchWords.
        return { url in
//            let absString: NSString? = try! url.filePathURL().absoluteString
//            if let word = absString?.lastPathComponent.removingPercentEncoding {
            if let word = url.lastPathComponent.removingPercentEncoding {
                
//                let regEx: RegularExpression?
//                do {
//                    regEx = try RegularExpression(pattern: rex, options: .caseInsensitive)
//                } catch _ {
//                    regEx = nil
//                }
//                let matchRange = regEx?.rangeOfFirstMatch(in: word,
//                                        options: .reportCompletion,
//                                          range: NSRange(location: 0, length: word.characters.count))
//                
//                return matchRange?.location != NSNotFound
                
                if word.range(of:rex, options: .regularExpression) != nil {
                    return true
                }
            }
            return false
        }
    }
    
    /**
    Look at the other songs in the same album the given song belongs to see if they
    have art associated with them and return it if found.
    */
    private class func findArtForAlbum(forSong song: TGSong, inCollection collection: AlbumCollection) -> NSImage? {
        if let albumId = Album.albumIdForSong(song),
            let album = collection.albumWithIdFromCollection(collection, albumId: albumId),
            let albumArt = collection.artForAlbum(album, inCollection: collection){
                return albumArt
        }
        return nil
    }

}
