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
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"

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
  [self.result appendAttributedString: [self buildTitle]];

  GatekeeperSetting setting = [self collectGatekeeperSetting];
  
  if(setting == kNoGatekeeper)
    {
    [self.result
      appendString:
        ECLocalizedString(@"gatekeeperneedsmountainlion")
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }

  [self printGatekeeperSetting: setting];

  [self.result appendCR];
  }

// Collect the Gatekeeper setting.
- (GatekeeperSetting) collectGatekeeperSetting
  {
  // Only check gatekeeper on Mountain Lion or later.
  if([[OSVersion shared] major] < kMountainLion)
    return kNoGatekeeper;
    
  bool gatekeeperExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/sbin/spctl"];
  
  if(!gatekeeperExists)
    return kNoGatekeeper;

  NSArray * args =
    @[
      @"--status",
      @"--verbose"
    ];
  
  GatekeeperSetting setting = kSettingUnknown;
    
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"gatekeeper";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

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
  if(setting == kSettingUnknown)
    setting = [self collectMountainLionGatekeeperSetting];
    
  return setting;
  }

// Collect the Mountain Lion Gatekeeper setting.
- (GatekeeperSetting) collectMountainLionGatekeeperSetting
  {
  GatekeeperSetting setting = kSettingUnknown;
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSString * key = @"gatekeeper";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

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
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Mac App Store")];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", ECLocalizedString(@"Mac App Store")]];
      break;
    case kDeveloperID:
      [self.xml 
        addElement: @"status" 
        value: 
          ECLocalizedString(
            @"Mac App Store and identified developers")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n",
              ECLocalizedString(
                @"Mac App Store and identified developers")]];
      break;
    case kDisabled:
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Anywhere")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@ ", ECLocalizedString(@"Anywhere")]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      [self.result appendAttributedString: [self buildFixLink]];
      [self.result appendString: @"\n"];
      break;
      
    case kSettingUnknown:
    default:
      [self.xml 
        addElement: @"status" 
        value: ECLocalizedString(@"Unknown")];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\n", ECLocalizedString(@"Unknown!")]
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
    appendString: ECLocalizedString(@"[Fix Gatekeeper security]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [NSColor redColor],
        NSLinkAttributeName : @"etrecheck://enablegatekeeper/"
      }];
  
  return [urlString autorelease];
  }

@end
