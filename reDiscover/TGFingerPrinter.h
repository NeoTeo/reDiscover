//
//  TOFingerPrinter.h
//  Proto3
//
//  Created by Teo Sartori on 02/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "chromaprint.h"

// Forward declarations.
@protocol TGFingerPrinterDelegate;
@protocol SongIDProtocol;
@protocol SongPoolAccessProtocol;
@protocol TGSong;
@protocol FingerPrinter;


@interface TGFingerPrinter : NSObject <FingerPrinter>
{
    // A serial queue for fingerprinting multiple songs.
    dispatch_queue_t fingerprintingQueue;
    NSMutableDictionary *fingerPrintStatus;
}

- (nullable NSString *)fingerprintForSongId:(__nonnull id<SongIDProtocol>)songId;


- (NSUInteger)fingerPrintStatusForSong:(__nonnull id<TGSong>)theSong;
- (void)setFingerPrintStatusForSong:(__nonnull id<TGSong>)theSong toStatus:(UInt)status;

#pragma clang assume_nonnull begin
//- (void)requestFingerPrintForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSString*))fingerprintHandler;
//- (NSInteger)decodeAudioFile:(NSURL *)fileURL forContext:(ChromaprintContext __nonnull * __nonnull)theContext ofLength:(NSInteger)maxLength andDuration:(int *)duration;


//@property id<TGFingerPrinterDelegate> delegate;
//@property id<SongPoolAccessProtocol>songPoolAPI;
#pragma clang assume_nonnull end
@end


/*
@protocol TGFingerPrinterDelegate <NSObject>
@optional
#pragma clang assume_nonnull begin
//- (void)fingerprintReady:(NSString *)fingerPrint forSongID:(id<SongIDProtocol>)songID;
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;
#pragma clang assume_nonnull end

@end
*/