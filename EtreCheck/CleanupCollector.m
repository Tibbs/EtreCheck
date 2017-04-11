/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "CleanupCollector.h"
#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"

// Collect information about clean up opportuntities.
@implementation CleanupCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"cleanup";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking for clean up opportuntities", NULL)];

  [self printMissingExecutables];
  
  dispatch_semaphore_signal(self.complete);
  }

// Print any missing executables.
- (void) printMissingExecutables
  {
  NSDictionary * orphanLaunchdFiles = [[Model model] orphanLaunchdFiles];
  
  if([orphanLaunchdFiles count] > 0)
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    NSArray * sortedUnknownLaunchdFiles =
      [[orphanLaunchdFiles allKeys]
        sortedArrayUsingSelector: @selector(compare:)];
      
    [sortedUnknownLaunchdFiles
      enumerateObjectsUsingBlock:
        ^(id obj, NSUInteger idx, BOOL * stop)
          {
          [self.result
            appendString:
              [NSString
                stringWithFormat: @"    %@", [Utilities cleanPath: obj]]];

          NSDictionary * info = [orphanLaunchdFiles objectForKey: obj];
          
          NSString * signature = [info objectForKey: kSignature];
          
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  @"\n        %@\n",
                  [Utilities
                    formatExecutable: [info objectForKey: kCommand]]]];

          // Report a missing executable.
          if([signature isEqualToString: kExecutableMissing])
            {
            [self.result
              appendString:
                [NSString
                  stringWithFormat:
                    NSLocalizedString(
                      @"        Executable not found!\n", NULL)]
              attributes:
                @{
                  NSForegroundColorAttributeName : [[Utilities shared] red],
                  NSFontAttributeName : [[Utilities shared] boldFont]
                }];
            }
          }];
      
    NSString * message =
      TTTLocalizedPluralString(
        [orphanLaunchdFiles count], @"orphan file", NULL);

    [self.result appendString: @"    "];
    
    [self.result
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    NSAttributedString * cleanupLink =
      [self generateRemoveOrphanFilesLink: @"files"];

    if(cleanupLink)
      {
      [self.result appendAttributedString: cleanupLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    
    [[Model model] setCleanupRequired: YES];
    }
  }

@end
