/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Model.h"

// Collect all sorts of launchd information.
@implementation LaunchdCollector
  
// Perform the collection.
- (void) performCollect
  {
  // Load all launchd files. No-op after first call.
  [[self.model launchd] load];
  }

// Print files in a given directory.
- (void) printFilesInDirectory: (NSString *) directory
  {
  NSMutableArray * files = [NSMutableArray new];
  
  for(NSString * path in [[self.model launchd] filesByPath])
    if([path hasPrefix: directory])
      {
      LaunchdFile * file = 
        [[[self.model launchd] filesByPath] objectForKey: path];
      
      if([LaunchdFile isValid: file])
        [files addObject: file];
      }
      
  [self printFiles: files];
  
  [files release];
  }
  
// Print tasks.
- (void) printFiles: (NSArray *) files
  {
  int count = 0;
  
  // I will have already filtered out launchd files specific to this 
  // context.
  for(LaunchdFile * file in files)
    {
    if(count++ == 0)
      [self.result appendAttributedString: [self buildTitle]];
      
    // Print the file.
    [self.result appendAttributedString: file.attributedStringValue];
    [self.result appendString: @"\n"];
    
    // Export the XML.
    [self.xml addFragment: file.xml];
    }

  if(count > 0)
    [self.result appendCR];
  }

@end
