/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "HelpManager.h"
#import "LibEtreCheck/LibEtreCheck.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

@end

@implementation HelpManager

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myMinDrawerSize = NSMakeSize(300, 100);
    }
  
  return self;
  }

// Show detail.
- (void) showDetail: (NSString *) name
  {
  NSString * helpText = ESLocalizedStringFromTable(name, @"Help", NULL);
  
  if(![helpText length])
    helpText = NSLocalizedString(@"No help available", NULL);
    
  NSString * adjustText = [helpText stringByAppendingString: @"\n"];
  
  NSAttributedString * content =
    [[NSAttributedString alloc] initWithString: adjustText];
    
  [super
    showDetail: ESLocalizedStringFromTable(name, @"Collectors", NULL)
    content: content];
    
  [content release];
  }

@end
