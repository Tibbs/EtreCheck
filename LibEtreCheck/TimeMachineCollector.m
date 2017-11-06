/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "TimeMachineCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "NSDictionary+Etresoft.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"
#import "Volume.h"

#define kSnapshotcount @"snapshotcount"
#define kLastbackup @"lastbackup"
#define kOldestBackup @"oldestbackup"

// Collect information about Time Machine.
@implementation TimeMachineCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"timemachine"];
  
  if(self != nil)
    {
    formatter = [[ByteCountFormatter alloc] init];
    
    minimumBackupSize = 0;
    maximumBackupSize = 0;
    
    destinations = [[NSMutableDictionary alloc] init];
    
    excludedPaths = [[NSMutableSet alloc] init];
    
    excludedVolumeUUIDs = [[NSMutableSet alloc] init];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [excludedVolumeUUIDs release];
  [excludedPaths release];
  [destinations release];
  [formatter release];
  [volumes release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  [self.result appendAttributedString: [self buildTitle]];

  if([[OSVersion shared] major] < kMountainLion)
    {
    [self.model addElement: @"osversiontooold" boolValue: YES];
    
    [self.result
      appendString:
        ECLocalizedString(@"timemachineneedsmountainlion")
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }
    
  bool tmutilExists =
    [[NSFileManager defaultManager] fileExistsAtPath: @"/usr/bin/tmutil"];
  
  if(!tmutilExists)
    {
    [self.model addElement: @"tmutilunavailable" boolValue: YES];

    [self.result
      appendString:
        ECLocalizedString(@"timemachineinformationnotavailable")
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }
  
  // Build a volume map.
  [self buildVolumeMap];
  
  // Now I can continue.
  [self collectInformation];
  }

// Build a mapping of volumeUUIDs to volumes.
- (void) buildVolumeMap
  {
  volumes = [NSMutableDictionary new];
  
  for(NSString * device in [[Model model] storageDevices])
    {
    Volume * volume = [[[Model model] storageDevices] objectForKey: device];
    
    if([volume respondsToSelector: @selector(isVolume)])
      if(volume.UUID.length > 0)
        [volumes setObject: volume forKey: volume.UUID];
    }
  }
  
// Collect Time Machine information now that I know I should be able to
// find something.
- (void) collectInformation
  {
  NSDictionary * settings =
    [NSDictionary
      readPropertyList:
        @"/Library/Preferences/com.apple.TimeMachine.plist"];

  if(settings)
    {
    // Collect any excluded volumes.
    [self collectExcludedVolumes: settings];
    
    // Collect any excluded paths.
    [self collectExcludedPaths: settings];
      
    // Collect destinations by ID.
    [self collectDestinations: settings];
    
    if([destinations count])
      {
      // Print the information.
      [self printInformation: settings];
      
      // Check for excluded items.
      [self checkExclusions];

      [self.result appendCR];
        
      [[Model model] setBackupExists: YES];
      
      return;
      }
    }

  [self.result
    appendString:
      ECLocalizedString(@"    Time Machine not configured!\n\n")
    attributes:
      [NSDictionary
        dictionaryWithObjectsAndKeys:
          [NSColor redColor], NSForegroundColorAttributeName, nil]];
  }

// Collect excluded volumes.
- (void) collectExcludedVolumes: (NSDictionary *) settings
  {
  NSArray * excludedVolumeUUIDsArray =
    [settings objectForKey: @"ExcludedVolumeUUIDs"];
  
  for(NSString * UUID in excludedVolumeUUIDsArray)
    {
    [excludedVolumeUUIDs addObject: UUID];
    
    // Get the path for this volume too.
    Volume * volume = [volumes objectForKey: UUID];
    
    if(volume.mountpoint.length > 0)
      [excludedPaths addObject: volume.mountpoint];
    }
    
  // Excluded volumes could be referenced via bookmarks.
  [self collectExcludedVolumeBookmarks: settings];
  }

// Excluded volumes could be referenced via bookmarks.
- (void) collectExcludedVolumeBookmarks: (NSDictionary *) settings
  {
  NSArray * excludedVolumes = [settings objectForKey: @"ExcludedVolumes"];
  
  for(NSData * data in excludedVolumes)
    {
    NSURL * url = [self readVolumeBookmark: data];
    
    if(url)
      [excludedPaths addObject: [url path]];
    }
  }

// Read a volume bookmark into a URL.
- (NSURL *) readVolumeBookmark: (NSData *) data
  {
  BOOL isStale = NO;
  
  NSURLBookmarkResolutionOptions options =
    NSURLBookmarkResolutionWithoutMounting |
    NSURLBookmarkResolutionWithoutUI;
  
  return
    [NSURL
      URLByResolvingBookmarkData: data
      options: options
      relativeToURL: nil
      bookmarkDataIsStale: & isStale
      error: NULL];
  }

// Collect excluded paths.
- (void) collectExcludedPaths: (NSDictionary *) settings
  {
  NSArray * excluded = [settings objectForKey: @"ExcludeByPath"];
  
  for(NSString * path in excluded)
    [excludedPaths addObject: path];
  }

// Collect destinations indexed by ID.
- (void) collectDestinations: (NSDictionary *) settings
  {
  NSArray * destinationsArray =
    [settings objectForKey: @"Destinations"];
  
  for(NSDictionary * destination in destinationsArray)
    {
    NSString * destinationID =
      [destination objectForKey: @"DestinationID"];
    
    NSMutableDictionary * consolidatedDestination =
      [NSMutableDictionary dictionaryWithDictionary: destination];
    
    // Collect destination snapshots.
    [self collectDestinationSnapshots: consolidatedDestination];
    
    // Save the new, consolidated destination.
    [destinations
      setObject: consolidatedDestination forKey: destinationID];
    }
    
  // Consolidation destination info between defaults and tmutil.
  [self consolidateDestinationInfo];
  }

// Consolidation destination info between defaults and tmutil.
- (void) consolidateDestinationInfo
  {
  // Now consolidate destination information.
  NSArray * args =
    @[
      @"destinationinfo",
      @"-X"
    ];
  
  // result = [NSData dataWithContentsOfFile: @"/tmp/etrecheck/tmutil.xml"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/tmutil" arguments: args])
    {
    NSDictionary * destinationinfo  =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
    
    NSArray * destinationList =
      [destinationinfo objectForKey: @"Destinations"];
    
    for(NSDictionary * destination in destinationList)
      [self consolidateDestination: destination];
    }
    
  [subProcess release];
  }

// Collect destination snapshots.
- (void) collectDestinationSnapshots: (NSMutableDictionary *) destination
  {
  NSArray * snapshots = [destination objectForKey: @"SnapshotDates"];
  
  NSNumber * snapshotCount;
  NSDate * oldestBackup = nil;
  NSDate * lastBackup = nil;
  
  if([snapshots count])
    {
    snapshotCount =
      [NSNumber numberWithUnsignedInteger: [snapshots count]];
    
    oldestBackup = [snapshots objectAtIndex: 0];
    lastBackup = [snapshots lastObject];
    }
  else
    {
    snapshotCount = [destination objectForKey: @"SnapshotCount"];

    oldestBackup =
      [destination objectForKey: @"kCSBackupdOldestCompleteSnapshotDate"];
    lastBackup = [destination objectForKey: @"BACKUP_COMPLETED_DATE"];
    }
    
  if(snapshotCount == nil)
    snapshotCount = @0;
    
  [destination setObject: snapshotCount forKey: kSnapshotcount];
  
  if(oldestBackup != nil)
    [destination setObject: oldestBackup forKey: kOldestBackup];
    
  if(lastBackup != nil)
    [destination setObject: lastBackup forKey: kLastbackup];
  }

// Consolidate a single destination.
- (void) consolidateDestination: (NSDictionary *) destinationInfo
  {
  NSString * destinationID = [destinationInfo objectForKey: @"ID"];
  
  if(destinationID)
    {
    NSMutableDictionary * destination =
      [destinations objectForKey: destinationID];
      
    if(destination)
      {
      // Put these back where they can be easily referenced.
      NSString * kind = [destinationInfo objectForKey: @"Kind"];
      NSString * name = [destinationInfo objectForKey: @"Name"];
      NSNumber * lastDestination =
        [destinationInfo objectForKey: @"LastDestination"];
      
      if(kind.length == 0)
        kind = ECLocalizedString(@"Unknown");
        
      if(name.length == 0)
        name = destinationID;
        
      if(lastDestination == nil)
        lastDestination = @0;
        
      [destination setObject: kind forKey: @"Kind"];
      [destination setObject: name forKey: @"Name"];
      [destination
        setObject: lastDestination forKey: @"LastDestination"];
      }
    }
  }

// Print a volume being backed up.
- (void) printBackedupVolume: (NSString *) UUID
  {
  Volume * volume = [volumes objectForKey: UUID];
  
  if(volume != nil)
    {
    // See if this volume is excluded. If so, skip it.
    if(volume.mountpoint.length > 0)
      if([excludedPaths containsObject: volume.mountpoint])
        return;

    if([excludedVolumeUUIDs containsObject: UUID])
      return;
    
    [self printVolume: volume];
    }
  }

// Print the volume.
- (void) printVolume: (Volume *) volume
  {
  NSString * volumeName = [Utilities cleanPath: volume.name];
  
  NSString * diskSize = ECLocalizedString(@"Unknown");

  unsigned long long used = volume.size - volume.freeSpace;
  
  diskSize = [formatter stringFromByteCount: volume.size];
    
  NSString * spaceRequired = [formatter stringFromByteCount: used];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"        %@: Disk size: %@ - Disk used: %@\n"),
          volumeName, diskSize, spaceRequired]];

  [self.model startElement: @"volume"];
  [self.model addElement: @"name" value: volume.name]; 

  [self.model 
    addElement: @"size" 
    valueWithUnits: 
      [formatter stringFromByteCount: volume.size]];
  
  [self.model 
    addElement: @"free" 
    valueWithUnits: 
      [formatter stringFromByteCount: volume.freeSpace]];
  [self.model 
    addElement: @"used" 
    valueWithUnits: 
      [formatter stringFromByteCount: used]];

  [self.model endElement: @"volume"];

  minimumBackupSize += used;
  maximumBackupSize += volume.size;
  }

