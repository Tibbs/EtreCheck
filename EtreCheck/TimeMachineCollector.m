/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "TimeMachineCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "SubProcess.h"

#define kSnapshotcount @"snapshotcount"
#define kLastbackup @"lastbackup"
#define kOldestBackup @"oldestbackup"

// Collect information about Time Machine.
@implementation TimeMachineCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"timemachine"];
  
  if(self)
    {
    formatter = [[ByteCountFormatter alloc] init];
    
    minimumBackupSize = 0;
    maximumBackupSize = 0;
    
    destinations = [[NSMutableDictionary alloc] init];
    
    excludedPaths = [[NSMutableSet alloc] init];
    
    excludedVolumeUUIDs = [[NSMutableSet alloc] init];
    
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
  [excludedVolumeUUIDs release];
  [excludedPaths release];
  [destinations release];
  [formatter release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking Time Machine information", NULL)];

  [self.result appendAttributedString: [self buildTitle]];

  if([[Model model] majorOSVersion] < kMountainLion)
    {
    [self.result
      appendString:
        NSLocalizedString(@"timemachineneedsmountainlion", NULL)
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
    [self.result
      appendString:
        NSLocalizedString(@"timemachineinformationnotavailable", NULL)
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    return;
    }
  
  // Now I can continue.
  [self collectInformation];
  }

// Collect Time Machine information now that I know I should be able to
// find something.
- (void) collectInformation
  {
  NSUserDefaults * defaults = [[NSUserDefaults alloc] init];
  
  NSDictionary * settings =
    [defaults
      persistentDomainForName:
        @"/Library/Preferences/com.apple.TimeMachine.plist"];

  // settings =
  //   [defaults
  //     persistentDomainForName:
  //       @"/tmp/etrecheck/com.apple.TimeMachine.plist"];

  [defaults release];
  
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
      NSLocalizedString(@"    Time Machine not configured!\n\n", NULL)
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
    NSDictionary * volume =
      [[[Model model] volumes] objectForKey: UUID];
    
    NSString * mountPoint = [volume objectForKey: @"mount_point"];
    
    if(mountPoint)
      [excludedPaths addObject: mountPoint];
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
  
  NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle: NSDateFormatterShortStyle];
  [dateFormatter setTimeStyle: NSDateFormatterShortStyle];
  [dateFormatter setTimeZone: [NSTimeZone localTimeZone]];

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
    
  if(!snapshotCount)
    snapshotCount = @0;
    
  [destination setObject: snapshotCount forKey: kSnapshotcount];
  
  if(oldestBackup)
    [destination
      setObject: [dateFormatter stringFromDate: oldestBackup]
      forKey: kOldestBackup];
    
  if(lastBackup)
    [destination
      setObject: [dateFormatter stringFromDate: lastBackup]
      forKey: kLastbackup];
    
  [dateFormatter release];
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
        [destination objectForKey: @"LastDestination"];
      
      if(!kind)
        kind = NSLocalizedString(@"Unknown", NULL);
        
      if(!name)
        name = destinationID;
        
      if(!lastDestination)
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
  NSDictionary * volume =
    [[[Model model] volumes] objectForKey: UUID];
  
  if(!volume)
    return;
    
  NSString * mountPoint = [volume objectForKey: @"mount_point"];
  
  // See if this volume is excluded. If so, skip it.
  if(mountPoint)
    if([excludedPaths containsObject: mountPoint])
      return;

  if([excludedVolumeUUIDs containsObject: UUID])
    return;
    
  [self printVolume: volume];
  }

// Print the volume.
- (void) printVolume: (NSDictionary *) volume
  {
  NSString * name = [volume objectForKey: @"_name"];

  NSString * diskSize = NSLocalizedString(@"Unknown", NULL);
  NSString * spaceRequired = NSLocalizedString(@"Unknown", NULL);

  if(!name)
    name = NSLocalizedString(@"Unknown", NULL);

  NSNumber * size = [volume objectForKey: @"size_in_bytes"];
  NSNumber * freespace = [volume objectForKey: @"free_space_in_bytes"];

  unsigned long long used =
    [size unsignedLongLongValue] - [freespace unsignedLongLongValue];
  
  if(size)
    {
    diskSize =
      [formatter stringFromByteCount: [size unsignedLongLongValue]];
    
    spaceRequired = [formatter stringFromByteCount: used];
    }

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"        %@: Disk size: %@ Disk used: %@\n", NULL),
          name, diskSize, spaceRequired]];

  if(size)
    {
    minimumBackupSize += used;
    maximumBackupSize += [size unsignedLongLongValue];
    }
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

  if(skipSystemFiles)
    {
    bool skip = [skipSystemFiles boolValue];

    [self.result
      appendString: NSLocalizedString(@"    Skip System Files: ", NULL)];

    if(!skip)
      [self.result appendString: NSLocalizedString(@"NO\n", NULL)];
    else
      [self.result
        appendString:
          NSLocalizedString(
            @"YES - System files not being backed up\n", NULL)
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

  if(mobileBackups)
    {
    bool mobile = [mobileBackups boolValue];

    [self.result
      appendString: NSLocalizedString(@"    Mobile backups: ", NULL)];

    if(mobile)
      [self.result appendString: NSLocalizedString(@"ON\n", NULL)];
    else
      [self.result appendString: NSLocalizedString(@"OFF\n", NULL)];
    }
    
    // TODO: Can I get the size of mobile backups?
  }

// Print the autobackup setting.
- (void) printAutoBackupSettings: (NSDictionary *) settings
  {
  NSNumber * autoBackup =
    [settings objectForKey: @"AutoBackup"];

  if(autoBackup)
    {
    bool backup = [autoBackup boolValue];

    [self.result
      appendString: NSLocalizedString(@"    Auto backup: ", NULL)];

    if(backup)
      [self.result appendString: NSLocalizedString(@"YES\n", NULL)];
    else
      [self.result
        appendString:
          NSLocalizedString(@"NO - Auto backup turned off\n", NULL)
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
    [self.result
      appendString:
        NSLocalizedString(@"    Volumes being backed up:\n", NULL)];

    for(NSString * UUID in backedupVolumeUUIDs)
      {
      // See if this disk is excluded. If so, skip it.
      if([excludedVolumeUUIDs containsObject: UUID])
        continue;
        
      [self printBackedupVolume: UUID];
      }
    }
  }

// Print Time Machine destinations.
- (void) printDestinations: (NSDictionary *) settings
  {
  [self.result
    appendString: NSLocalizedString(@"    Destinations:\n", NULL)];

  bool first = YES;
  
  for(NSString * destinationID in destinations)
    {
    if(!first)
      [self.result appendString: @"\n"];
      
    [self printDestination: [destinations objectForKey: destinationID]];
    
    first = NO;
    }
  }

// Print a Time Machine destination.
- (void) printDestination: (NSDictionary *) destination
  {
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
    lastused = NSLocalizedString(@"(Last used)", NULL);

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

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"        Total size: %@ \n", NULL),
          totalSize]];
  }

