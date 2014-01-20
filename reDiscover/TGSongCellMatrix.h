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

- (void)clearView;
- (void)incrementActiveCellCount;
@end
