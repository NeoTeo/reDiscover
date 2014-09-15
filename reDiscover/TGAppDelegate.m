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


    if (_theWindowController == NULL) {
        _theWindowController = [[TGWindowController alloc] initWithWindowNibName:@"TGWindowController"];
    }
    [_theWindowController showWindow:self];    
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"reDiscover is quitting");
}
@end
