//
//  TGSongCellMatrix.h
//  Proto3
//
//  Created by Teo Sartori on 16/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TGSongCellMatrix : NSMatrix

@property NSUInteger activeCellCount;
// A cell's tag is an index into the cellTagToSongID array.
// That way we can:
//      SongID -> cell (by doing an indexForObject:songID and cellWithTag on the cells array) and
//      cell -> SongID (by looking up the cell's tag in the cellTagToSongID)
@property NSMutableArray* cellTagToSongID;

- (void)clearView;
- (void)incrementActiveCellCount;
@end