// Print information about snapshots.
- (void) printSnapshotInformation: (NSDictionary *) destination
  {
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"        Total number of backups: %@ \n", NULL),
          [destination objectForKey: kSnapshotcount]]];
  
  NSDate * oldestBackup = [destination objectForKey: kOldestBackup];
  NSDate * lastBackup = [destination objectForKey: kLastbackup];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"        Oldest backup: %@ \n", NULL),
          oldestBackup ? oldestBackup : @"-"]];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"        Last backup: %@ \n", NULL),
          lastBackup ? lastBackup : @"-"]];
  }

// Print an overall analysis of the Time Machine size differential.
- (void) printDestinationSizeAnalysis: (unsigned long long) totalSizeValue
  {
  [self.result
    appendString:
      NSLocalizedString(@"        Size of backup disk: ", NULL)];

  NSString * analysis = nil;
  
  if(totalSizeValue >= (maximumBackupSize * 3))
    analysis =
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"            Backup size %@ > (Disk size %@ X 3)", NULL),
          [formatter stringFromByteCount: totalSizeValue],
          [formatter stringFromByteCount: maximumBackupSize]];
    
  else if(totalSizeValue >= (minimumBackupSize * 3))
    analysis =
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"            Backup size %@ > (Disk used %@ X 3)", NULL),
          [formatter stringFromByteCount: totalSizeValue],
          [formatter stringFromByteCount: minimumBackupSize]];
    
  else
    analysis =
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"            Backup size %@ < (Disk used %@ X 3)", NULL),
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
            NSLocalizedString(@"Excellent\n%@\n", NULL), analysis]];
    
  else if(totalSizeValue >= (minimumBackupSize * 3))
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"Adequate\n%@\n", NULL), analysis]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            NSLocalizedString(@"Too small\n%@\n", NULL), analysis]
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
            NSLocalizedString(@"    %@ excluded from backup!\n", NULL),
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
