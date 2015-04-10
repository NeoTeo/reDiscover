//
//  TGSongProtocol.h
//  reDiscover
//
//  Created by Teo on 07/04/15.
//  Copyright (c) 2015 Teo Sartori. All rights reserved.
//

#ifndef reDiscover_TGSongProtocol_h
#define reDiscover_TGSongProtocol_h

@protocol SongIDProtocol;


@protocol TGSongProtocol
@property (readonly) id<SongIDProtocol>songID;
@property (nonatomic,copy) NSString *artID;
@property (readonly) NSString *urlString;
@end

#endif
