/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "VirtualVolumeCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "LocalizedString.h"
#import "Drive.h"
#import "Volume.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation VirtualVolumeCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"virtualvolume"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  // There should always be data found.
  [self.result appendAttributedString: [self buildTitle]];

  [self printDrives];
  [self exportDrives];
  
  [self printVolumes];
  [self exportVolumes];

  if([[[Model model] storageDevices] count] == 0)
    [self.result
      appendString:
        ECLocalizedString(@"    Disk information not found!\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];

  [self.result appendCR];
  }
  
// Print all drives found.
- (void) printDrives
  {
  // Get a sorted list of devices.
  NSArray * storageDevices = 
    [[[[Model model] storageDevices] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  // Now export all drives matching this type.
  for(NSString * device in storageDevices)
    {
    Drive * drive = [[[Model model] storageDevices] objectForKey: device];
    
    if([drive respondsToSelector: @selector(isDrive)])
      [drive buildAttributedStringValue: self.result];
    }
  }
  
// Export all drives found to XML.
- (void) exportDrives
  {
  // Get a sorted list of devices.
  NSArray * storageDevices = 
    [[[[Model model] storageDevices] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  // Now export all drives matching this type.
  for(NSString * device in storageDevices)
    {
    Drive * drive = [[[Model model] storageDevices] objectForKey: device];
    
    if([drive respondsToSelector: @selector(isDrive)])
      [drive buildXMLValue: self.model];
    }
  }

// Print all volumes found.
- (void) printVolumes
  {
  // Get a sorted list of devices.
  NSArray * storageDevices = 
    [[[[Model model] storageDevices] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  // Now export all drives matching this type.
  for(NSString * device in storageDevices)
    {
    Volume * volume = [[[Model model] storageDevices] objectForKey: device];
    
    if([volume respondsToSelector: @selector(isVolume)])
      [volume buildAttributedStringValue: self.result];
    }
  }
  
// Export all volumes found to XML.
- (void) exportVolumes
  {
  // Get a sorted list of devices.
  NSArray * storageDevices = 
    [[[[Model model] storageDevices] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  // Now export all drives matching this type.
  for(NSString * device in storageDevices)
    {
    Volume * volume = [[[Model model] storageDevices] objectForKey: device];
    
    if([volume respondsToSelector: @selector(isVolume)])
      [volume buildXMLValue: self.model];
    }
  }

@end
