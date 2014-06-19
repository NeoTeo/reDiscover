//
//  TGDropView.m
//  Proto3
//
//  Created by teo on 25/03/13.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGDropView.h"

@implementation TGDropView
- (void)awakeFromNib {
    // This is necessary to avoid the NSImageView hijacking the drag event. Took me an afternoon to track down.
    [dropArrowImageView unregisterDraggedTypes];
    // Make sure we get drag and drop notifications
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, nil]];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationLink;
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] ) {
        
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSLog(@"drop!");

        
        // Pass the url back to the controller.
        if (_delegate && [_delegate respondsToSelector:@selector(dropViewDidReceiveURL:)]) {
            
            [_delegate dropViewDidReceiveURL:fileURL];
        }
    }
    
    return YES;
}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"I'll be...prepared");
}

@end
