//
//  TOFingerPrinter.m
//  Proto3
//
//  Created by Teo Sartori on 02/05/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//
@import AppKit;

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
- (nullable NSString *)fingerprintForSong:(id<TGSong>)theSong {
    
    int maxLength = 120;
    char *theFingerprint;
    int duration;
    
    ChromaprintContext *chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);

    id<SongIDProtocol> songID = theSong.songID;
    
    NSURL* songURL = [_delegate URLForSongID:songID];
    TGLog(TGLOG_TMP,@"requestFingerPrintForSong called with song Id %@",songID);
    [self decodeAudioFileNew:songURL forContext:chromaprintContext ofLength:maxLength andDuration:&duration];
    
    if (chromaprint_get_fingerprint(chromaprintContext, &theFingerprint)) {
        
        NSString *songFingerPrint = [NSString stringWithCString:theFingerprint encoding:NSASCIIStringEncoding];
        
        // Deallocate the fingerprint data.
        chromaprint_dealloc(theFingerprint);
        
        // Call the handler with the generated fingerprint.
        return songFingerPrint;
        
    } else
        TGLog(TGLOG_ALL,@"ERROR: Fingerprinter failed to produce a fingerprint for songId %@",songID);
    
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

// A version of the fingerprint request that uses a completion block instead of a delegate callback.
/**
 Produces a fingerprint from the song with songID using AcoustID and uses the generated fingerprint to 
 request a unique id from the AcoustID web service.
 @params songID The id of the song to fingerprint
 @params fingerprintHandler A closure that handles the generated fingerprint.
 */
- (void)requestFingerPrintForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSString*))fingerprintHandler {
    dispatch_async(fingerprintingQueue, ^{
        int maxLength = 120;
        char *theFingerprint;
        int duration;
        
        ChromaprintContext *chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);
        NSURL* songURL = [_delegate URLForSongID:songID];
        TGLog(TGLOG_TMP,@"requestFingerPrintForSong called with song Id %@",songID);
        [self decodeAudioFileNew:songURL forContext:chromaprintContext ofLength:maxLength andDuration:&duration];
        
        if (chromaprint_get_fingerprint(chromaprintContext, &theFingerprint)) {
            
            //MARK: This needs to be extracted from the fingerprinting so we can use whatever uuid method we like
            // independently of the fingerprinter.
            // Since this is synchronous the call will block until either it succeeded or failed to fetch an UUId.
//            TGLog(TGLOG_TMP,@"requesting UUId from generated fingerprint.");
//            [self requestUUIDForSongID:songID withDuration:duration andFingerPrint:theFingerprint];
            
            NSString *songFingerPrint = [NSString stringWithCString:theFingerprint encoding:NSASCIIStringEncoding];
            
            // Presumably the duration returned from fingerprinting is the most accurate so store it in the song.
//            [_songPoolAPI setSongDuration:[NSNumber numberWithInt:duration] forSongId:songID];
//            [self requestUUIDForSongID:songID withDuration:duration andFingerPrint:(char*)[songFingerPrint UTF8String]];
            
            // Deallocate the fingerprint data.
            chromaprint_dealloc(theFingerprint);
             
            // Call the handler with the generated fingerprint.
            fingerprintHandler(songFingerPrint);
            
        } else
            TGLog(TGLOG_ALL,@"ERROR: Fingerprinter failed to produce a fingerprint for songId %@",songID);
        
        chromaprint_free(chromaprintContext);
    });
}

- (void)requestUUIDForSongID:(id<SongIDProtocol>)songID withDuration:(int)duration andFingerPrint:(char*)theFingerprint {
    // make sure we copy the fingerprint as it gets deallocated outside this method.
    // Don't run this async, since the caller is already running async and shouldn't return before this has had a go.
    // Problem is that SongPool is also calling this with fetchUUIDForSongId:
//    dispatch_async(fingerprintingQueue, ^{
        NSURL *acoustIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://api.acoustid.org/v2/lookup?client=8XaBELgH&meta=releases&duration=%d&fingerprint=%s",duration,theFingerprint]];
        NSData *acoustiData = [[NSData alloc] initWithContentsOfURL:acoustIDURL];
        
        if ([acoustiData length] == 0 ) {
            TGLog(TGLOG_ALL,@"ERROR: requestFingerPrintForSong - no acoustic data!");
            return;
        }
        NSDictionary *acoustiJSON = [NSJSONSerialization JSONObjectWithData:acoustiData options:NSJSONReadingMutableContainers error:nil];
        
        // First we check that the return status is ok.
        NSString *status = [acoustiJSON objectForKey:@"status"];
        if ([status isEqualToString:@"ok"]) {
            NSArray *results = [acoustiJSON objectForKey:@"results"];
            // The first element is the one with the highest score so we take that (for now).
            // Later we can traverse and compare with any tags we already have.
            if ([results count]) {

                NSDictionary *theElement = [results objectAtIndex:0];
                [_delegate setUUIDString:[theElement objectForKey:@"id"] forSongID:songID];
                
                // Extract the releases for this song.
                NSArray* releases = [theElement objectForKey:@"releases"];
                [_delegate setReleases:[NSKeyedArchiver archivedDataWithRootObject:releases] forSongID:songID];
            } else
                TGLog(TGLOG_ALL,@"AcoustID returned 0 results.");
            
        } else
            TGLog(TGLOG_ALL,@"ERROR: AcoustID server returned %@",status);
//    });
}



