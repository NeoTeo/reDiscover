//
//  TOFingerPrinter.m
//  Proto3
//
//  Created by Teo Sartori on 02/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//
@import AppKit;

#import "chromaprint.h"
#import "TGFingerPrinter.h"

//#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/opt.h>
#import <libswresample/swresample.h>

#import "rediscover-swift.h"

#import "TGSongPool.h"

// This is using the chromaprint from this workspace.
//#import "/Users/teo/Dropbox/usr/local/include/chromaprint.h"
#import <CommonCrypto/CommonDigest.h>

#import "TGSongProtocol.h"
//#import "TEOSongData.h"

@implementation TGFingerPrinter

- (id)init {
    self = [super init];
    
    if (self) {
        
        av_register_all();
        av_log_set_level(AV_LOG_ERROR);
        fingerprintingQueue = dispatch_queue_create("fingerprinting queue", NULL);
        
        fingerPrintStatus = [NSMutableDictionary dictionaryWithCapacity:100];
    }
    return self;
}

- (void)dealloc {
    TGLog(TGLOG_ALL,@"freeing chromaprint context.");
}

/**
 Produces a fingerprint from the given song using the chromaprint library.

 @params theSong The song to fingerprint.
 @returns the fingerprint as a nullable NSString*.
 */
- (nullable NSString *)fingerprintForSongId:(id<SongIDProtocol> _Nonnull)songId {
    int maxLength = 120;
    char *theFingerprint;
    int duration;
    
    ChromaprintContext *chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);

    //id<SongIDProtocol> songID = theSong.songID;
    
    NSURL* songURL = [SongPool URLForSongId:songId];//[_delegate URLForSongID:songId];

    [self decodeAudioFileNew:songURL forContext:chromaprintContext ofLength:maxLength andDuration:&duration];
    // The duration returned by the decodeAudioFileNew is not very precise - only to the second.
    
    if (chromaprint_get_fingerprint(chromaprintContext, &theFingerprint)) {
        
        NSString *songFingerPrint = [NSString stringWithCString:theFingerprint encoding:NSASCIIStringEncoding];
        
        // Deallocate the fingerprint data.
        chromaprint_dealloc(theFingerprint);
        
        // Call the handler with the generated fingerprint.
        return songFingerPrint;
        
    } else
        TGLog(TGLOG_ALL,@"ERROR: Fingerprinter failed to produce a fingerprint for songId %@",songId);
    
    chromaprint_free(chromaprintContext);

    return nil;
}

//MARK: REFAC - added this to move out of TGSong
- (NSUInteger)fingerPrintStatusForSong:(id<TGSong>)theSong {
    NSUInteger status = [fingerPrintStatus[theSong.songID] unsignedIntegerValue];
    return status;
}

//MARK: REFAC - added this to move out of TGSong
/**
 This does not modify the song, but does modify the fingerPrintStatus dictionary.
 */
- (void)setFingerPrintStatusForSong:(id<TGSong>)theSong toStatus:(UInt)status {
    fingerPrintStatus[theSong.songID] = [NSNumber numberWithUnsignedInteger:status];
}