// Is this volume a destination volume?
- (bool) isDestinationVolume: (NSString *) UUID
  {
  for(NSString * destinationID in destinations)
    {
    NSDictionary * destination = [destinations objectForKey: destinationID];
    
    NSArray * destinationUUIDs =
      [destination objectForKey: @"DestinationUUIDs"];
    
    for(NSString * destinationUUID in destinationUUIDs)
      if([UUID isEqualToString: destinationUUID])
        return YES;
    }
    
  return NO;
  }

// Print the core Time Machine information.
- (void) printInformation: (NSDictionary *) settings
  {
  // Print some time machine settings.
  [self printSkipSystemFilesSetting: settings];
  [self printMobileBackupsSetting: settings];
  [self printAutoBackupSettings: settings];
  
  // Print volumes being backed up.
  [self printBackedupVolumes: settings];
    
  // Print destinations.
  [self printDestinations: settings];
  }

// Print the skip system files setting.
- (void) printSkipSystemFilesSetting: (NSDictionary *) settings
  {
  NSNumber * skipSystemFiles =
    [settings objectForKey: @"SkipSystemFiles"];

  [self.model 
    addElement: @"skipsystemfiles" boolValue: [skipSystemFiles boolValue]];
  
  if(skipSystemFiles != nil)
    {
    bool skip = [skipSystemFiles boolValue];

    [self.result
      appendString: ECLocalizedString(@"    Skip System Files: ")];

    if(!skip)
      [self.result appendString: ECLocalizedString(@"NO\n")];
    else
      [self.result
        appendString:
          ECLocalizedString(
            @"YES - System files not being backed up\n")
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor],
              NSForegroundColorAttributeName, nil]];
    }
  }

