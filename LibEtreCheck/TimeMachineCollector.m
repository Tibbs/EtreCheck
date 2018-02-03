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
#import "NSMutableDictionary+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "NSArray+Etresoft.h"
#import "NSString+Etresoft.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"
#import "Volume.h"
#import "NSDate+Etresoft.h"
#import "NSNumber+Etresoft.h"

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
    [self.xml addElement: @"osversiontooold" boolValue: YES];
    
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
    [self.xml addElement: @"tmutilunavailable" boolValue: YES];

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
  
  for(NSString * device in [self.model storageDevices])
    {
    Volume * volume = [[self.model storageDevices] objectForKey: device];
    
    if([Volume isValid: volume])
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
        
      [self.model setBackupExists: YES];
      
      return;
      }
    }

  [self.xml addElement: @"notconfigured" boolValue: YES];

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
  if(![NSDictionary isValid: settings])
    return;
    
  NSArray * excludedVolumeUUIDsArray =
    [settings objectForKey: @"ExcludedVolumeUUIDs"];
  
  if([NSArray isValid: excludedVolumeUUIDsArray])
    for(NSString * UUID in excludedVolumeUUIDsArray)
      {
      [excludedVolumeUUIDs addObject: UUID];
      
      // Get the path for this volume too.
      Volume * volume = [volumes objectForKey: UUID];
      
      if([Volume isValid: volume])
        if(volume.mountpoint.length > 0)
          [excludedPaths addObject: volume.mountpoint];
      }
    
  // Excluded volumes could be referenced via bookmarks.
  [self collectExcludedVolumeBookmarks: settings];
  }

// Excluded volumes could be referenced via bookmarks.
- (void) collectExcludedVolumeBookmarks: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings])
    return;
    
  NSArray * excludedVolumes = [settings objectForKey: @"ExcludedVolumes"];
  
  if([NSArray isValid: excludedVolumes])
    for(NSData * data in excludedVolumes)
      {
      NSURL * url = [self readVolumeBookmark: data];
      
      if(url != nil)
        {
        NSString * path = url.path;
        
        if([NSString isValid: path])
          [excludedPaths addObject: path];
        }
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
  if(![NSDictionary isValid: settings])
    return;
    
  NSArray * excluded = [settings objectForKey: @"ExcludeByPath"];
  
  if([NSArray isValid: excluded])
    for(NSString * path in excluded)
      if([NSString isValid: path])
        [excludedPaths addObject: path];
  }

// Collect destinations indexed by ID.
- (void) collectDestinations: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings])
    return;
    
  NSArray * destinationsArray =
    [settings objectForKey: @"Destinations"];
  
  if([NSArray isValid: destinationsArray])
    for(NSDictionary * destination in destinationsArray)
      {
      NSString * destinationID =
        [destination objectForKey: @"DestinationID"];
      
      if(![NSString isValid: destinationID])
        continue;
        
      NSMutableDictionary * consolidatedDestination =
        [NSMutableDictionary dictionaryWithDictionary: destination];
      
      if(![NSMutableDictionary isValid: consolidatedDestination])
        continue;
        
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
  
  NSString * key = @"tmutil";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/bin/tmutil" arguments: args])
    {
    NSDictionary * destinationinfo  =
      [NSDictionary readPropertyListData: subProcess.standardOutput];
    
    NSArray * destinationList =
      [destinationinfo objectForKey: @"Destinations"];
    
    if([NSArray isValid: destinationList])
      for(NSDictionary * destination in destinationList)
        [self consolidateDestination: destination];
    }
    
  [subProcess release];
  }

// Collect destination snapshots.
- (void) collectDestinationSnapshots: (NSMutableDictionary *) destination
  {
  if(![NSMutableDictionary isValid: destination])
    return;
    
  NSArray * snapshots = [destination objectForKey: @"SnapshotDates"];
  
  NSNumber * snapshotCount;
  NSDate * oldestBackup = nil;
  NSDate * lastBackup = nil;
  
  if([NSArray isValid: snapshots] && (snapshots.count > 0))
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
    
  if(![NSArray isValid: snapshots])
    snapshotCount = @0;
    
  [destination setObject: snapshotCount forKey: kSnapshotcount];
  
  if([NSDate isValid: oldestBackup])
    [destination setObject: oldestBackup forKey: kOldestBackup];
    
  if([NSDate isValid: lastBackup])
    [destination setObject: lastBackup forKey: kLastbackup];
  }

