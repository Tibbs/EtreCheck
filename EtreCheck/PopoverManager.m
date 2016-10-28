/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "PopoverManager.h"
#import <INPopoverController/INPopoverController.h>

@implementation PopoverManager

@synthesize minDrawerSize = myMinDrawerSize;
@synthesize maxDrawerSize = myMaxDrawerSize;
@synthesize minPopoverSize = myMinPopoverSize;
@synthesize maxPopoverSize = myMaxPopoverSize;
@synthesize contentView = myContentView;
@synthesize popoverViewController = myPopoverViewController;
@synthesize title = myTitle;
@synthesize popover = myPopover;
@synthesize textView = myTextView;
@synthesize details = myDetails;
@dynamic visible;

- (BOOL) visible
  {
  if(myPopover)
    {
    if([myPopover respondsToSelector: @selector(popoverIsVisible)])
      return [(INPopover *)myPopover popoverIsVisible];
    else if([myPopover respondsToSelector: @selector(isShown)])
      return [(NSPopover *)myPopover isShown];
    }
    
  return NO;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myMinDrawerSize = NSMakeSize(400, 100);
    myMaxDrawerSize = NSMakeSize(400, 1000);
    myMinPopoverSize = NSMakeSize(400, 100);
    myMaxPopoverSize = NSMakeSize(400, 600);
    
    if([NSPopover class])
      {
      NSPopover * popover = [[NSPopover alloc] init];
      
      popover.delegate = (id<NSPopoverDelegate>)self;
      
      myPopover = popover;
      }
    else
      {
      INPopover * popover = [[INPopover alloc] init];
      
      popover.delegate = (id<INPopoverDelegate>)self;
      
      myPopover = popover;
      }
    }
  
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.details = nil;
  
  if(self.popover)
    self.popover = nil;
    
  [super dealloc];
  }

// Setup nib connections.
- (void) awakeFromNib
  {
  if(self.popover)
    {
    [self.popover setContentViewController: self.popoverViewController];
    [self.popover setContentSize: self.minPopoverSize];
    [self.popover setBehavior: NSPopoverBehaviorApplicationDefined];
    }
  }

// Show detail.
- (void) showDetail: (NSString *) content
  {
  }

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content
  {
  [self.title setStringValue: title];
  
  self.details = content;
  
  NSData * rtfData =
    [self.details
      RTFFromRange: NSMakeRange(0, [self.details length])
      documentAttributes: @{}];

  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);
  
  [self.textView replaceCharactersInRange: range withRTF: rtfData];
  [self.textView setFont: [NSFont systemFontOfSize: 13]];
  
  [self.textView setEditable: YES];
  [self.textView setEnabledTextCheckingTypes: NSTextCheckingTypeLink];
  [self.textView checkTextInDocument: nil];
  [self.textView setEditable: NO];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];

  [self showDetailWindow];

  NSTextStorage * storage =
    [[NSTextStorage alloc] initWithAttributedString: self.details];

  [self resizeDetail: storage];

  [storage release];
  }

// Show the detail window.
- (void) showDetailWindow
  {
  if(self.popover)
    {
    NSPoint clickPoint =
      [self.contentView
        convertPoint:
          [[self.contentView window] mouseLocationOutsideOfEventStream]
        fromView: nil];
    
    NSRect rect = NSMakeRect(clickPoint.x, clickPoint.y, 40, 1);
    
    [self.popover
      showRelativeToRect: rect
      ofView: self.contentView
      preferredEdge: NSMinXEdge];
    }
  }

// Resize the detail pane to match the content.
- (void) resizeDetail: (NSTextStorage *) storage
  {
  NSSize minWidth = self.minDrawerSize;
  
  if(self.popover)
    minWidth = self.minPopoverSize;
    
  NSSize size = [self.popover contentSize];

  size.width = minWidth.width - 36;
  size.height = FLT_MAX;
  
  NSRect idealRect = [self idealRectForStorage: storage size: size];
    
  size.width += 36;
  size.height = idealRect.size.height + 76;
  size.height += 5;
    
  NSRect textViewFrame = [self.textView frame];
  
  textViewFrame.size.width = size.width - 45;
  textViewFrame.size.height = size.height - 20;
  
  [self.textView setFrame: textViewFrame];
  
  if(self.popover)
    {
    if(size.height < self.minPopoverSize.height)
      size.height = self.minPopoverSize.height;
      
    [self.popover setContentSize: size];
    }
  }

// Get the ideal rect size.
- (NSRect) idealRectForStorage: (NSTextStorage *) storage
  size: (NSSize) size
  {
  NSTextContainer * container =
    [[NSTextContainer alloc] initWithContainerSize: size];
  NSLayoutManager * manager = [[NSLayoutManager alloc] init];
    
  [manager addTextContainer: container];
  [storage addLayoutManager: manager];
   
  [storage
    addAttribute: NSFontAttributeName
    value: [NSFont systemFontOfSize: 15]
    range: NSMakeRange(0, [storage length])];
    
  // Use the same old layout behaviour that the table view uses.
  //[manager
  //  setTypesetterBehavior: NSTypesetterBehavior_10_2_WithCompatibility];
  [manager glyphRangeForTextContainer: container];
  
  NSRect idealRect = [manager usedRectForTextContainer: container];

  [manager release];
  [container release];
  
  return idealRect;
  }

// Close the detail.
- (IBAction) closeDetail: (id) sender
  {
  if(self.popover)
    [self.popover close];
  }

@end
