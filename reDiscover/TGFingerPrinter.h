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

@interface TGFingerPrinter : NSObject
{
//    ChromaprintContext *chromaprintContext;
    // A serial queue for fingerprinting multiple songs.
    dispatch_queue_t fingerprintingQueue;
    // A concurrent queue for fingerprinting multiple songs.
//    NSOperationQueue *opQueue;
}

//- (NSArray *)requestFingerPrintForSongURL:(NSURL *)songURL;
//- (NSArray *)requestFingerPrintForSong:(TGSong *)song;
- (void)requestFingerPrintForSong:(TGSong *)song;
- (void)requestFingerPrintForSong:(TGSong *)song withHandler:(void (^)(NSString*))fingerprintHandler;

- (NSInteger)decodeAudioFile:(NSURL *)fileURL forContext:(ChromaprintContext *)theContext ofLength:(NSInteger)maxLength andDuration:(int *)duration;

//-(void)requestCoverArtForSong:(TGSong*)song withHandler:(void (^)(NSImage*))imageHandler;

@property id<TGFingerPrinterDelegate> delegate;

@end



@protocol TGFingerPrinterDelegate <NSObject>
@optional
//- (void)fingerprintReady:(NSArray *)fingerPrint ForSong:(TGSong *)song;
- (void)fingerprintReady:(NSString *)fingerPrint ForSong:(TGSong *)song;
@end