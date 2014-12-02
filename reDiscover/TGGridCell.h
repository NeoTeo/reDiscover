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
// Used to signal that we don't want to draw the image. Set to true when animating a layer above the image.
@property BOOL hideImage;
//@property TGCoverImage* coverImage;

@end
