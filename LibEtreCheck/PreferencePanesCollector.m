/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "PreferencePanesCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"

// Collect 3rd party preference panes.
@implementation PreferencePanesCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"preferencepanes"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPPrefPaneDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
      
      NSArray * items = [results objectForKey: @"_items"];
        
      if([NSArray isValid: items])
        {
        [self.result appendAttributedString: [self buildTitle]];
        
        NSUInteger count = 0;
        
        for(NSDictionary * item in items)
          if([NSDictionary isValid: item])
            if([self printPreferencePaneInformation: item])
              ++count;
          
        if(!count)
          [self.result appendString: ECLocalizedString(@"    None\n")];
          
        [self.result appendCR];
        }
      }
    }
    
  [subProcess release];
  }

// Print information for a preference pane.
// Return YES if this is a 3rd party preference pane.
- (bool) printPreferencePaneInformation: (NSDictionary *) item
  {
  if(![NSDictionary isValid: item])
    return false;
    
  NSString * name = [item objectForKey: @"_name"];

  if(![NSString isValid: name])
    return false;

  NSString * support = [item objectForKey: @"spprefpane_support"];
  
  if(![NSString isValid: support])
    return false;

  NSString * bundleID =
    [item objectForKey: @"spprefpane_identifier"];
  
  if(![NSString isValid: bundleID])
    return false;

  NSString * path = [item objectForKey: @"spprefpane_bundlePath"];

  if(![NSString isValid: path])
    return false;

  if([support isEqualToString: @"spprefpane_support_3rdParty"])
    {
    [self.xml startElement: @"preferencepane"];
    
    [self.xml addElement: @"name" value: name];
    
    [self.result
      appendString: [NSString stringWithFormat: @"    %@ ", name]];
      
    NSAttributedString * supportLink =
      [self getSupportURL: name bundleID: bundleID];
    
    [self appendModificationDate: path];
    
    if(supportLink != nil)
      [self.result appendAttributedString: supportLink];
      
    [self.result appendString: @"\n"];
    
    [self.xml endElement: @"preferencepane"];

    return YES;
    }
    
  return NO;
  }

// Append the modification date.
- (void) appendModificationDate: (NSString *) path
  {
  NSDate * modificationDate = [Utilities modificationDate: path];
    
  [self.xml addElement: @"installdate" date: modificationDate];
  
  if(modificationDate)
    {
    NSString * modificationDateString =
      [Utilities installDateAsString: modificationDate];
    
    if(modificationDateString)
      [self.result
        appendString:
          [NSString stringWithFormat: @"(%@)", modificationDateString]];
    }
  }

@end