// Consolidate a single destination.
- (void) consolidateDestination: (NSDictionary *) destinationInfo
  {
  if(![NSDictionary isValid: destinationInfo])
    return;
    
  NSString * destinationID = [destinationInfo objectForKey: @"ID"];
  
  if([NSString isValid: destinationID])
    {
    NSMutableDictionary * destination =
      [destinations objectForKey: destinationID];
      
    if([NSMutableDictionary isValid: destination])
      {
      // Put these back where they can be easily referenced.
      NSString * kind = [destinationInfo objectForKey: @"Kind"];
      NSString * name = [destinationInfo objectForKey: @"Name"];
      NSNumber * lastDestination =
        [destinationInfo objectForKey: @"LastDestination"];
      
      if(![NSString isValid: kind])
        kind = ECLocalizedString(@"Unknown");
        
      if(![NSString isValid: name])
        name = destinationID;
        
      if(![NSNumber isValid: lastDestination])
        lastDestination = @0;
        
      [destination setObject: kind forKey: @"Kind"];
      [destination setObject: name forKey: @"Name"];
      [destination setObject: lastDestination forKey: @"LastDestination"];
      }
    }
  }

// Print a volume being backed up.
- (void) printBackedupVolume: (NSString *) UUID
  {
  Volume * volume = [volumes objectForKey: UUID];
  
  if([Volume isValid: volume])
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
  volume.cleanName = [self cleanName: volume.name];
  
  unsigned long long used = volume.size - volume.freeSpace;
  
  NSString * diskSize = [formatter stringFromByteCount: volume.size];
    
  NSString * spaceRequired = [formatter stringFromByteCount: used];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"        %@: Disk size: %@ - Disk used: %@\n"),
          volume.cleanName, diskSize, spaceRequired]];

  [self.xml startElement: @"volume"];
  [self.xml addElement: @"name" value: volume.name]; 
  [self.xml addElement: @"cleanname" value: volume.cleanName]; 

  [self.xml 
    addElement: @"size" 
    valueWithUnits: 
      [formatter stringFromByteCount: volume.size]];
  
  [self.xml 
    addElement: @"free" 
    valueWithUnits: 
      [formatter stringFromByteCount: volume.freeSpace]];
      
  [self.xml 
    addElement: @"used" 
    valueWithUnits: 
      [formatter stringFromByteCount: used]];

  [self.xml endElement: @"volume"];

  minimumBackupSize += used;
  maximumBackupSize += volume.size;
  }

// Is this volume a destination volume?
- (bool) isDestinationVolume: (NSString *) UUID
  {
  for(NSString * destinationID in destinations)
    {
    NSDictionary * destination = [destinations objectForKey: destinationID];
    
    if([NSDictionary isValid: destination])
      {
      NSArray * destinationUUIDs =
        [destination objectForKey: @"DestinationUUIDs"];
    
      if([NSArray isValid: destinationUUIDs])
        for(NSString * destinationUUID in destinationUUIDs)
          if([NSString isValid: destinationUUID])
            if([UUID isEqualToString: destinationUUID])
              return YES;
      }
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
  if(![NSDictionary isValid: settings])
    return;
    
  NSNumber * skipSystemFiles =
    [settings objectForKey: @"SkipSystemFiles"];

  if(![NSNumber isValid: skipSystemFiles])
    return;
    
  bool skip = [skipSystemFiles boolValue];

  [self.xml addElement: @"skipsystemfiles" boolValue: skip];
  
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

// Print the mobile backup setting.
- (void) printMobileBackupsSetting: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings]) 
    return;
    
  NSNumber * mobileBackups =
    [settings objectForKey: @"MobileBackups"];

  if(![NSNumber isValid: mobileBackups])
    return;
    
  bool mobile = [mobileBackups boolValue];

  [self.xml addElement: @"mobilebackups" boolValue: mobile];
  
  [self.result
    appendString: ECLocalizedString(@"    Mobile backups: ")];

  if(mobile)
    [self.result appendString: ECLocalizedString(@"ON\n")];
  else
    [self.result appendString: ECLocalizedString(@"OFF\n")];
  }
  
// Print the autobackup setting.
- (void) printAutoBackupSettings: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings]) 
    return;
    
  NSNumber * autoBackup =
    [settings objectForKey: @"AutoBackup"];

  if(![NSNumber isValid: autoBackup])
    return;
    
  bool backup = [autoBackup boolValue];

  [self.xml addElement: @"autobackup" boolValue: backup];

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

