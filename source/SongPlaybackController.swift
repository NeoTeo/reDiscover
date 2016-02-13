//
//  SongPlaybackController.swift
//  reDiscover
//
//  Created by teo on 12/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import AVFoundation

protocol SongPlaybackController {
    func requestSongPlayback(songId : SongId, withStartTimeInSeconds time : NSNumber?)
    func requestSongPlayback(songId : SongId)
    func refreshCache(context : SongSelectionContext)
    func dumpCacheToLog()
    func currentlyPlaying() -> SongId
}

protocol SongPlaybackControllerDelegate {
    func getSong(songId : SongId) -> TGSong?
    func getUrl(songId : SongId) -> NSURL?
    func getSongId(gridPos : NSPoint) -> SongId?
}

/** TGSongPlaybackController cannot be a struct because it has dynamic properties
    that are only allowed in classes 
*/
class TGSongPlaybackController : NSObject {

    var delegate : SongPlaybackControllerDelegate?

    private var songAudioCacher = TGSongAudioCacher()
    private var songAudioPlayer = TGSongAudioPlayer()
    
    private var lastRequestedSongId : SongId?
    private var currentlyPlayingSongId : SongId?
    
    /// currentSongDuration needs to be dynamic because it is KVO bound.
    private dynamic var currentSongDuration : NSNumber?

    /// The current position of the playhead.
    private dynamic var playheadPos : NSNumber?

    private dynamic var requestedPlayheadPos : NSNumber?
    dynamic var requestedPlayheadPosition : NSNumber? {
        /**
        This method sets the requestedPlayheadPosition (which represents the position the user has manually set with a slider)
        of the currently playing song to newPosition and sets a sweet spot for the song which gets stored on next save.
        The requestedPlayheadPosition should only result in a sweet spot when the user releases the slider.
        */
        set(newPosition) {
            guard newPosition != nil else { return }
            self.requestedPlayheadPos = newPosition
            songAudioPlayer.currentPlayTime = newPosition!.doubleValue
        }
        
        get {
            return self.requestedPlayheadPos
        }
    }

    override init() {
        delegate = nil
        super.init()
        
        songAudioCacher.delegate = self
    }
}

/** Accessors */
extension TGSongPlaybackController {

    func updateCurrentSongDuration(newDuration : NSNumber?) {
        currentSongDuration = newDuration
    }
    
    func getCurrentSongDuration() -> NSNumber? {
        return currentSongDuration
    }
    
    func getRequestedSongId() -> SongId? {
        return lastRequestedSongId
    }
    
    func getCurrentlyPlayingSongId() -> SongId? {
        return currentlyPlayingSongId
    }
}

extension TGSongPlaybackController {
    
    func setVolume(value : Float) {
        songAudioPlayer.setVolume(0.2)
    }
    
    func setSongPlaybackObserver(songPlayer : AVPlayer) {
        /// MARK : Make sure we're not creating a retain cycle.
        let timerObserver = { [weak self, weak songPlayer] (time : CMTime) -> () in
            /// FIXME : When songPlayer is nil it might be a sign that we're not properly
            /// sync'ing ! Fix
            let currentPlaybackTime = songPlayer!.currentTime()
            self!.songDidUpdatePlayheadPosition(NSNumber(double: CMTimeGetSeconds(currentPlaybackTime)))
        }
        songAudioPlayer.setSongPlayer(songPlayer, block: timerObserver)
    }
    
    func refreshCache(context : SongSelectionContext) {

        /// Cache songs using the context
        songAudioCacher.cacheWithContext(context)

        /// Update the last requestedSongId.
        lastRequestedSongId = context.selectedSongId

        //// Request updated data for the selected song.
//        songMetadataUpdater?.requestUpdatedData(forSongId: lastRequestedSongId!)
    }

    /**     Initiate a request to play back the given song.
     
     If the song has a selected sweet spot play the song from there otherwise
     just play the song from the start.
     :params: songID The id of the song to play.
     */
    func requestSongPlayback(songId: SongId) {
        
        guard let song = delegate?.getSong(songId) else { return }
        let startTime = SweetSpotController.selectedSweetSpotForSong(song)

        requestSongPlayback(songId, withStartTimeInSeconds: startTime)
    }

    
    func requestSongPlayback(songId : SongId, withStartTimeInSeconds time : NSNumber?) {

        /// Ensure we have a delegate to call.
        precondition(delegate != nil)
        
        lastRequestedSongId = songId
        
        songAudioCacher.performWhenPlayerIsAvailableForSongId(songId) { player in
            
            guard (self.lastRequestedSongId != nil) && (self.lastRequestedSongId! == songId) else { return }
            
            self.setSongPlaybackObserver(player)
            let song = self.delegate?.getSong(songId)
            let startTime = time ?? SweetSpotController.selectedSweetSpotForSong(song!) ?? NSNumber(double: 0)
            
            self.songAudioPlayer.playAtTime(startTime.doubleValue)
            self.currentlyPlayingSongId = songId
            
            let duration = song?.duration() ?? CMTimeGetSeconds(self.songAudioPlayer.songDuration)
            /// Only update currentSongDuration if valid.
            if duration != 0 {
                self.currentSongDuration = duration
            }
            self.requestedPlayheadPosition = startTime
        }
    }

    func songDidUpdatePlayheadPosition(playheadPosition : NSNumber) {
        /** Do on the main thread to avoid upsetting CoreAnimation.
            playheadPos property is bound to playlistProgress (which is an NSView).
        */
        dispatch_sync(dispatch_get_main_queue()){
            self.playheadPos = playheadPosition
        }
    }
}

extension TGSongPlaybackController : SongAudioCacherDelegate {
    func getUrl(songId : SongId) -> NSURL? {
        return delegate?.getUrl(songId)
    }
    
    func getSongId(gridPos : NSPoint) -> SongId? {
        return delegate?.getSongId(gridPos)
    }
}

extension TGSongPlaybackController {
    func dumpCacheToLog() {
        songAudioCacher.dumpCacheToLog()
    }
}