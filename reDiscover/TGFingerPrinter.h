//
//  TOFingerPrinter.h
//  Proto3
//
//  Created by Teo Sartori on 02/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <chromaprint.h>

//#import "/Users/teo/Dropbox/usr/local/include/chromaprint.h"
//#import "/Users/teo/Dropbox/usr/local/include/chromaprint.h"
// Forward declarations.
//@class TGSong;
@protocol TGFingerPrinterDelegate;
@protocol SongIDProtocol;
@protocol SongPoolAccessProtocol;
@protocol TGSong;


@interface TGFingerPrinter : NSObject
{
//    ChromaprintContext *chromaprintContext;
    // A serial queue for fingerprinting multiple songs.
    dispatch_queue_t fingerprintingQueue;
    // A concurrent queue for fingerprinting multiple songs.
//    NSOperationQueue *opQueue;
    NSMutableDictionary *fingerPrintStatus;
}

- (nullable NSString *)fingerprintForSong:(__nonnull id<TGSong>)theSong;
- (__nonnull id<TGSong>)songWithFingerPrint:(__nonnull id<TGSong>)song;
    
//MARK: REFAC
- (NSUInteger)fingerPrintStatusForSong:(__nonnull id<TGSong>)theSong;
- (void)setFingerPrintStatusForSong:(__nonnull id<TGSong>)theSong toStatus:(UInt)status;

#pragma clang assume_nonnull begin
- (void)requestFingerPrintForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSString*))fingerprintHandler;
- (void)requestUUIDForSongID:(id<SongIDProtocol>)songID withDuration:(int)duration andFingerPrint:(char*)theFingerprint;
- (NSInteger)decodeAudioFile:(NSURL *)fileURL forContext:(ChromaprintContext *)theContext ofLength:(NSInteger)maxLength andDuration:(int *)duration;


@property id<TGFingerPrinterDelegate> delegate;
@property id<SongPoolAccessProtocol>songPoolAPI;
#pragma clang assume_nonnull end
@end



@protocol TGFingerPrinterDelegate <NSObject>
@optional
#pragma clang assume_nonnull begin
//- (void)fingerprintReady:(NSString *)fingerPrint forSongID:(id<SongIDProtocol>)songID;
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;
#pragma clang assume_nonnull end

@end
