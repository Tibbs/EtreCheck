/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "DiskCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "ByteCountFormatter.h"
#import "NSArray+Etresoft.h"
#import "TTTLocalizedPluralString.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Some keys for an internal dictionary.
#define kDiskType @"volumetype"
#define kDiskStatus @"volumestatus"
#define kAttributes @"attributes"

// Collect information about disks.
@implementation DiskCollector

@dynamic volumes;

// Provide easy access to volumes.
- (NSMutableDictionary *) volumes
  {
  return [[Model model] volumes];
  }

// Constructor.
- (id) init
  {
  self = [super initWithName: @"disk"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  BOOL dataFound = [self collectSerialATA];
  
  if([self collectNVMExpress: dataFound])
    dataFound = YES;
  
  // There should always be data found.
  if(!dataFound)
    {
    [self.result appendAttributedString: [self buildTitle]];

    [self.result
      appendString:
        NSLocalizedString(@"    Disk information not found!\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red]
        }];

    [self.result appendCR];
    }
  }

// Perform the collection for old Serial ATA controllers.
- (BOOL) collectSerialATA
  {
  BOOL dataFound = NO;
      
  NSArray * args =
    @[
      @"-xml",
      @"SPSerialATADataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  //subProcess.debugStandardOutput =
  //  [NSData
  //    dataWithContentsOfFile: @"/tmp/SPSerialATADataType.xml"];
    
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
     NSArray * plist =
       [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if(controllers.count > 0)
        {
        [self.model startElement: @"controllers"];
        
        for(NSDictionary * controller in controllers)
          if([self shouldPrintController: controller])
            {
            BOOL printed =
              [self 
                printController: controller 
                type: @"SerialATA" 
                dataFound: dataFound];
              
            if(printed)
              dataFound = YES;
            }

        [self.model endElement: @"controllers"];
        }
      }
    }

  [subProcess release];
  
  return dataFound;
  }

// Perform the collection for new NVM controllers.
- (BOOL) collectNVMExpress: (BOOL) dataFound
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPNVMeDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSDictionary * controllers =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if(controllers.count > 0)
        {
        [self.model startElement: @"controllers"];
        
        for(NSDictionary * controller in controllers)
          if([self shouldPrintController: controller])
            {
            BOOL printed =
              [self 
                printController: controller 
                type: @"NVMExpress" 
                dataFound: dataFound];
            
            if(printed)
              dataFound = YES;
            }

        [self.model endElement: @"controllers"];
        }
      }
    }

  return dataFound;
  }

// Should this controller be printed here?
- (BOOL) shouldPrintController: (NSDictionary *) controller
  {
  NSString * name = [controller objectForKey: @"_name"];
  
  if([name hasPrefix: @"Thunderbolt"])
    return NO;
    
  return YES;
  }

// Print disks attached to a single NVMExpress controller.
- (BOOL) printController: (NSDictionary *) controller
  type: (NSString *) type dataFound: (BOOL) dataFound
  {
  [self.model startElement: @"controller"];
  
  [self.model addElement: @"interfacetype" value: type];

  NSDictionary * disks = [controller objectForKey: @"_items"];
  
  if(disks.count > 0)
    {
    [self.model startElement: @"disks"];
    
    for(NSDictionary * disk in disks)
      {
      [self.model startElement: @"disk"];
      
      NSString * diskName = [disk objectForKey: @"_name"];
      NSString * diskDevice = [disk objectForKey: @"bsd_name"];
      NSString * diskSize = [disk objectForKey: @"size"];
      NSString * UUID = [disk objectForKey: @"volume_uuid"];
      NSString * medium = [disk objectForKey: @"spsata_medium_type"];
      NSString * TRIM = [disk objectForKey: @"spnvme_trim_support"];
      
      NSString * TRIMString =
        [NSString
          stringWithFormat: @" - TRIM: %@", ESLocalizedString(TRIM, NULL)];
      
      NSString * info =
        [NSString
          stringWithFormat:
            @"(%@%@)",
            medium
              ? ESLocalizedString(medium, NULL)
              : @"",
            ([medium isEqualToString: @"Solid State"] && [TRIM length])
              ? TRIMString
              : @""];
        
      if([diskDevice length] == 0)
        diskDevice = @"";
        
      [self.model addElement: @"device" value: diskDevice];
      [self.model addElement: @"size" valueWithUnits: diskSize];
      [self.model addElement: @"UUID" value: UUID];

      if([diskSize length] > 0)
        diskSize =
          [NSString
            stringWithFormat: 
              @": (%@)", [Utilities translateSize: diskSize]];
      else
        diskSize = @"";

      if([UUID length] > 0)
         [self.volumes setObject: disk forKey: UUID];
        
      if(!dataFound)
        [self.result appendAttributedString: [self buildTitle]];
        
      [self.model addElement: @"name" value: diskName];
      [self.model addElement: @"medium" value: medium];
      
      if([medium isEqualToString: @"Solid State"])
        [self.model addElement: @"TRIM" value: TRIM];

      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@ %@%@ %@\n",
              diskName ? diskName : @"-", diskDevice, diskSize, info]];
      
      [self collectSMARTStatus: disk indent: @"    "];
      
      [self printDiskVolumes: disk];
      
      [self.result appendCR];
      
      dataFound = YES;
      
      [self.model endElement: @"disk"];
      }

    [self.model endElement: @"disks"];
    }
    
  [self.model endElement: @"controller"];

  return dataFound;
  }

