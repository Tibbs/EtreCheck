/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "SafariExtensionsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Safari.h"
#import "SafariExtension.h"
#import "LocalizedString.h"
#import "XMLBuilder.h"
#import "OSVersion.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"

// Collect Safari extensions.
@implementation SafariExtensionsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"safariextensions"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  Safari * safari = [[Model model] safari];
  
  [safari load];

  // Print the extensions.
  [self.result appendAttributedString: [self buildTitle]];

  for(NSString * identifier in safari.extensions)
    [self printExtension: [safari.extensions objectForKey: identifier]];
  
  if(safari.extensions.count == 0)
    [self.result appendString: ECLocalizedString(@"    None\n")];
  
  [self.result appendCR];
  }

// Print a Safari extension.
- (void) printExtension: (SafariExtension *) extension
  {
  [self.model startElement: @"extension"];

  [self printExtensionDetails: extension];
  
  [self appendModificationDate: extension];
  
  [self.result appendString: @"\n"];
  
  [self.model endElement: @"extension"];
  }

// Print extension details
- (void) printExtensionDetails: (SafariExtension *) extension
  {
  // Format the status.
  [self.result appendAttributedString: [self formatStatus: extension]];
  
  [self.model addElement: @"name" value: extension.name];
  [self.model addElement: @"displayname" value: extension.displayName];
  [self.model addElement: @"developer" value: extension.developerName];
  [self.model addElement: @"url" value: extension.developerWebSite];
  
  [self.result appendString: extension.displayName];
    
  if(extension.developerName.length > 0)
    [self.result
      appendString:
        [NSString stringWithFormat: @" - %@", extension.developerName]];
  
  if(extension.developerWebSite.length > 0)
    {
    [self.result appendString: @" - "];
    
    [self.result
      appendString: extension.developerWebSite
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : extension.developerWebSite
        }];
    }
  }

// Format a status string.
- (NSAttributedString *) formatStatus: (SafariExtension *) extension
  {
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
  
  if([[OSVersion shared] major] == kYosemite)
    [output appendString: @"    "];
  else
    {
    NSString * statusString = ECLocalizedString(@"unknown");
    
    NSColor * color = [[Utilities shared] red];
    
    if(!extension.loaded)
      {
      statusString = ECLocalizedString(@"not loaded");
      color = [[Utilities shared] gray];
      }
    else if(extension.enabled)
      {
      statusString = ECLocalizedString(@"enabled");
      color = [[Utilities shared] green];
      }
    else 
      {
      statusString = ECLocalizedString(@"disabled");
      color = [[Utilities shared] gray];
      }
    
    [self.model addElement: @"status" value: statusString];
    
    [output
      appendString: 
        [NSString stringWithFormat: @"    [%@]    ", statusString]
      attributes:
        @{
          NSForegroundColorAttributeName : color,
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  
  return [output autorelease];
  }

// Append the modification date.
- (void) appendModificationDate: (SafariExtension *) extension
  {
  NSDate * modificationDate = [Utilities modificationDate: extension.path];
    
  [self.model addElement: @"installdate" day: modificationDate];
  
  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities installDateAsString: modificationDate];
    
    if(modificationDateString)
      [self.result
        appendString:
          [NSString stringWithFormat: @" (%@)", modificationDateString]];
    }
  }

@end
