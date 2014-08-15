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


// This is using the chromaprint from this workspace.
//#import "/Users/teo/Dropbox/usr/local/include/chromaprint.h"
#import <CommonCrypto/CommonDigest.h>

#import "TGSong.h"
#import "TEOSongData.h"

@implementation TGFingerPrinter

- (id)init {
    self = [super init];
    if (self) {
        av_register_all();
        av_log_set_level(AV_LOG_ERROR);
//        chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);
        fingerprintingQueue = dispatch_queue_create("fingerprinting queue", NULL);
//        fingerprintingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    }
    return self;
}

- (void)dealloc {
    NSLog(@"freeing chromaprint context.");
    //chromaprint_free(chromaprintContext);
}

//- (void)testFunc:(id<SongIDProtocol>) songID {
//    NSLog(@"I gots a songID %@",songID);
//}

// A version of the fingerprint request that uses a completion block instead of a delegate callback.
//- (void)requestFingerPrintForSong:(TGSong *)song withHandler:(void (^)(NSString*))fingerprintHandler {
- (void)requestFingerPrintForSong:(id<SongIDProtocol>)songID withHandler:(void (^)(NSString*))fingerprintHandler {
//#pragma warning returning from requestFingerPrintForSong: withHandler:
//    return;
    
    dispatch_async(fingerprintingQueue, ^{
        int maxLength = 120;
        char *theFingerprint;
        int duration;

        ChromaprintContext *chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);
        NSURL* songURL = [_delegate URLForSongID:songID];
        [self decodeAudioFileNew:songURL forContext:chromaprintContext ofLength:maxLength andDuration:&duration];
        
//        SongID* test = [[SongID alloc] initWithString:(NSString*)songID];
//        SongID* testES =[[SongID alloc] initWithString:(NSString*)songID];
//        if ([test isEqualToSongID:testES]) {
//            NSLog(@"It wooooorks");
//            [self testFunc:test];
//        }
        
        if (chromaprint_get_fingerprint(chromaprintContext, &theFingerprint)) {
        
//            NSLog(@"requesting UUID from generated fingerprint.");
            // Ask AcoustID for the unique id for this song.
            NSURL *acoustIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://api.acoustid.org/v2/lookup?client=8XaBELgH&meta=releases&duration=%d&fingerprint=%s",duration,theFingerprint]];

            NSData *acoustiData = [[NSData alloc] initWithContentsOfURL:acoustIDURL];
            if ([acoustiData length] == 0 ) {
                NSLog(@"ERROR: requestFingerPrintForSong - no acoustic data!");
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
                    NSString* UUIDString = [theElement objectForKey:@"id"];
                    [_delegate setUUIDString:UUIDString forSongID:songID];
//                    song.TEOData.uuid =  [theElement objectForKey:@"id"];
                    
                    // Extract the releases for this song.
                    NSArray* releases = [theElement objectForKey:@"releases"];
                    [_delegate setReleases:[NSKeyedArchiver archivedDataWithRootObject:releases] forSongID:songID];
//                    song.TEOData.songReleases = [NSKeyedArchiver archivedDataWithRootObject:releases];
                    
//                    NSLog(@"Acoustid server returned a UUID %@",UUIDString);
                } else
                    NSLog(@"AcoustID returned 0 results.");
                

            } else
                NSLog(@"ERROR: AcoustID server returned %@",status);
            
            NSString *songFingerPrint = [NSString stringWithCString:theFingerprint encoding:NSASCIIStringEncoding];
            // Deallocate the fingerprint data.
            chromaprint_dealloc(theFingerprint);
        
            // Call the handler with the generated fingerprint.
            fingerprintHandler(songFingerPrint);
            
        } else
            NSLog(@"ERROR: Fingerprinter failed to produce a fingerprint for songID %@",songID);
        
        chromaprint_free(chromaprintContext);
    });
}