- (NSInteger)decodeAudioFileNew:(NSURL *)fileURL
                     forContext:(ChromaprintContext *)theContext
                       ofLength:(NSInteger)maxLength
                    andDuration:(int *)duration {
    
    // TEO Early out on DRM protected songs until I figure out what to do with them. Also need better way of detecting them.
    if ([[fileURL pathExtension] isEqualToString:@"m4p"]) {
        return 0;
    }
    
    int ok = 0, remaining, length, consumed, codec_ctx_opened = 0, got_frame, stream_index;
    AVFormatContext *format_ctx = NULL;
    AVCodecContext *codec_ctx = NULL;
    AVCodec *codec = NULL;
    AVStream *stream = NULL;
    AVFrame *frame = NULL;
    
    // So we're using libswresample
    SwrContext *convert_ctx = NULL;
    
    int max_dst_nb_samples = 0, dst_linsize = 0;
    uint8_t *dst_data[1] = { NULL };
    uint8_t **data;
    AVPacket packet;
    
    NSString *urlString = [fileURL relativePath];
    const char *file_name = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    
    if (avformat_open_input(&format_ctx, file_name, NULL, NULL) != 0) {
        fprintf(stderr, "ERROR: couldn't open the file\n");
        goto done;
    }
    
    if (avformat_find_stream_info(format_ctx, NULL) < 0) {
        fprintf(stderr, "ERROR: couldn't find stream information in the file\n");
        goto done;
    }
    
    stream_index = av_find_best_stream(format_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, &codec, 0);
    if (stream_index < 0) {
        fprintf(stderr, "ERROR: couldn't find any audio stream in the file\n");
        goto done;
    }
    
    stream = format_ctx->streams[stream_index];
    
    codec_ctx = stream->codec;
    codec_ctx->request_sample_fmt = AV_SAMPLE_FMT_S16;
    
    if (avcodec_open2(codec_ctx, codec, NULL) < 0) {
        fprintf(stderr, "ERROR: couldn't open the codec\n");
        goto done;
    }
    codec_ctx_opened = 1;
    
    if (codec_ctx->channels <= 0) {
        fprintf(stderr, "ERROR: no channels found in the audio stream\n");
        goto done;
    }
    
    if (codec_ctx->sample_fmt != AV_SAMPLE_FMT_S16) {
        int64_t channel_layout = codec_ctx->channel_layout;
        if (!channel_layout) {
            channel_layout = av_get_default_channel_layout(codec_ctx->channels);
        }
        
        convert_ctx = swr_alloc_set_opts(NULL,
                                     channel_layout, AV_SAMPLE_FMT_S16, (int)codec_ctx->sample_rate,
                                     channel_layout, codec_ctx->sample_fmt, (int)codec_ctx->sample_rate,
                                     0, NULL);
        if (!convert_ctx) {
            fprintf(stderr, "ERROR: couldn't allocate audio converter\n");
            goto done;
        }
        if (swr_init(convert_ctx) < 0) {
            fprintf(stderr, "ERROR: couldn't initialize the audio converter\n");
            goto done;
        }
    }
    
    if (stream->duration != AV_NOPTS_VALUE) {
        *duration = (int)(stream->time_base.num * stream->duration / stream->time_base.den);
    } else if (format_ctx->duration != AV_NOPTS_VALUE) {
        *duration = (int)(format_ctx->duration / AV_TIME_BASE);
    } else {
        fprintf(stderr, "ERROR: couldn't detect the audio duration\n");
        goto done;
    }
    
    remaining = (int)maxLength * codec_ctx->channels * codec_ctx->sample_rate;
    chromaprint_start(theContext, codec_ctx->sample_rate, codec_ctx->channels);
    
//    frame = avcodec_alloc_frame();
    frame = av_frame_alloc();
    
    while (1) {
        if (av_read_frame(format_ctx, &packet) < 0) {
            break;
        }
        
        if (packet.stream_index == stream_index) {
//            avcodec_get_frame_defaults(frame); deprecated
            av_frame_unref(frame);
            
            got_frame = 0;
            consumed = avcodec_decode_audio4(codec_ctx, frame, &got_frame, &packet);
            if (consumed < 0) {
                fprintf(stderr, "WARNING: error decoding audio\n");
                continue;
            }
            
            if (got_frame) {
                data = frame->data;
                if (convert_ctx) {
                    if (frame->nb_samples > max_dst_nb_samples) {
                        av_freep(&dst_data[0]);
                        if (av_samples_alloc(dst_data, &dst_linsize, codec_ctx->channels, frame->nb_samples, AV_SAMPLE_FMT_S16, 1) < 0) {
                            fprintf(stderr, "ERROR: couldn't allocate audio converter buffer\n");
                            goto done;
                        }
                        max_dst_nb_samples = frame->nb_samples;
                    }
                    
                    if (swr_convert(convert_ctx, dst_data, frame->nb_samples, (const uint8_t **)frame->data, frame->nb_samples) < 0) {
                        fprintf(stderr, "ERROR: couldn't convert the audio\n");
                        goto done;
                    }
                    data = dst_data;
                }
                
                length = MIN(remaining, frame->nb_samples * codec_ctx->channels);
                if (!chromaprint_feed(theContext, data[0], length)) {
                    goto done;
                }
                
                if (maxLength) {
                    remaining -= length;
                    if (remaining <= 0) {
                        goto finish;
                    }
                }
            }
        }
        av_free_packet(&packet);
    }
    
finish:
    if (!chromaprint_finish(theContext)) {
        fprintf(stderr, "ERROR: fingerprint calculation failed\n");
        goto done;
    }
    
    ok = 1;
    
done:
    if (frame) {
//        avcodec_free_frame(&frame); deprecated
        av_frame_free(&frame);
    }
    
    if (dst_data[0]) {
        av_freep(&dst_data[0]);
    }
    if (convert_ctx) {
        swr_free(&convert_ctx);
    }
    
    if (codec_ctx_opened) {
        avcodec_close(codec_ctx);
    }
    if (format_ctx) {
        avformat_close_input(&format_ctx);
    }
    return ok;
}

@end
