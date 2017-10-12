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

// Additional attributes indexed by path.
@synthesize attributes = myAttributes;

// Destructor.
- (void) dealloc
  {
  [myAttributes release];
  
  [super dealloc];
  }
  
// Perform the collection.
- (void) performCollect
  {
  // Create attributes for these launchd files.
  myAttributes = [NSMutableDictionary new];
  
  // Load all launchd files. No-op after first call.
  [[[Model model] launchd] load];
  }

// Print files in a given directory.
- (void) printFilesInDirectory: (NSString *) directory
  {
  NSMutableArray * files = [NSMutableArray new];
  
  for(NSString * path in [[[Model model] launchd] filesByPath])
    if([path hasPrefix: directory])
      {
      LaunchdFile * file = 
        [[[[Model model] launchd] filesByPath] objectForKey: path];
      
      if(file != nil)
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
    [self.model addFragment: file.xml];
    }

  [self.result appendCR];
  }

@end
