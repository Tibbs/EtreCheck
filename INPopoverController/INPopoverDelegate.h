//
//  INPopoverDelegate.h
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INPopoverDefines.h"

@class INPopover;

@protocol INPopoverDelegate <NSObject>
@optional
/**
 When the -closePopover: method is invoked, this method is called to give a change for the delegate to prevent it from closing. Returning NO for this delegate method will prevent the popover being closed. This delegate method does not apply to the -forceClosePopover: method, which will close the popover regardless of what the delegate returns.
 @param popover the @class INPopover object that is controlling the popover
 @returns whether the popover should close or not
 */
- (BOOL)popoverShouldClose:(INPopover *)popover;

/**
 Invoked right before the popover shows on screen
 @param popover the @class INPopover object that is controlling the popover
 */
- (void)popoverWillShow:(INPopover *)popover;

/**
 Invoked right after the popover shows on screen
 @param popover the @class INPopover object that is controlling the popover
 */
- (void)popoverDidShow:(INPopover *)popover;

/**
 Invoked right before the popover closes
 @param popover the @class INPopover object that is controlling the popover
 */
- (void)popoverWillClose:(INPopover *)popover;

/**
 Invoked right after the popover closes
 @param popover the @class INPopover object that is controlling the popover
 */
- (void)popoverDidClose:(INPopover *)popover;
@end