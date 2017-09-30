/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import "EtreCheckDeletedFilesCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "XMLBuilder.h"

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

  [deletedFiles
    sortUsingComparator:
      ^(id obj1, id obj2)
        {
        NSDictionary * file1 = (NSDictionary *)obj1;
        NSDictionary * file2 = (NSDictionary *)obj2;

        NSDate * date1 = [file1 objectForKey: @"date"];
        NSDate * date2 = [file2 objectForKey: @"date"];
        
        if(date1 && date2)
          return [date1 compare: date2];
        
        if(date1)
          return (NSComparisonResult)NSOrderedDescending;
          
        if(date2)
          return (NSComparisonResult)NSOrderedAscending;
          
        return (NSComparisonResult)NSOrderedSame;
        }];
  
  NSDate * then =
    [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 7];
  
  BOOL hasOutput = NO;
  
  for(NSDictionary * deletedFile in deletedFiles)
    {
    NSString * reason = [deletedFile objectForKey: @"reason"];
    
    if([reason length] == 0)
      reason = NSLocalizedString(@"Unknown", NULL);
      
    NSDate * date = [deletedFile objectForKey: @"date"];
  
    if(self.simulating || ([then compare: date] == NSOrderedAscending))
      {
      if(!hasOutput)
        {
        [self.result appendAttributedString: [self buildTitle]];
      
        hasOutput = YES;
        }
        
      NSString * path = [deletedFile objectForKey: @"file"];
      
      if([path length] > 0)
        {
        NSString * safePath = [Utilities prettyPath: path];
        
        [self.model startElement: @"deletedfile"];

        [self.model addElement: @"date" date: date];
        [self.model addElement: @"path" value: safePath];
        [self.model addElement: @"reason" value: reason];

        [self.model endElement: @"deletedfile"];
        
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
