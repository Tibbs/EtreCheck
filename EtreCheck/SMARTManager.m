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

@end

@implementation SMARTManager

// Show detail.
- (void) showDetail: (NSString *) name
  {
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
    NSString * title =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"SMART report for device %@", NULL), name];
    
    NSString * contentString =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
      
    NSAttributedString * content =
      [[NSAttributedString alloc] initWithString: contentString];
      
    [super showDetail: title content: content];
    
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
  NSSize minWidth = self.minDrawerSize;
  
  if(self.popover)
    minWidth = self.minPopoverSize;
    
  NSSize size = [self.popover contentSize];

  size.width = 645;
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
  else
    {
    if(size.height < self.minPopoverSize.height)
      size.height = self.minPopoverSize.height;

    [self.drawer setContentSize: size];
    }
  }

@end
