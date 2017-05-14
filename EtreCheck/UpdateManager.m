/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "UpdateManager.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

@implementation UpdateManager

@synthesize window = myWindow;
@synthesize textView = myTextView;
@synthesize content = myContent;
@synthesize updateURL = myUpdateURL;

// Destructor.
- (void) dealloc
  {
  [myWindow release];
  [myTextView release];
  [myContent release];
  [myUpdateURL release];
  
  [super dealloc];
  }

// Allow quit.
- (void) awakeFromNib
  {
  self.window.preventsApplicationTerminationWhenModal = NO;  
  }

// Show the window.
- (void) show
  {
  if(!self.content)
    self.content = NSLocalizedString(@"nocontenthtml", NULL);
    
  NSAttributedString * details =
    [[NSAttributedString alloc]
      initWithHTML: [self.content dataUsingEncoding: NSUTF8StringEncoding]
      documentAttributes: nil];

  NSData * rtfData =
    [details
      RTFFromRange: NSMakeRange(0, [details length])
      documentAttributes: @{}];

  NSRange range = NSMakeRange(0, [[self.textView textStorage] length]);
  
  [self.textView replaceCharactersInRange: range withRTF: rtfData];
  [self.textView setFont: [NSFont systemFontOfSize: 13]];
  
  [self.textView setEditable: YES];
  [self.textView setEnabledTextCheckingTypes: NSTextCheckingTypeLink];
  [self.textView checkTextInDocument: nil];
  [self.textView setEditable: NO];

  [self.textView scrollRangeToVisible: NSMakeRange(0, 1)];
    
  [details release];

  [[NSApplication sharedApplication] runModalForWindow: self.window];
  }

// Quit and go to update.
- (IBAction) quitAndUpdate: (id) sender;
  {
  [[NSApplication sharedApplication] stopModal];

  [self.window close];

  [[NSWorkspace sharedWorkspace] openURL: self.updateURL];
  
  [[NSApplication sharedApplication] terminate: self];
  }

// Continue without update.
- (IBAction) continueWithoutUpdate: (id) sender;
  {
  [[NSApplication sharedApplication] stopModal];
  
  [self.window close];
  }

@end
