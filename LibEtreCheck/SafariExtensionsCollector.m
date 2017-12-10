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
  Safari * safari = [self.model safari];
  
  [safari load];

  // Print the extensions.
  int count = 0;
  
  for(NSString * identifier in safari.extensions)
    {
    SafariExtension * extension = 
      [safari.extensions objectForKey: identifier];
      
    if(extension != nil)
      {
      if(count++ == 0)
        [self.result appendAttributedString: [self buildTitle]];
        
      // Print the extension.
      [self.result appendAttributedString: extension.attributedStringValue];
      [self.result appendString: @"\n"];
      
      // Export the XML.
      [self.xml addFragment: extension.xml];
      }
    }
    
  [self.result appendCR];
  }

@end
