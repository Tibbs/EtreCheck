/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "SystemLaunchdCollector.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "XMLBuilder.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Model.h"

// Collect all sorts of launchd information.
@interface LaunchdCollector ()

// Print tasks.
- (void) printFiles: (NSArray *) files;

@end

// A launchd collector that can hide Apple files from RTF output and
// collect totals grouped by status.
@implementation SystemLaunchdCollector

// Print tasks.
- (void) printFiles: (NSArray *) files
  {
  if(![self.model hideAppleTasks])
    [super printFiles: files];
  else
    {  
    [self.result appendAttributedString: [self buildTitle]];
    
    NSMutableDictionary * totals = [NSMutableDictionary new];
    
    // I will have already filtered out launchd files specific to this 
    // context.
    for(LaunchdFile * file in files)
      {
      NSNumber * currentTotal = [totals objectForKey: file.status];
    
      NSNumber * newTotal = 
        [[NSNumber alloc] initWithInt: currentTotal.intValue + 1];
        
      [totals setObject: newTotal forKey: file.status];
      
      [newTotal release];

      // Export the XML.
      [self.xml addFragment: file.xml];
      }

    [self printTotals: totals];
    [self exportTotals: totals];
    
    [totals release];
    
    [self.result appendCR];
    }
  }

// Print totals.
- (void) printTotals: (NSDictionary *) totals
  {
  [self 
    printAppleCount: [[totals objectForKey: kStatusNotLoaded] intValue]
    status: kStatusNotLoaded];
    
  [self 
    printAppleCount: [[totals objectForKey: kStatusLoaded] intValue]
    status: kStatusLoaded];

  [self 
    printAppleCount: [[totals objectForKey: kStatusRunning] intValue]
    status: kStatusRunning];

  [self 
    printAppleCount: [[totals objectForKey: kStatusFailed] intValue]
    status: kStatusFailed];
  }
  
// Export totals.
- (void) exportTotals: (NSDictionary *) totals
  {
  [self 
    exportAppleCount: [[totals objectForKey: kStatusNotLoaded] intValue]
    status: kStatusNotLoaded];
    
  [self 
    exportAppleCount: [[totals objectForKey: kStatusLoaded] intValue]
    status: kStatusLoaded];

  [self 
    exportAppleCount: [[totals objectForKey: kStatusRunning] intValue]
    status: kStatusRunning];

  [self 
    exportAppleCount: [[totals objectForKey: kStatusFailed] intValue]
    status: kStatusFailed];
  }

// Print Apple counts for a given status.
- (void) printAppleCount: (NSUInteger) count
  status: (NSString *) status
  {
  if(count > 0)
    {
    [self.result appendString: @"    "];
    
    [self.result 
      appendAttributedString: [LaunchdTask formatStatus: status]];
    
    [self.result appendString: @"    "];

    [self.result 
      appendString: ECLocalizedPluralString(count, @"applecount")];
    
    [self.result appendString: @"\n"];
    }
  }
  
// Exports Apple counts for a given status.
- (void) exportAppleCount: (NSUInteger) count
  status: (NSString *) status
  {
  if(count > 0)
    {
    [self.xml startElement: @"applelaunchdfile"];
    
    [self.xml addElement: @"status" value: status];
    [self.xml addElement: @"count" unsignedIntegerValue: count];
    
    [self.xml endElement: @"applelaunchdfile"];
    }
  }

@end
