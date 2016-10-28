/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "SMARTManager.h"
#import "Model.h"
#import "DiagnosticEvent.h"
#import "SubProcess.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

// Show detail window.
- (void) showDetailWindow;

@end

@implementation SMARTManager

@synthesize spinner = mySpinner;

// Show detail.
- (void) showDetail: (NSString *) name
  {
  [self.spinner startAnimation: self];
  
  NSString * title =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"SMART report for device %@", NULL), name];
    
  [self.title setStringValue: title];
  
  [super showDetailWindow];

  [self resizeDetail];

  NSString * smartctlPath =
    [[NSBundle mainBundle] pathForResource: @"smartctl" ofType: nil];

  NSArray * args =
    @[
      name,
      @"-a"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: smartctlPath arguments: args])
    {
    NSString * contentString =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
      
    NSAttributedString * content =
      [[NSAttributedString alloc] initWithString: contentString];
      
    self.details = content;
    
    NSData * rtfData =
      [self.details
        RTFFromRange: NSMakeRange(0, [self.details length])
        documentAttributes: @{}];

    NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);
    
    [self.textView replaceCharactersInRange: range withRTF: rtfData];
    [self.textView setFont: [NSFont systemFontOfSize: 13]];
    
    [self.spinner stopAnimation: self];
    [self.spinner setHidden: YES];
    [[self.textView enclosingScrollView] setHidden: NO];
    [self.textView setEditable: YES];
    [self.textView setEnabledTextCheckingTypes: NSTextCheckingTypeLink];
    [self.textView checkTextInDocument: nil];
    [self.textView setEditable: NO];

    [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    
    [self.textView
      setFont: [NSFont fontWithName: @"Courier" size: 10]
      range: NSMakeRange(0, [self.details length])];

    [content release];
    [contentString release];
    }
    
  [subProcess release];
  }

// Resize the detail pane to match the content.
- (void) resizeDetail: (NSTextStorage *) storage
  {
  [self resizeDetail];
  }

// Resize the detail pane to match the content.
- (void) resizeDetail
  {
  NSSize minWidth = self.minDrawerSize;
  
  if(self.popover)
    minWidth = self.minPopoverSize;
    
  NSSize size = [self.popover contentSize];

  size.width = 650;
  size.height = 420;
    
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

@end
