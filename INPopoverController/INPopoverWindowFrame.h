//
//  INPopoverWindowFrame.h
//  Copyright 2011-2014 Indragie Karunaratne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INPopoverDefines.h"

/**
 @class INPopoverWindowFrame
 The NSView subclass responsible for drawing the frame of the popover
 */
@interface INPopoverWindowFrame : NSView
  {
  NSColor * _color;
  NSColor * _borderColor;
  NSColor * _topHighlightColor;
  CGFloat _borderWidth;
  CGFloat _cornerRadius;
  NSSize _arrowSize;
  NSRectEdge _edge;
  }

@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, strong) NSColor *topHighlightColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) NSSize arrowSize;
@property (nonatomic, assign) NSRectEdge edge;
@end