// Print the mobile backup setting.
- (void) printMobileBackupsSetting: (NSDictionary *) settings
  {
  NSNumber * mobileBackups =
    [settings objectForKey: @"MobileBackups"];

  [self.model 
    addElement: @"mobilebackups" boolValue: [mobileBackups boolValue]];
  
  if(mobileBackups != nil)
    {
    bool mobile = [mobileBackups boolValue];

    [self.result
      appendString: ECLocalizedString(@"    Mobile backups: ")];

    if(mobile)
      [self.result appendString: ECLocalizedString(@"ON\n")];
    else
      [self.result appendString: ECLocalizedString(@"OFF\n")];
    }
    
    // TODO: Can I get the size of mobile backups?
  }

// Print the autobackup setting.
- (void) printAutoBackupSettings: (NSDictionary *) settings
  {
  NSNumber * autoBackup =
    [settings objectForKey: @"AutoBackup"];

  [self.model addElement: @"autobackup" boolValue: [autoBackup boolValue]];

  if(autoBackup != nil)
    {
    bool backup = [autoBackup boolValue];

    [self.result
      appendString: ECLocalizedString(@"    Auto backup: ")];

    if(backup)
      [self.result appendString: ECLocalizedString(@"YES\n")];
    else
      [self.result
        appendString:
          ECLocalizedString(@"NO - Auto backup turned off\n")
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor],
              NSForegroundColorAttributeName, nil]];
    }
  }

