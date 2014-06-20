//
//  TGSongCellMatrix.h
//  Proto3
//
//  Created by Teo Sartori on 16/07/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TGSongCellMatrix : NSMatrix
{
    NSMutableArray* cellTagToSongID;

}
//@property NSUInteger activeCellCount;
@property int activeCellCount;
// A cell's tag is an index into the cellTagToSongID array.
// That way we can:
//      SongID -> cell (by doing an indexForObject:songID and cellWithTag on the cells array) and
//      cell -> SongID (by looking up the cell's tag in the cellTagToSongID)


// Use to access the queue without causing concurrent access problems.
@property dispatch_queue_t matrixAccessQueue;



- (void)clearView;
- (void)incrementActiveCellCount;
-(BOOL)validateCellRow:(NSInteger)row andColumn:(NSInteger)col;
// Synchronous serial matrixAccessQueue methods
- (NSInteger)indexOfObjectWithSongID:(id)songID;

- (NSInteger)tagForSongWithID:(id)songID;
- (id)songIDForSongWithTag:(NSInteger)songTag;

@end
