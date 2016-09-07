/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "CPUUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import <stdlib.h>
#import "Model.h"

// Collect information about CPU usage.
@implementation CPUUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"cpu"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Collecting CPU usage", NULL)];

  [self.result appendAttributedString: [self buildTitle]];
  
  [self printLoad];
  
  [self.result appendCR];
    
  dispatch_semaphore_signal(self.complete);
  }

// Print system load.
- (void) printLoad
  {
  double loads[3];
  
  int result = getloadavg(loads, 3);
  
  NSArray * labels =
    [NSArray
      arrayWithObjects:
        NSLocalizedString(@"Current system load", NULL),
        NSLocalizedString(@"System load for past 5 minutes", NULL),
        NSLocalizedString(@"System load for past 15 minutes", NULL),
        nil];
    
  if(result != -1)
    for(int index = 0; index < 3; ++index)
      {
      double load = loads[index] / (double)[[Model model] coreCount] * 100;
      
      NSString * output =
        [NSString
          stringWithFormat:
            @"    %4.0lf%%\t%@\n",
            load,
            [labels objectAtIndex: index]];
        
      if(load > 80.0)
        [self.result
          appendString: output
          attributes:
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil]];      
      else
        [self.result appendString: output];
            
      }
  }

@end
