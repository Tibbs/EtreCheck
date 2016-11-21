/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
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
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Gatekeeper information", NULL)];

  // Only check gatekeeper on Maountain Lion or later.
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
    
    [self.XML addAttribute: kSeverity value: kWarning];
    [self.XML
      addElement: kSeverityExplanation
      value: NSLocalizedString(@"gatekeeperrequireslion", NULL)];

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
      [self.XML addString: @"Mac App Store"];
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", NSLocalizedString(@"Mac App Store", NULL)]];
      break;
    case kDeveloperID:
      [self.XML addString: @"Mac App Store and identified developers"];
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n",
              NSLocalizedString(
                @"Mac App Store and identified developers", NULL)]];
      break;
    case kDisabled:
      [self.XML addAttribute: kSeverity value: kCritical];
      [self.XML
        addElement: kSeverityExplanation value: @"gatekeeperdisabled"];
      [self.XML addString: @"anywhere"];
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", NSLocalizedString(@"Anywhere", NULL)]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      break;
      
    case kUnknown:
    default:
      [self.XML addAttribute: kSeverity value: kCritical];
      [self.XML
        addElement: kSeverityExplanation value: @"gatekeeperunknown"];
      [self.XML addString: @"unknown"];
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

@end
