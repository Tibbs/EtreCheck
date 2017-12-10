/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import "EtreCheckDeletedFilesCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSArray+Etresoft.h"
#import "NSDate+Etresoft.h"
#import "NSString+Etresoft.h"

// Collect information about EtreCheck deleted files.
@implementation EtreCheckDeletedFilesCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"etrecheckdeletedfiles"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect information from log files.
- (void) performCollect
  {
  NSMutableArray * deletedFiles =
    [[[NSUserDefaults standardUserDefaults]
      objectForKey: @"deletedfiles"] mutableCopy];

  if(![NSArray isValid: deletedFiles])
    {
    [deletedFiles release];
    
    return;
    }
    
  [deletedFiles
    sortUsingComparator:
      ^(id obj1, id obj2)
        {
        NSDictionary * file1 = (NSDictionary *)obj1;
        NSDictionary * file2 = (NSDictionary *)obj2;

        NSDate * date1 = [file1 objectForKey: @"date"];
        NSDate * date2 = [file2 objectForKey: @"date"];
        
        BOOL valid1 = [NSDate isValid: date1];
        BOOL valid2 = [NSDate isValid: date2];
        
        if(valid1 && valid2)
          return [date1 compare: date2];
        
        if(valid1)
          return (NSComparisonResult)NSOrderedDescending;
          
        if(valid2)
          return (NSComparisonResult)NSOrderedAscending;
          
        return (NSComparisonResult)NSOrderedSame;
        }];
  
  NSDate * then =
    [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 7];
  
  BOOL hasOutput = NO;
  
  for(NSDictionary * deletedFile in deletedFiles)
    {
    NSString * reason = [deletedFile objectForKey: @"reason"];
    
    if(![NSString isValid: reason] || (reason.length == 0))
      reason = ECLocalizedString(@"Unknown");
      
    NSDate * date = [deletedFile objectForKey: @"date"];
  
    if(![NSDate isValid: date])
      continue;
      
    if(self.simulating || ([then compare: date] == NSOrderedAscending))
      {
      if(!hasOutput)
        {
        [self.result appendAttributedString: [self buildTitle]];
      
        hasOutput = YES;
        }
        
      NSString * path = [deletedFile objectForKey: @"file"];
      
      if([NSString isValid: path])
        {
        NSString * safePath = [self prettyPath: path];
        
        [self.xml startElement: @"deletedfile"];

        [self.xml addElement: @"date" date: date];
        [self.xml addElement: @"path" value: safePath];
        [self.xml addElement: @"reason" value: reason];

        [self.xml endElement: @"deletedfile"];
        
        [self.result
          appendString:
            [NSString
              stringWithFormat:
                @"    %@ - %@ - %@\n",
                [Utilities dateAsString: date],
                safePath,
                reason]];
        }
      }
    }
    
  [self.result appendCR];
  }

@end
