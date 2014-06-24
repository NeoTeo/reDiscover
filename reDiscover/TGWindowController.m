//
//  TGWindowController.m
//  Proto3
//
//  Created by Teo Sartori on 14/10/2013.
//  Copyright (c) 2013 Teo Sartori. All rights reserved.
//

#import "TGWindowController.h"

#import "TGMainViewController.h"
//#import "TGDropViewController.h"
//#import "TGDropView.h"
#import "TGSongPool.h"

static NSInteger const kDropViewTag = 0;
static NSInteger const kMainViewTag = 1;

static NSString *const kDropViewName = @"TGDropViewController";
static NSString *const kMainViewName = @"TGMainView";


//@interface TGWindowController () <TGDropViewDelegate, NSSeguePerforming>
@interface TGWindowController () <NSSeguePerforming>
@end


@implementation TGWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        activeViewController = nil;
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

/*
- (void)setActiveViewControllerToViewWithTag:(NSInteger)viewTag {
    
    if (activeViewController != nil) {
        [[activeViewController view] removeFromSuperview];
    }
    
    NSView *theContentView = [[self window] contentView] ;
    
    // If the active view controller is the dropview make sure we add ourselves as delegate so we can receive the drop view call.
    if (viewTag == kDropViewTag) {
        
       activeViewController = [[TGDropViewController alloc] initWithNibName:kDropViewName bundle:nil];
       [theContentView addSubview:[activeViewController view]];
        
       TGDropView *theDropView = (TGDropView *)[activeViewController view];
       [theDropView setDelegate:self];
        
    } else {
        
        activeViewController = [[TGMainViewController alloc] initWithNibName:kMainViewName bundle:nil];
        
        [theContentView addSubview:[activeViewController view]];
        
        NSView *theMainView = [activeViewController view];
    
        // Make sure the autoresizing mask doesn't mess with the layout.
        [theMainView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        // Set up the constraints for the main view.
        NSDictionary *viewDictionary = @{@"mainView":theMainView};
        
        // The horizontal priority has to be below 500 to allow window resizing to resize the mainView.
        [theContentView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"H:|[mainView(600@499)]|"
                                      options:0
                                      metrics:nil
                                      views:viewDictionary]];
        
        [theContentView addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|[mainView(600@750)]|"
                                      options:0
                                      metrics:nil
                                      views:viewDictionary]];
    }

}
*/
- (void)awakeFromNib
{
//    [self setActiveViewControllerToViewWithTag:kDropViewTag];
	//[self changeViewController: kImageView];
    // This is necessary to avoid the NSImageView hijacking the drag event. Took me an afternoon to track down.
//    [dropArrowImageView unregisterDraggedTypes];
    // Make sure we get drag and drop notifications
//    TGDropView* theDropView = [[self window] contentView];
//    [theDropView registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, nil]];
//    [theDropView setDelegate:self];
    
    NSLog(@"The window's content view controller is: %@",[self contentViewController]);
    NSLog(@"The window's storyboard is: %@",[self storyboard]);


}

-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"Prepping that segue");
}

// Delegate methods
//


// Drop view delegate method called when a URL is dropped onto it
- (void)dropViewDidReceiveURL:(NSURL *)theURL {
    
    TGSongPool *songPool = [[TGSongPool alloc] init];
    
    if ([songPool validateURL:theURL]) {
        NSLog(@"gogogo");
//        [self setContentViewController:[[self storyboard] instantiateControllerWithIdentifier:@"TheSplit"]];
        NSLog(@"This window is %@ and the first responder is %@",[self window], [[self window] firstResponder]);
        // Dismiss own window (not working?)
//        [self dismissController:nil];

//        [[self contentViewController] performSegueWithIdentifier:@"goMainViewSegue" sender:self];
//        [self performSegueWithIdentifier:@"goMainViewSegue" sender:self];
/*
        // activateIgnoringOtherApps brings the application to the front.
        [NSApp activateIgnoringOtherApps:YES];


        // Change the active view controller to the main view.
        [self setActiveViewControllerToViewWithTag:kMainViewTag];
        
        TGMainViewController *mainViewController = (TGMainViewController *)activeViewController;
        if ([mainViewController respondsToSelector:@selector(setSongPool:)]) {
            [mainViewController setSongPool:songPool];
            [songPool loadFromURL:theURL];
        }
        
        // Ensure that the songGridView receives all the events (in particular the key events).
        [[self window] makeFirstResponder:mainViewController];
*/
    }
}

@end