// Print volumes being backed up.
- (void) printBackedupVolumes: (NSDictionary *) settings
  {
  NSMutableSet * backedupVolumeUUIDs = [NSMutableSet set];
  
  // Root always gets backed up.
  // It can be specified directly in settings.
  NSString * root = [settings objectForKey: @"RootVolumeUUID"];

  if(root)
    [backedupVolumeUUIDs addObject: root];

  // Or it can be in each destination.
  for(NSString * destinationID in destinations)
    {
    NSDictionary * destination = [destinations objectForKey: destinationID];
    
    // Root always gets backed up.
    root = [destination objectForKey: @"RootVolumeUUID"];
  
    if(root)
      [backedupVolumeUUIDs addObject: root];
    }
    
  // Included volumes get backed up.
  NSArray * includedVolumeUUIDs =
    [settings objectForKey: @"IncludedVolumeUUIDs"];

  if(includedVolumeUUIDs)
  
    for(NSString * includedVolumeUUID in includedVolumeUUIDs)
      
      // Unless they are the destination volume.
      if(![self isDestinationVolume: includedVolumeUUID])
        [backedupVolumeUUIDs addObject: includedVolumeUUID];
  
  if([backedupVolumeUUIDs count])
    {
    [self.model startElement: @"volumesbeingbackedup"];
    
    [self.result
      appendString:
        ECLocalizedString(@"    Volumes being backed up:\n")];

    for(NSString * UUID in backedupVolumeUUIDs)
      {
      // See if this disk is excluded. If so, skip it.
      if([excludedVolumeUUIDs containsObject: UUID])
        continue;
        
      [self printBackedupVolume: UUID];
      }

    [self.model endElement: @"volumesbeingbackedup"];
    }
  }

// Print Time Machine destinations.
- (void) printDestinations: (NSDictionary *) settings
  {
  [self.result
    appendString: ECLocalizedString(@"    Destinations:\n")];

  bool first = YES;
  
  [self.model startElement: @"destinations"];
  
  for(NSString * destinationID in destinations)
    {
    if(!first)
      [self.result appendString: @"\n"];
      
    [self printDestination: [destinations objectForKey: destinationID]];
    
    first = NO;
    }

  [self.model endElement: @"destinations"];
  }

// Print a Time Machine destination.
- (void) printDestination: (NSDictionary *) destination
  {
  [self.model startElement: @"destination"];
  
  // Print the destination description.
  [self printDestinationDescription: destination];
  
  // Calculate some size values.
  NSNumber * bytesAvailable = [destination objectForKey: @"BytesAvailable"];
  NSNumber * bytesUsed = [destination objectForKey: @"BytesUsed"];

  unsigned long long totalSizeValue =
    [bytesAvailable unsignedLongLongValue] +
    [bytesUsed unsignedLongLongValue];

  // Print the total size.
  [self printTotalSize: totalSizeValue];
  
  // Print snapshot information.
  [self printSnapshotInformation: destination];

  // Print an overall analysis of the Time Machine size differential.
  [self printDestinationSizeAnalysis: totalSizeValue];

  [self.model endElement: @"destination"];
  }

// Print the destination description.
- (void) printDestinationDescription: (NSDictionary *) destination
  {
  NSString * kind = [destination objectForKey: @"Kind"];
  NSString * name = [destination objectForKey: @"Name"];
  NSNumber * last = [destination objectForKey: @"LastDestination"];

  NSString * safeName = [Utilities cleanPath: name];
  
  if([safeName length] == 0)
    safeName = name;
    
  NSString * lastused = @"";

  if([last integerValue] == 1)
    lastused = ECLocalizedString(@"(Last used)");

  [self.model addElement: @"name" value: safeName];
  [self.model addElement: @"type" value: kind];
  [self.model addElement: @"lastused" boolValue: last.boolValue];
  
  if([last boolValue])
    [self.model addElement: @"lastused" boolValue: [last boolValue]];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"        %@ [%@] %@\n", safeName, kind, lastused]];
  }