// Print the volumes on a disk.
- (void) printDiskVolumes: (NSDictionary *) disk
  {
  NSArray * volumes = [disk objectForKey: @"volumes"];
  
  if([volumes count] > 0)
    {
    [self.model startElement: @"volumes"];
    
    for(NSDictionary * volume in volumes)
      {
      [self.model startElement: @"volume"];
      
      [self printVolume: volume indent: @"        "];
      
      [self.model endElement: @"volume"];
      }
      
    [self.model endElement: @"volumes"];
    }
  }

// Get the SMART status for this disk.
- (void) collectSMARTStatus: (NSDictionary *) disk
  indent: (NSString *) indent
  {
  NSString * smart_status = [disk objectForKey: @"smart_status"];

  if(!smart_status)
    return;
    
  [self.model addElement: @"smartstatus" value: smart_status];
  
  bool smart_not_supported =
    [smart_status isEqualToString: @"Not Supported"];
  
  bool smart_verified =
    [smart_status isEqualToString: @"Verified"];

  if(!smart_not_supported && !smart_verified)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"%@S.M.A.R.T. Status: %@\n", NULL),
            indent, smart_status]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];

  NSString * device = [disk objectForKey: @"bsd_name"];
  
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  if(!smart_not_supported)
    {
    [urlString
      appendString:
        [NSString stringWithFormat:
          NSLocalizedString(@"%@[Show SMART report]", NULL), indent]
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName :
            [NSString stringWithFormat: @"etrecheck://smart/%@", device]
        }];

    [self.result appendAttributedString: urlString];
    [self.result appendString: @"\n"];
    }
    
  [urlString release];
  }
  
// Print information about a volume.
- (void) printVolume: (NSDictionary *) volume indent: (NSString *) indent
  {
  NSString * volumeName = [volume objectForKey: @"_name"];
  NSString * volumeMountPoint = [volume objectForKey: @"mount_point"];
  NSString * volumeDevice = [volume objectForKey: @"bsd_name"];
  NSString * volumeSize = [self volumeSize: volume];
  NSString * volumeFree = [self volumeFreeSpace: volume];
  NSString * UUID = [volume objectForKey: @"volume_uuid"];
  NSString * fileSystem = [volume objectForKey: @"file_system"];
    
  NSNumber * size = [volume objectForKey: @"size_in_bytes"];
  NSNumber * free = [volume objectForKey: @"free_space_in_bytes"];

  [self.model addElement: @"device" value: volumeDevice];
  [self.model addElement: @"name" value: volumeName];
  [self.model addElement: @"mountpoint" value: volumeMountPoint];
  
  if(!volumeMountPoint)
    volumeMountPoint = NSLocalizedString(@"<not mounted>", NULL);
    
  if(UUID)
    {
    [self.model addElement: @"UUID" value: UUID];
    
    [self.volumes setObject: volume forKey: UUID];
    }
    
  [self.model 
    addElement: @"size" 
    number: size 
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"B", @"units", nil]];
      
  if(free != nil)
    [self.model 
      addElement: @"free" 
      number: free 
      attributes: 
        [NSDictionary dictionaryWithObjectsAndKeys: @"B", @"units", nil]];

  [self.model addElement: @"filesystem" value: fileSystem];

  NSDictionary * stats = [self volumeStats: volume];

  NSDictionary * attributes = [stats objectForKey: kAttributes];
  
  NSNumber * errorCount =
    [[[Model model] diskErrors] objectForKey: volumeDevice];

  NSString * errors = [self errorsFor: volumeDevice];
  
  if([errors length])
    {
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };

    [self.model addElement: @"errors" number: errorCount];
    }
    
  NSString * status =
    [[stats objectForKey: kDiskStatus] stringByAppendingString: errors];

  NSString * volumeInfo = nil;
  
  NSString * fileSystemName = @"";
  
  if([fileSystem length] > 0)
    fileSystemName =
      [NSString
        stringWithFormat: @" - %@", ESLocalizedString(fileSystem, NULL)];
    
  if([fileSystemName length] > 0)
    {
    volumeInfo =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"%@%@ (%@%@) %@ %@: %@ %@%@\n", NULL),
          indent,
          volumeName ? [Utilities cleanPath: volumeName] : @"",
          volumeDevice,
          fileSystemName,
          volumeMountPoint,
          [stats objectForKey: kDiskType],
          volumeSize ? volumeSize : @"",
          volumeFree ? volumeFree : @"",
          status];
      
    [[[Model model] physicalVolumes] addObject: volumeDevice];
    }
  else
    volumeInfo =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"%@(%@) %@ %@: %@\n", NULL),
          indent,
          volumeDevice,
          volumeMountPoint,
          [stats objectForKey: kDiskType],
          volumeSize];
    
  if(attributes)
    [self.result appendString: volumeInfo attributes: attributes];
  else
    [self.result appendString: volumeInfo];
  }

