//
//  TGAppDelegate.h
//  Proto3
//
//  Created by Teo Sartori on 13/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Forward declaration of the main controller class
//@class TGViewController;
@class TGWindowController;

@interface TGAppDelegate : NSObject <NSApplicationDelegate>

//@property (assign) IBOutlet NSWindow *window;
//@property (strong) NSWindow *window;

@property TGWindowController *theWindowController;

//@property TGViewController *mainViewController;

@end