// Print the total size of the backup.
- (void) printTotalSize: (unsigned long long) totalSizeValue
  {
  NSString * totalSize =
    [formatter stringFromByteCount: totalSizeValue];

  [self.model addElement: @"size" valueWithUnits: totalSize];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(@"        Total size: %@ \n"),
          totalSize]];
  }

// Print information about snapshots.
- (void) printSnapshotInformation: (NSDictionary *) destination
  {
  NSNumber * count = [destination objectForKey: kSnapshotcount];
  
  [self.model addElement: @"count" number: count];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"        Total number of backups: %@ \n"), count]];
  
  NSDate * oldestBackup = [destination objectForKey: kOldestBackup];

  if(oldestBackup != nil)
    {
    [self.model addElement: @"oldestbackup" date: oldestBackup];
    
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(
              @"        Oldest backup: %@ \n"),
            [Utilities dateAsString: oldestBackup]]];
    }
    
  NSDate * lastBackup = [destination objectForKey: kLastbackup];

  if(oldestBackup != nil)
    {
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 10];
  
    [self.model addElement: @"lastbackup" date: lastBackup];

    if([lastBackup compare: then] != NSOrderedDescending)
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(@"        Last backup: %@ \n"),
              [Utilities dateAsString: lastBackup]]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(@"        Last backup: %@ \n"),
              [Utilities dateAsString: lastBackup]]];
    }
  }

// Print an overall analysis of the Time Machine size differential.
- (void) printDestinationSizeAnalysis: (unsigned long long) totalSizeValue
  {
  [self.result
    appendString:
      ECLocalizedString(@"        Size of backup disk: ")];

  NSString * analysis = nil;
  
  if(totalSizeValue >= (maximumBackupSize * 3))
    analysis =
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"            Backup size %@ > (Disk size %@ X 3)"),
          [formatter stringFromByteCount: totalSizeValue],
          [formatter stringFromByteCount: maximumBackupSize]];
    
  else if(totalSizeValue >= (minimumBackupSize * 3))
    analysis =
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"            Backup size %@ > (Disk used %@ X 3)"),
          [formatter stringFromByteCount: totalSizeValue],
          [formatter stringFromByteCount: minimumBackupSize]];
    
  else
    analysis =
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"            Backup size %@ < (Disk used %@ X 3)"),
          [formatter stringFromByteCount: totalSizeValue],
          [formatter stringFromByteCount: minimumBackupSize]];
  
  // Print the size analysis result.
  [self printSizeAnalysis: analysis forSize: totalSizeValue];
  }

// Print the size analysis result.
- (void) printSizeAnalysis: (NSString *) analysis
  forSize: (unsigned long long) totalSizeValue
  {
  if(totalSizeValue >= (maximumBackupSize * 3))
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"Excellent\n%@\n"), analysis]];
    
  else if(totalSizeValue >= (minimumBackupSize * 3))
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"Adequate\n%@\n"), analysis]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"Too small\n%@\n"), analysis]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
  }

// Check for important system paths that are excluded.
- (void) checkExclusions
  {
  NSArray * importantPaths =
    @[
      @"/Applications",
      @"/System",
      @"/bin",
      @"/Library",
      @"/Users",
      @"/usr",
      @"/sbin",
      @"/private"
    ];

  NSCountedSet * excludedItems =
    [self collectImportantExclusions: importantPaths];
  
  for(NSString * importantPath in excludedItems)
    if([excludedItems countForObject: importantPath] == 3)
      {
      NSString * exclusion =
        [NSString
          stringWithFormat:
            ECLocalizedString(@"    %@ excluded from backup!\n"),
            importantPath];

      [self.result
        appendString: exclusion
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
      }
  }

// Return the number of times an important path is excluded.
- (NSCountedSet *) collectImportantExclusions: (NSArray *) importantPaths
  {
  NSCountedSet * excludedItems = [NSCountedSet set];
  
  // These can show up as excluded at any time. Check three 3 times.
  for(int i = 0; i < 3; ++i)
    {
    bool exclusions = NO;
    
    for(NSString * importantPath in importantPaths)
      {
      NSURL * url = [NSURL fileURLWithPath: importantPath];

      bool excluded = CSBackupIsItemExcluded((CFURLRef)url, NULL);
      
      if(excluded)
        {
        [excludedItems addObject: importantPath];
        exclusions = YES;
        }
      }
    
    if(exclusions)
      sleep(5);
    else
      break;
    }
    
  return excludedItems;
  }

@end