// Get the size of a volume.
- (NSString *) volumeSize: (NSDictionary *) volume
  {
  NSString * size = nil;
  
  NSNumber * sizeInBytes =
    [volume objectForKey: @"size_in_bytes"];
  
  if(sizeInBytes)
    {
    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    size =
      [formatter
        stringFromByteCount: [sizeInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!size)
    size = [volume objectForKey: @"size"];

  if(!size)
    size = NSLocalizedString(@"Size unknown", NULL);
    
  return size;
  }

// Get the free space on the volume.
- (NSString *) volumeFreeSpace: (NSDictionary *) volume
  {
  NSString * volumeFree = nil;
  
  NSNumber * freeSpaceInBytes =
    [volume objectForKey: @"free_space_in_bytes"];
  
  if(freeSpaceInBytes)
    {
    ByteCountFormatter * formatter = [ByteCountFormatter new];
    
    volumeFree =
      [formatter
        stringFromByteCount: [freeSpaceInBytes unsignedLongLongValue]];
      
    [formatter release];
    }

  if(!volumeFree)
    volumeFree = [volume objectForKey: @"free_space"];

  if(!volumeFree)
    volumeFree = @"";
  else
    volumeFree =
      [NSString
        stringWithFormat:
          NSLocalizedString(@"(%@ free)", NULL), volumeFree];
    
  return volumeFree;
  }

// Get more information about a volume.
- (NSDictionary *) volumeStats: (NSDictionary *) volume
  {
  NSString * name = [volume objectForKey: @"_name"];
  NSString * mountPoint = [volume objectForKey: @"mount_point"];
  NSString * iocontent = [volume objectForKey: @"iocontent"];
  unsigned long long free =
    [[volume objectForKey: @"free_space_in_bytes"] unsignedLongLongValue];
  NSString * filesystem = [volume objectForKey: @"file_system"];
  
  NSString * type = NSLocalizedString(@"", NULL);
  NSString * status = NSLocalizedString(@"", NULL);
  NSDictionary * attributes = @{};
  
  if([mountPoint isEqualToString: @"/"])
    {
    type = NSLocalizedString(@"Startup", NULL);

    unsigned long long GB = 1024 * 1024 * 1024;

    if(free < (GB * 15))
      status = NSLocalizedString(@" (Low!)", NULL);
    }
  
  else if([name isEqualToString: @"Recovery HD"])
    type = NSLocalizedString(@"Recovery", NULL);
    
  else if([name isEqualToString: @"EFI"])
    type = NSLocalizedString(@"EFI", NULL);
    
  else if([name isEqualToString: @"KernelCoreDump"])
    type = NSLocalizedString(@"KernelCoreDump", NULL);

  else if([filesystem length] == 0)
    {
    if([iocontent hasPrefix: @"Apple_"])
      type = [iocontent substringFromIndex: 6];
    
    if([type isEqualToString: @"APFS"])
      type = NSLocalizedString(@"APFS Container", NULL);
    else if([type isEqualToString: @"CoreStorage"])
      type = NSLocalizedString(@"CoreStorage Container", NULL);
    }

  if([mountPoint length] == 0)
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] gray]
      };
    
  [self.model addElement: @"type" value: type];

  if([type length] > 0)
    type = [NSString stringWithFormat: @" [%@]", type];
    
  if([status length] && ![attributes count])
    attributes =
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      };

  return
    @{
      kDiskType : type,
      kDiskStatus : status,
      kAttributes : attributes
    };
  }

// Get more information about a device.
- (NSString *) errorsFor: (NSString *) name
  {
  NSNumber * errors =
    [[[Model model] diskErrors] objectForKey: name];
    
  int errorCount = [errors intValue];
  
  if(errorCount)
    return
      [NSString
        stringWithFormat:
          NSLocalizedString(@" - %@ Drive failure!", NULL),
          TTTLocalizedPluralString(errorCount, @"error", NULL)];

  return NSLocalizedString(@"", NULL);
  }

@end
