/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "DetailManager.h"
#import "LibEtreCheck/LibEtreCheck.h"

@interface PopoverManager ()

// Show detail.
- (void) showDetail: (NSString *) title
  content: (NSAttributedString *) content;

@end

@implementation DetailManager

// Show detail.
- (void) showDetail: (NSString *) name
  {
  DiagnosticEvent * event =
    [[[Model model] diagnosticEvents] objectForKey: name];
  
  NSString * detailsText = event.details;
  
  if(![detailsText length])
    detailsText = NSLocalizedString(@"No details available", NULL);
    
  NSAttributedString * content =
    [[NSAttributedString alloc] initWithString: detailsText];
    
  [super showDetail: name content: content];
    
  [content release];
  }
  
@end
