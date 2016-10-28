//
//  PopoverSampleAppAppDelegate.m
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

#import "PopoverSampleAppAppDelegate.h"
#import "ContentViewController.h"
#import <INPopoverController/INPopoverController.h>

@implementation PopoverSampleAppAppDelegate
@synthesize window, popover;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ContentViewController *viewController = [[ContentViewController alloc] initWithNibName:@"ContentViewController" bundle:nil];
    self.popover = [[INPopover alloc] initWithContentViewController:viewController];
}

- (IBAction)togglePopover:(id)sender
{
    if (self.popover.popoverIsVisible) {
        [self.popover performClose:nil];
    } else {
        [self.popover presentPopoverFromRect:[sender bounds] inView:sender preferredArrowDirection:INPopoverArrowDirectionLeft anchorsToPositionView:YES];
    }
}

@end
