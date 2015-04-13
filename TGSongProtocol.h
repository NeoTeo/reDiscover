//
//  TGSongProtocol.h
//  reDiscover
//
//  Created by Teo on 07/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

#ifndef reDiscover_TGSongProtocol_h
#define reDiscover_TGSongProtocol_h

// forward declarations
@protocol SongIDProtocol;
@class SongMetaData;

// The protocol
@protocol TGSongProtocol <NSCopying>
@property (readonly) id<SongIDProtocol>songID;
@property (nonatomic,copy) NSString *artID;
@property (readonly) NSString *urlString;
//@property (readonly) NSNumber *selectedSweetSpot;
@property NSNumber *selectedSweetSpot;
@property NSArray *sweetSpots;
//@property CMTime songDuration;
@property (nonatomic, copy) SongMetaData *metadata;

- (id)copy;
//- (id)copyWithZone:(NSZone *)zone;
@end

#endif
