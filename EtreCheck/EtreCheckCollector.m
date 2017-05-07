/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2016. All rights reserved.
 **********************************************************************/

#import "EtreCheckCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"

// Collect information about EtreCheck itself.
@implementation EtreCheckCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"etrecheckdeletedfiles";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking information from EtreCheck", NULL)];

  [self collectEtreCheck];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect information from log files.
- (void) collectEtreCheck
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
  
    if([then compare: date] == NSOrderedAscending)
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
