//
//  TGAppDelegate.m
//  Proto3
//
//  Created by Teo Sartori on 13/03/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGAppDelegate.h"
#import "TGMainViewController.h"
#import "TGWindowController.h"

@implementation TGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

#if 1
    if (_theWindowController == NULL) {
        _theWindowController = [[TGWindowController alloc] initWithWindowNibName:@"TGWindowController"];
    }
    
    [_theWindowController showWindow:self];
#else
    // Insert code here to initialize your application
    NSRect windowFrame = NSMakeRect(0, 0, 400, 400);
    
    // init the main controller.
    _mainViewController = [[TGViewController alloc] initWithFrame:windowFrame];
  
    [self setWindow:[[NSWindow alloc] initWithContentRect:windowFrame
                                                styleMask:NSTitledWindowMask | NSClosableWindowMask //|NSResizableWindowMask
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO]];

    [[self window] center];

    // Add the mainViewController's view as a subview of the window's content view.
    [[[self window] contentView] addSubview:[_mainViewController view]];

    [[self window] makeKeyAndOrderFront:NSApp];
#endif
    
}

@end
