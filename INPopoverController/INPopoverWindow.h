//
//  INPopoverWindow.h
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "INPopoverDefines.h"
#import <QuartzCore/QuartzCore.h>

/** 
 @class INPopoverWindow
 An NSWindow subclass used to draw a custom window frame (@class INPopoverWindowFrame)
 **/
@class INPopoverWindowFrame;
@class INPopover;

@interface INPopoverWindow : NSPanel <CAAnimationDelegate>
{
	NSView * _popoverContentView;
	NSWindow * _zoomWindow;
  INPopoverWindowFrame * _frameView;
  INPopover * _popover;
}

@property (nonatomic, readonly) INPopoverWindowFrame *frameView; // Equivalent to contentView
@property (nonatomic, strong) INPopover *popover;
@property (nonatomic, strong) NSView *popoverContentView;

- (void)presentAnimated;
- (void)dismissAnimated;

@end
