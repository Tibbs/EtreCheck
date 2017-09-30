/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "GatekeeperCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Gatekeeper settings.
typedef enum
  {
  kUnknown,
  kDisabled,
  kDeveloperID,
  kMacAppStore
  }
GatekeeperSetting;
    
// Collect Gatekeeper status.
@implementation GatekeeperCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"gatekeeper"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  // Only check gatekeeper on Mountain Lion or later.
  if([[Model model] majorOSVersion] < kMountainLion)
    return;
    
  [self.result appendAttributedString: [self buildTitle]];

  bool gatekeeperExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/sbin/spctl"];
  
  if(!gatekeeperExists)
    {
    [self.result
      appendString:
        NSLocalizedString(@"gatekeeperneedslion", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }

  GatekeeperSetting setting = [self collectGatekeeperSetting];
  
  [self printGatekeeperSetting: setting];

  [self.result appendCR];
  }

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting
  {
  NSArray * args =
    @[
      @"--status",
      @"--verbose"
    ];
  
  GatekeeperSetting setting = kUnknown;
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/spctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      if(self.simulating)
        trimmedLine = @"assessments disabled";
        
      if([trimmedLine isEqualToString: @"assessments disabled"])
        setting = kDisabled;
      else if([trimmedLine isEqualToString: @"developer id enabled"])
        setting = kDeveloperID;
      else if([trimmedLine isEqualToString: @"developer id disabled"])
        setting = kMacAppStore;
      }
    }
    
  [subProcess release];
  
  // Perhaps I am on Mountain Lion and need to check the old debug
  // command line argument.
  if(setting == kUnknown)
    setting = [self collectMountainLionGatekeeperSetting];
    
  return setting;
  }

// Collect the Mountain Lion Gatekeeper setting.
- (GatekeeperSetting) collectMountainLionGatekeeperSetting
  {
  GatekeeperSetting setting = kUnknown;
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  BOOL result =
    [subProcess
      execute: @"/usr/sbin/spctl" arguments: @[@"--test-devid-status"]];
    
  if(result)
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];

    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
      if([trimmedLine isEqualToString: @""])
        continue;

      if([trimmedLine isEqualToString: @"devid enabled"])
        setting = kDeveloperID;
      else if([trimmedLine isEqualToString: @"devid disabled"])
        setting = kMacAppStore;
      }
    }
    
  [subProcess release];
    
  return setting;
  }

// Print the Gatekeeper setting.
- (void) printGatekeeperSetting: (GatekeeperSetting) setting
  {
  switch(setting)
    {
    case kMacAppStore:
      [self.model 
        addElement: @"status" 
        value: NSLocalizedString(@"Mac App Store", NULL)];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", NSLocalizedString(@"Mac App Store", NULL)]];
      break;
    case kDeveloperID:
      [self.model 
        addElement: @"status" 
        value: 
          NSLocalizedString(
            @"Mac App Store and identified developers", NULL)];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n",
              NSLocalizedString(
                @"Mac App Store and identified developers", NULL)]];
      break;
    case kDisabled:
      [self.model 
        addElement: @"status" 
        value: NSLocalizedString(@"Anywhere", NULL)];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@ ", NSLocalizedString(@"Anywhere", NULL)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      [self.result appendAttributedString: [self buildFixLink]];
      [self.result appendString: @"\n"];
      break;
      
    case kUnknown:
    default:
      [self.model 
        addElement: @"status" 
        value: NSLocalizedString(@"Unknown", NULL)];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", NSLocalizedString(@"Unknown!", NULL)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      break;
    }
  }

// Create an open URL for a file.
- (NSAttributedString *) buildFixLink
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString
    appendString: NSLocalizedString(@"[Fix Gatekeeper security]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [NSColor redColor],
        NSLinkAttributeName : @"etrecheck://enablegatekeeper/"
      }];
  
  return [urlString autorelease];
  }

@end