// Print volumes being backed up.
- (void) printBackedupVolumes: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings]) 
    return;
    
  NSMutableSet * backedupVolumeUUIDs = [NSMutableSet set];
  
  // Root always gets backed up.
  // It can be specified directly in settings.
  NSString * root = [settings objectForKey: @"RootVolumeUUID"];

  if([NSString isValid: root])
    [backedupVolumeUUIDs addObject: root];

  // Or it can be in each destination.
  for(NSString * destinationID in destinations)
    {
    NSDictionary * destination = [destinations objectForKey: destinationID];
    
    if([NSDictionary isValid: destination])
      {
      // Root always gets backed up.
      root = [destination objectForKey: @"RootVolumeUUID"];
    
      if([NSString isValid: root])
        [backedupVolumeUUIDs addObject: root];
      }
    }
    
  // Included volumes get backed up.
  NSArray * includedVolumeUUIDs =
    [settings objectForKey: @"IncludedVolumeUUIDs"];

  if([NSArray isValid: includedVolumeUUIDs])
  
    for(NSString * includedVolumeUUID in includedVolumeUUIDs)
      if([NSString isValid: includedVolumeUUID])
        // Unless they are the destination volume.
        if(![self isDestinationVolume: includedVolumeUUID])
          [backedupVolumeUUIDs addObject: includedVolumeUUID];
  
  if([backedupVolumeUUIDs count])
    {
    [self.xml startElement: @"volumesbeingbackedup"];
    
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

    [self.xml endElement: @"volumesbeingbackedup"];
    }
  }

// Print Time Machine destinations.
- (void) printDestinations: (NSDictionary *) settings
  {
  if(![NSDictionary isValid: settings]) 
    return;
    
  [self.result
    appendString: ECLocalizedString(@"    Destinations:\n")];

  bool first = YES;
  
  [self.xml startElement: @"destinations"];
  
  for(NSString * destinationID in destinations)
    {
    if(!first)
      [self.result appendString: @"\n"];
      
    NSDictionary * destination = [destinations objectForKey: destinationID];
    
    if([NSDictionary isValid: destination])
      {
      [self printDestination: destination];
    
      first = NO;
      }
    }

  [self.xml endElement: @"destinations"];
  }

// Print a Time Machine destination.
- (void) printDestination: (NSDictionary *) destination
  {
  if(![NSDictionary isValid: destination])
    return;
    
  [self.xml startElement: @"destination"];
  
  // Print the destination description.
  [self printDestinationDescription: destination];
  
  // Calculate some size values.
  NSNumber * bytesAvailable = [destination objectForKey: @"BytesAvailable"];
  NSNumber * bytesUsed = [destination objectForKey: @"BytesUsed"];

  unsigned long long totalSizeValue = 0;
  
  if([NSNumber isValid: bytesAvailable] && [NSNumber isValid: bytesUsed])
    totalSizeValue =
      [bytesAvailable unsignedLongLongValue] +
      [bytesUsed unsignedLongLongValue];

  // Print the total size.
  [self printTotalSize: totalSizeValue];
  
  // Print snapshot information.
  [self printSnapshotInformation: destination];

  // Print an overall analysis of the Time Machine size differential.
  [self printDestinationSizeAnalysis: totalSizeValue];

  [self.xml endElement: @"destination"];
  }

// Print the destination description.
- (void) printDestinationDescription: (NSDictionary *) destination
  {
  if(![NSDictionary isValid: destination])
    return;
    
  NSString * kind = [destination objectForKey: @"Kind"];
  NSString * name = [destination objectForKey: @"Name"];
  NSNumber * last = [destination objectForKey: @"LastDestination"];

  if(![NSString isValid: name])
    return;
    
  if(![NSString isValid: kind])
    return;

  NSString * cleanName = [self cleanName: name];
  
  NSString * lastused = @"";

  if([NSNumber isValid: last])
    if([last integerValue] == 1)
      lastused = ECLocalizedString(@"(Last used)");

  [self.xml addElement: @"name" value: name];
  [self.xml addElement: @"cleanname" value: cleanName];
  [self.xml addElement: @"type" value: kind];
  [self.xml addElement: @"lastused" boolValue: last.boolValue];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"        %@ [%@] %@\n", cleanName, kind, lastused]];
  }

// Print the total size of the backup.
- (void) printTotalSize: (unsigned long long) totalSizeValue
  {
  NSString * totalSize =
    [formatter stringFromByteCount: totalSizeValue];

  [self.xml addElement: @"size" valueWithUnits: totalSize];
  
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
  if(![NSDictionary isValid: destination])
    return;
    
  NSNumber * count = [destination objectForKey: kSnapshotcount];
  
  if(![NSNumber isValid: count])
    return;
    
  [self.xml addElement: @"count" number: count];
  
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"        Total number of backups: %@ \n"), count]];
  
  NSDate * oldestBackup = [destination objectForKey: kOldestBackup];

  if([NSDate isValid: oldestBackup])
    {
    [self.xml addElement: @"oldestbackup" date: oldestBackup];
    
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(
              @"        Oldest backup: %@ \n"),
            [Utilities dateAsString: oldestBackup]]];
    }
    
  NSDate * lastBackup = [destination objectForKey: kLastbackup];

  if([NSDate isValid: lastBackup] )
    {
    NSDate * then =
      [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 10];
  
    [self.xml addElement: @"lastbackup" date: lastBackup];

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
