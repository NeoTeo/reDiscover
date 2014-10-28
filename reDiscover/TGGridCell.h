//
//  TGGridCell.h
//  Proto3
//
//  Created by Teo Sartori on 15/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

///// class forward declaration
//@class TGCoverImage;

@interface TGGridCell : NSActionCell //NSImageCell

//@property NSImage *songImage;
//@property NSInteger tag;
@property NSTextField *cellText;
@property NSColor *tintColour;
//@property TGCoverImage* coverImage;

@end
