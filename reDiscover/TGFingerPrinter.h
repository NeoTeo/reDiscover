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
@class TGSong;
@protocol TGFingerPrinterDelegate;
@protocol SongIDProtocol;

@interface TGFingerPrinter : NSObject
{
//    ChromaprintContext *chromaprintContext;
    // A serial queue for fingerprinting multiple songs.
    dispatch_queue_t fingerprintingQueue;
    // A concurrent queue for fingerprinting multiple songs.
//    NSOperationQueue *opQueue;
}

- (void)requestFingerPrintForSongID:(id<SongIDProtocol>)songID;
- (void)requestFingerPrintForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSString*))fingerprintHandler;

- (NSInteger)decodeAudioFile:(NSURL *)fileURL forContext:(ChromaprintContext *)theContext ofLength:(NSInteger)maxLength andDuration:(int *)duration;

@property id<TGFingerPrinterDelegate> delegate;

@end



@protocol TGFingerPrinterDelegate <NSObject>
@optional
- (void)fingerprintReady:(NSString *)fingerPrint forSongID:(id<SongIDProtocol>)songID;
- (NSURL *)URLForSongID:(id<SongIDProtocol>)songID;
-(void)setUUIDString:(NSString*)theUUID forSongID:(id<SongIDProtocol>)songID;
- (void)setReleases:(NSData*)releases forSongID:(id<SongIDProtocol>)songID;
@end