- (void)requestFingerPrintForSong:(TGSong *)song {
    //__block NSMutableArray *songFingerPrint = NULL;
#pragma warning returning from requestFingerPrintForSong:
    return;
    
    //NSBlockOperation *theOp = [NSBlockOperation blockOperationWithBlock:^{
    dispatch_async(fingerprintingQueue, ^{
        int maxLength = 120;
        char *theFingerprint;
        int duration;
        ChromaprintContext *chromaprintContext = chromaprint_new(CHROMAPRINT_ALGORITHM_DEFAULT);

        [self decodeAudioFile:[NSURL URLWithString:song.TEOData.urlString] forContext:chromaprintContext ofLength:maxLength andDuration:&duration];

        if (chromaprint_get_fingerprint(chromaprintContext, &theFingerprint)) {
        
//            NSLog(@"requesting UUID from generated fingerprint.");
            // Ask AcoustID for the unique id for this song.
//            NSURL *acoustIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://api.acoustid.org/v2/lookup?client=8XaBELgH&duration=%d&fingerprint=%s",duration,theFingerprint]];
            NSURL *acoustIDURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://api.acoustid.org/v2/lookup?client=8XaBELgH&meta=releases&duration=%d&fingerprint=%s",duration,theFingerprint]];

            NSData *acoustiData = [[NSData alloc] initWithContentsOfURL:acoustIDURL];
            if ([acoustiData length] == 0 ) {
                NSLog(@"ERROR: requestFingerPrintForSong - no acoustic data!");
                return;
            }
            NSDictionary *acoustiJSON = [NSJSONSerialization JSONObjectWithData:acoustiData options:NSJSONReadingMutableContainers error:nil];
//            NSLog(@"The json data is this %@",acoustiJSON);
            
            // First we check that the return status is ok.
            NSString *status = [acoustiJSON objectForKey:@"status"];
            if ([status isEqualToString:@"ok"]) {
                NSArray *results = [acoustiJSON objectForKey:@"results"];
                // The first element is the one with the highest score so we take that (for now).
                // Later we can traverse and compare with any tags we already have.
                if ([results count]) {
                    NSDictionary *theElement = [results objectAtIndex:0];
                    song.TEOData.uuid =  [theElement objectForKey:@"id"];
                    
                    // Extract the releases for this song.
                    NSArray* releases = [theElement objectForKey:@"releases"];
                    song.TEOData.songReleases = [NSKeyedArchiver archivedDataWithRootObject:releases];
                    
//                    NSLog(@"Acoustid server returned a UUID %@",song.TEOData.uuid);
                } else
                    NSLog(@"AcoustID returned 0 results.");
                

            } else
                NSLog(@"ERROR: AcoustID server returned %@",status);
            
            NSString *songFingerPrint = [NSString stringWithCString:theFingerprint encoding:NSASCIIStringEncoding];
            // Deallocate the fingerprint data.
            chromaprint_dealloc(theFingerprint);
        
            if ([_delegate respondsToSelector:@selector(fingerprintReady:ForSong:)]) {
                [_delegate fingerprintReady:songFingerPrint ForSong:song];
            }
        } else
            NSLog(@"ERROR: Fingerprinter failed to produce a fingerprint for song %@",song);
        
        chromaprint_free(chromaprintContext);
    });
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
    //NSLog(@"the url's string is %@",urlString);
    
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
    
	frame = avcodec_alloc_frame();
    
	while (1) {
		if (av_read_frame(format_ctx, &packet) < 0) {
			break;
		}
        
		if (packet.stream_index == stream_index) {
			avcodec_get_frame_defaults(frame);
            
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
		avcodec_free_frame(&frame);
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
    
    frame = avcodec_alloc_frame();
    
    while (1) {
        if (av_read_frame(format_ctx, &packet) < 0) {
            break;
        }
        
        if (packet.stream_index == stream_index) {
            avcodec_get_frame_defaults(frame);
            
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
        avcodec_free_frame(&frame);
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
