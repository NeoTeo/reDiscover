//
//  SongArtFinder.swift
//  reDiscover
//
//  Created by Teo on 11/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

import Foundation

/**
The SongArtFinder tries to find the artwork for a given song using a variety of 
different ways.
1) Looks in the metadata via the SongMetaData class.
2) 
*/
@objc class SongArtFinder {
    static func findArtForSong(song: TGSong, collection: AlbumCollection) -> NSImage? {
        // No existing artID. Try looking in the metadata.
        let arts = SongMetaData.getCoverArtForSong(song)
        if arts.count > 0 {
            // FIXME: For now just pick the first. We want this to be user selectable.
            return arts[0]
        }
        
        if let art = findArtForAlbum(forSong: song, inCollection: collection) {
            return art
        }
        
        if let urlString = song.urlString,
            let url = NSURL(string: urlString),
            let dirURL = url.filePathURL?.URLByDeletingLastPathComponent {
            let imageURLs = LocalFileIO.imageURLsAtPath(dirURL)
                
            var words = ["scan","album","art","cover","front","fold"]
            if let albumName = dirURL.filePathURL?.absoluteString?.lastPathComponent.stringByRemovingPercentEncoding {
                words.append(albumName)
            }

            if let matches = imageURLs?.filter(lastURLComponentInMatchWordsFilter(words)) where matches.count > 0 {
                return NSImage(contentsOfURL: matches[0])
            }

        }
        return nil
    }
    
    /**
    This function, given an array of matchWords will return a new lambda function which
    takes an URL and returns true if the last component the URL matches any of the words 
    in the matchWords.
    */
    private class func lastURLComponentInMatchWordsFilter(matchWords: [String]) -> (NSURL) -> Bool {
        // Make a bar separated string from the array of strings
        // to use in the regular expression.
        var rex = matchWords.reduce("(") {$0 + $1 + "|"}
        let endIdx = advance(rex.endIndex,-1)
        rex = rex.substringToIndex(endIdx)
        rex.insert(")", atIndex: endIdx)
        
        // Return a lambda that returns true if its input matches any of the matchWords.
        return { url in
            if let word = url.filePathURL?.absoluteString?.lastPathComponent.stringByRemovingPercentEncoding {
                let regEx = NSRegularExpression(pattern: rex, options: .CaseInsensitive, error: nil)
                let matchRange = regEx?.rangeOfFirstMatchInString(word, options: .ReportCompletion, range: NSMakeRange(0, count(word)))
                
                return matchRange?.location != NSNotFound
            }
            return false
        }
    }
    
    private class func makeWordFilter(matchWords: [String]) -> (String) -> Bool {
        // Make a bar separated string from the array of strings 
        // to use in the regular expression.
        var rex = matchWords.reduce("(") {$0 + $1 + "|"}
        let endIdx = advance(rex.endIndex,-1)
        rex = rex.substringToIndex(endIdx)
        rex.insert(")", atIndex: endIdx)
        
        // Return a lambda that returns true if its input matches any of the matchWords.
        return { word in
            let regEx = NSRegularExpression(pattern: rex, options: .CaseInsensitive, error: nil)
            let matchRange = regEx?.rangeOfFirstMatchInString(word, options: .ReportCompletion, range: NSMakeRange(0, count(word)))

            return matchRange?.location != NSNotFound
        }
    }
    
    
    /**
    Look at the other songs in the same album the given song belongs to see if they
    have art associated with them and return it if found.
    */
    static private func findArtForAlbum(forSong song: TGSong, inCollection collection: AlbumCollection) -> NSImage? {
        if let albumId = Album.albumIdForSong(song),
            let album = AlbumCollection.albumWithIdFromCollection(collection, albumId: albumId),
            let albumArt = AlbumCollection.artForAlbum(album, inCollection: collection){
                return albumArt
        }
        return nil
    }
    

}