// Taken from fpcalc.c example of the chromaprint library and slightly modified.
//int decode_audio_file(ChromaprintContext *chromaprint_ctx, const char *file_name, int max_length, int *duration)
- (NSInteger)decodeAudioFile:(NSURL *)fileURL forContext:(ChromaprintContext *)theContext ofLength:(NSInteger)maxLength andDuration:(int *)duration {
    
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

	SwrContext *swr_ctx = NULL;
	int max_dst_nb_samples = 0, dst_linsize = 0;
	uint8_t *dst_data[1] = { NULL };

	uint8_t **data;
	AVPacket packet;
    
    NSString *urlString = [fileURL relativePath];
    const char *file_name = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    //TGLog(TGLOG_ALL,@"the url's string is %@",urlString);
    
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
		fprintf(stderr, "WTF ERROR: no channels found in the audio stream\n");
		goto done;
	}
    
	if (codec_ctx->sample_fmt != AV_SAMPLE_FMT_S16) {

		swr_ctx = swr_alloc_set_opts(NULL,
                                     codec_ctx->channel_layout, AV_SAMPLE_FMT_S16, (int)codec_ctx->channel_layout,
                                     codec_ctx->channel_layout, codec_ctx->sample_fmt, (int)codec_ctx->channel_layout,
                                     0, NULL);
		if (!swr_ctx) {
			fprintf(stderr, "ERROR: couldn't allocate audio converter\n");
			goto done;
		}
		if (swr_init(swr_ctx) < 0) {
			fprintf(stderr, "ERROR: couldn't initialize the audio converter\n");
			goto done;
		}
	}
    
	*duration = (int)(stream->time_base.num * stream->duration / stream->time_base.den);
    
	remaining = (int)maxLength * codec_ctx->channels * codec_ctx->sample_rate;
	chromaprint_start(theContext, codec_ctx->sample_rate, codec_ctx->channels);
    
//	frame = avcodec_alloc_frame(); deprecated
    frame = av_frame_alloc();
    
	while (1) {
		if (av_read_frame(format_ctx, &packet) < 0) {
			break;
		}
        
		if (packet.stream_index == stream_index) {
//			avcodec_get_frame_defaults(frame); deprecated
            av_frame_unref(frame);
            
			got_frame = 0;
			consumed = avcodec_decode_audio4(codec_ctx, frame, &got_frame, &packet);
			if (consumed < 0) {
				fprintf(stderr, "WARNING: error decoding audio\n");
				continue;
			}
            
			if (got_frame) {
				data = frame->data;
				if (swr_ctx) {
					if (frame->nb_samples > max_dst_nb_samples) {
						av_freep(&dst_data[0]);
						if (av_samples_alloc(dst_data, &dst_linsize, codec_ctx->channels, frame->nb_samples, AV_SAMPLE_FMT_S16, 1) < 0) {
							fprintf(stderr, "ERROR: couldn't allocate audio converter buffer\n");
							goto done;
						}
						max_dst_nb_samples = frame->nb_samples;
					}
					if (swr_convert(swr_ctx, dst_data, frame->nb_samples, (const uint8_t **)frame->data, frame->nb_samples) < 0) {
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
//		avcodec_free_frame(&frame); deprecated
        av_frame_free(&frame);
	}

	if (dst_data[0]) {
		av_freep(&dst_data[0]);
	}
	if (swr_ctx) {
		swr_free(&swr_ctx);
	}

	if (codec_ctx_opened) {
		avcodec_close(codec_ctx);
	}
	if (format_ctx) {
		avformat_close_input(&format_ctx);
	}
	return ok;
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
