/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@interface PopoverManager : NSObject
  {
  NSSize myMinDrawerSize;
  NSSize myMaxDrawerSize;
  NSSize myMinPopoverSize;
  NSSize myMaxPopoverSize;
  
  NSView * myContentView;
  
  // My popover view controller.
  NSViewController * myPopoverViewController;
  
  // My detail label.
  NSTextField * myTitle;
  
  // My popover.
  id myPopover;

  // My text content.
  NSTextView * myTextView;
  
  // The current details text.
  NSAttributedString * myDetails;
  }

@property (assign) NSSize minDrawerSize;
@property (assign) NSSize maxDrawerSize;
@property (assign) NSSize minPopoverSize;
@property (assign) NSSize maxPopoverSize;
@property (retain) IBOutlet NSView * contentView;
@property (retain) IBOutlet NSViewController * popoverViewController;
@property (retain) IBOutlet NSTextField * title;
@property (retain) id popover;
@property (retain) IBOutlet NSTextView * textView;
@property (retain) NSAttributedString * details;
@property (readonly) BOOL visible;

// Show detail.
- (void) showDetail: (NSString *) content;

// Close the detail.
- (IBAction) closeDetail: (id) sender;

// Resize the detail pane to match the content.
- (void) resizeDetail: (NSTextStorage *) storage;

@end
