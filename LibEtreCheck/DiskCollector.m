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
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"

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
        ECLocalizedString(@"    Disk information not found!\n")
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
    [self.model startElement: @"drives"];
    
    for(NSDictionary * disk in disks)
      {
      [self.model startElement: @"drive"];
      
      NSString * diskName = [disk objectForKey: @"_name"];
      NSString * diskDevice = [disk objectForKey: @"bsd_name"];
      NSString * diskSize = [disk objectForKey: @"size"];
      NSString * UUID = [disk objectForKey: @"volume_uuid"];
      NSString * medium = [disk objectForKey: @"spsata_medium_type"];
      NSString * TRIM = [disk objectForKey: @"spsata_trim_support"];
      
      if([TRIM length] == 0)
        TRIM = [disk objectForKey: @"spnvme_trim_support"];
        
      NSString * TRIMString =
        [NSString
          stringWithFormat: 
            @" - TRIM: %@", 
            ECLocalizedStringFromTable(TRIM, @"System")];
      
      NSString * info =
        [NSString
          stringWithFormat:
            @"(%@%@)",
            medium
              ? ECLocalizedStringFromTable(medium, @"System")
              : @"",
            ([medium isEqualToString: @"Solid State"] && [TRIM length])
              ? TRIMString
              : @""];
        
      if([diskDevice length] == 0)
        diskDevice = @"";
        
      [self.model addElement: @"model" value: diskName];
      [self.model addElement: @"device" value: diskDevice];
      [self.model addElement: @"size" valueWithUnits: diskSize];
      //[self.model addElement: @"UUID" value: UUID];

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
        
      [self.model addElement: @"type" value: medium];
      
      if([medium isEqualToString: @"Solid State"])
        [self.model 
          addElement: @"TRIM" boolValue: [TRIM isEqualToString: @"Yes"]];

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
      
      [self.model endElement: @"drive"];
      }

    [self.model endElement: @"drives"];
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
    
  if(self.simulating)
    smart_status = @"Simulated";
    
  bool smart_not_supported =
    [smart_status isEqualToString: @"Not Supported"];
  
  bool smart_verified =
    [smart_status isEqualToString: @"Verified"];

  if(!smart_not_supported && !smart_verified)
    {
    [self.model addElement: @"smartstatus" value: smart_status];
  
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"%@S.M.A.R.T. Status: %@\n"),
            indent, smart_status]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
    
  NSString * device = [disk objectForKey: @"bsd_name"];
  
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  if(!smart_not_supported)
    {
    [urlString
      appendString:
        [NSString stringWithFormat:
          ECLocalizedString(@"%@[Show SMART report]"), indent]
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
    
  NSString * cleanName = 
    [volumeName length] > 0 ? [Utilities cleanPath: volumeName] : @"";
    
  [self.model addElement: @"name" value: volumeName];
  [self.model addElement: @"device" value: volumeDevice];
  [self.model addElement: @"filesystem" value: fileSystem];
  [self.model addElement: @"mountpoint" value: volumeMountPoint];
  
  if(!volumeMountPoint)
    volumeMountPoint = ECLocalizedString(@"<not mounted>");
    
  if(UUID)
    {
    //[self.model addElement: @"UUID" value: UUID];
    
    [self.volumes setObject: volume forKey: UUID];
    }
    
  [self.model addElement: @"size" valueWithUnits: volumeSize];
  [self.model addElement: @"free" valueWithUnits: volumeFree];

  NSDictionary * stats = [self volumeStats: volume];

  NSDictionary * attributes = [stats objectForKey: kAttributes];
  
  NSNumber * errorCount =
    [[[Model model] diskErrors] objectForKey: volumeDevice];

  if(self.simulating)
    errorCount = [NSNumber numberWithInt: 4];
    
  NSString * errors = [self errorsFor: errorCount];
  
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
        stringWithFormat: 
          @" - %@", 
          ECLocalizedStringFromTable(fileSystem, @"System")];
    
  if([fileSystemName length] > 0)
    {
    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"%@%@ (%@%@) %@ %@: %@ %@%@\n"),
          indent,
          cleanName,
          volumeDevice,
          fileSystemName,
          volumeMountPoint,
          [stats objectForKey: kDiskType],
          [volumeSize length] > 0
            ? volumeSize 
            : @"",
          [volumeFree length] > 0
            ? [NSString
                stringWithFormat:
                ECLocalizedString(@"(%@ free)"), volumeFree] 
            : @"",
          status];
      
    [[[Model model] physicalVolumes] addObject: volumeDevice];
    }
  else
    volumeInfo =
      [NSString
        stringWithFormat:
          ECLocalizedString(@"%@(%@) %@ %@: %@%@\n"),
          indent,
          volumeDevice,
          volumeMountPoint,
          [stats objectForKey: kDiskType],
          volumeSize,
          status];
    
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
  
  if(sizeInBytes != nil)
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
    size = ECLocalizedString(@"Size unknown");
    
  return size;
  }

// Get the free space on the volume.
- (NSString *) volumeFreeSpace: (NSDictionary *) volume
  {
  NSString * volumeFree = nil;
  
  NSNumber * freeSpaceInBytes =
    [volume objectForKey: @"free_space_in_bytes"];
  
  if(freeSpaceInBytes != nil)
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
  
  if(self.simulating)
    free = 12;
    
  NSString * type = @"";
  NSString * status = @"";
  NSDictionary * attributes = @{};
  
  if([mountPoint isEqualToString: @"/"])
    {
    type = ECLocalizedString(@"Startup");

    unsigned long long GB = 1024 * 1024 * 1024;

    if(free < (GB * 15))
      status = ECLocalizedString(@" (Low!)");
    }
  
  else if([name isEqualToString: @"Recovery HD"])
    type = ECLocalizedString(@"Recovery");
    
  else if([name isEqualToString: @"EFI"])
    type = ECLocalizedString(@"EFI");
    
  else if([name isEqualToString: @"KernelCoreDump"])
    type = ECLocalizedString(@"KernelCoreDump");

  else if([filesystem length] == 0)
    {
    if([iocontent hasPrefix: @"Apple_"])
      type = [iocontent substringFromIndex: 6];
    
    if([type isEqualToString: @"APFS"])
      type = ECLocalizedString(@"APFS Container");
    else if([type isEqualToString: @"CoreStorage"])
      type = ECLocalizedString(@"CoreStorage Container");
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
- (NSString *) errorsFor: (NSNumber *) errors
  {
  int errorCount = [errors intValue];
  
  if(errorCount)
    return
      [NSString
        stringWithFormat:
          ECLocalizedString(@" - %@ Drive failure!"),
          ECLocalizedPluralString(errorCount, @"error")];

  return @"";
  }

@end
