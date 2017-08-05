/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "Model.h"
#import "DiagnosticEvent.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "NSString+Etresoft.h"
#import "XMLBuilder.h"

@implementation Model

@synthesize majorOSVersion = myMajorOSVersion;
@synthesize minorOSVersion = myMinorOSVersion;
@synthesize OSBuild = myOSBuild;
@synthesize OSVersion = myOSVersion;
@synthesize volumes = myVolumes;
@synthesize physicalVolumes = myPhysicalVolumes;
@synthesize diskErrors = myDiskErrors;
@synthesize gpuErrors = myGPUErrors;
@synthesize logEntries = myLogEntries;
@synthesize applications = myApplications;
@synthesize physicalRAM = myPhysicalRAM;
@synthesize machineIcon = myMachineIcon;
@synthesize model = myModel;
@synthesize serialCode = mySerialCode;
@synthesize diagnosticEvents = myDiagnosticEvents;
@synthesize launchdFiles = myLaunchdFiles;
@synthesize processes = myProcesses;
@synthesize possibleAdwareFound = myPossibleAdwareFound;
@synthesize adwareFiles = myAdwareFiles;
@synthesize potentialAdwareTrioFiles = myPotentialAdwareTrioFiles;
@synthesize adwareExtensions = myAdwareExtensions;
@synthesize whitelistFiles = myWhitelistFiles;
@synthesize whitelistPrefixes = myWhitelistPrefixes;
@synthesize blacklistFiles = myBlacklistFiles;
@synthesize blacklistMatches = myBlacklistMatches;
@synthesize blacklistSuffixes = myBlacklistSuffixes;
@synthesize computerName = myComputerName;
@synthesize hostName = myHostName;
@dynamic unknownFilesFound;
@synthesize terminatedTasks = myTerminatedTasks;
@synthesize seriousProblems = mySeriousProblems;
@synthesize backupExists = myBackupExists;
@synthesize ignoreKnownAppleFailures = myIgnoreKnownAppleFailures;
@synthesize showSignatureFailures = myShowSignatureFailures;
@synthesize hideAppleTasks = myHideAppleTasks;
@synthesize oldEtreCheckVersion = myOldEtreCheckVersion;
@synthesize verifiedEtreCheckVersion = myVerifiedEtreCheckVersion;
@synthesize appleSoftware = myAppleSoftware;
@synthesize appleLaunchd = myAppleLaunchd;
@synthesize appleLaunchdByLabel = myAppleLaunchdByLabel;
@synthesize unknownFiles = myUnknownFiles;
@synthesize legitimateStrings = myLegitimateStrings;
@synthesize sip = mySIP;
@synthesize cleanupRequired = myCleanupRequired;
@synthesize pathsForUUIDs = myPathsForUUIDs;
@synthesize notificationSPAMs = myNotificationSPAMs;
@synthesize xml = myXMLBuilder;
@synthesize header = myXMLHeader;

- (NSDictionary *) adwareLaunchdFiles
  {
  NSMutableDictionary * files = [NSMutableDictionary dictionary];
  
  for(NSString * path in self.launchdFiles)
    {
    NSDictionary * info = [self.launchdFiles objectForKey: path];
    
    if([[info objectForKey: kAdware] boolValue])
      [files setObject: info forKey: path];
    }
    
  return [[files copy] autorelease];
  }

- (bool) possibleAdwareFound
  {
  if([self.adwareLaunchdFiles count] > 0)
    return YES;
    
  if([self.adwareFiles count] > 0)
    return YES;
    
  if([self.unknownLaunchdFiles count] > 0)
    return YES;

  if([self.unknownFiles count] > 0)
    return YES;

  return NO;
  }

- (NSDictionary *) orphanLaunchdFiles
  {
  NSMutableDictionary * files = [NSMutableDictionary dictionary];
  
  for(NSString * path in self.launchdFiles)
    {
    NSDictionary * info = [self.launchdFiles objectForKey: path];
    
    // Skip Apple files.
    if([[info objectForKey: kApple] boolValue])
      continue;
      
    // Check for a missing executable.
    NSString * signature = [info objectForKey: kSignature];
    
    if([signature isEqualToString: kExecutableMissing])
      [files setObject: info forKey: path];
    }
    
  return [[files copy] autorelease];
  }

- (NSDictionary *) unknownLaunchdFiles
  {
  NSMutableDictionary * files = [NSMutableDictionary dictionary];
  
  for(NSString * path in self.launchdFiles)
    {
    NSDictionary * info = [self.launchdFiles objectForKey: path];
    
    if([[info objectForKey: kUnknown] boolValue])
      {
      // Check for a valid executable.
      NSString * signature = [info objectForKey: kSignature];
      
      if([signature isEqualToString: kSignatureApple])
        continue;

      if([signature isEqualToString: kSignatureValid])
        continue;

      // This will be handled by the new clean up option.
      if([signature isEqualToString: kExecutableMissing])
        continue;
        
      [files setObject: info forKey: path];
      }
    }
    
  return [[files copy] autorelease];
  }

- (bool) unknownFilesFound
  {
  return [self.unknownFiles count] > 0;
  }
  
// Return the singeton of shared values.
+ (Model *) model
  {
  static Model * model = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      model = [[Model alloc] init];
    });
    
  return model;
  }

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myLegitimateStrings = [NSMutableSet new];
    myUnknownFiles = [NSMutableArray new];
    myLaunchdFiles = [NSMutableDictionary new];
    myVolumes = [NSMutableDictionary new];
    myPhysicalVolumes = [NSMutableSet new];
    myDiskErrors = [NSMutableDictionary new];
    myDiagnosticEvents = [NSMutableDictionary new];
    myAdwareFiles = [NSMutableDictionary new];
    myProcesses = [NSMutableSet new];
    myPotentialAdwareTrioFiles = [NSMutableDictionary new];
    myTerminatedTasks = [NSMutableArray new];
    mySeriousProblems = [NSMutableSet new];
    myIgnoreKnownAppleFailures = YES;
    myShowSignatureFailures = NO;
    myHideAppleTasks = YES;
    myWhitelistFiles = [NSMutableSet new];
    myWhitelistPrefixes = [NSMutableSet new];
    myBlacklistFiles = [NSMutableSet new];
    myBlacklistSuffixes = [NSMutableSet new];
    myBlacklistMatches = [NSMutableSet new];
    myPathsForUUIDs = [NSMutableDictionary new];
    myNotificationSPAMs = [NSMutableDictionary new];
    myXMLBuilder = [XMLBuilder new];
    myXMLHeader = [XMLBuilder new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myXMLHeader release];
  [myXMLBuilder release];
  [myNotificationSPAMs release];
  [myPathsForUUIDs release];
  [mySerialCode release];
  [myModel release];
  [myLogEntries release];
  [myHostName release];
  [myGPUErrors release];
  [myPhysicalVolumes release];
  [myComputerName release];
  [myAppleSoftware release];
  [myAppleLaunchd release];
  [myAdwareExtensions release];
  [myLegitimateStrings release];
  [myUnknownFiles release];
  [myAdwareFiles release];
  [myBlacklistSuffixes release];
  [myBlacklistMatches release];
  [myBlacklistFiles release];
  [myWhitelistFiles release];
  [myWhitelistPrefixes release];
  
  self.appleLaunchdByLabel = nil;
  self.seriousProblems = nil;
  self.terminatedTasks = nil;
  self.potentialAdwareTrioFiles = nil;
  self.processes = nil;
  self.launchdFiles = nil;
  self.diagnosticEvents = nil;
  self.diskErrors = nil;
  self.volumes = nil;
  self.applications = nil;
  self.machineIcon = nil;
  self.processes = nil;
  self.OSVersion = nil;
  self.OSBuild = nil;
  
  [super dealloc];
  }

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name
  {
  if(!name)
    return NO;
  
  __block bool matching = NO;
  __block NSMutableString * result = [NSMutableString string];
  
  [[self logEntries]
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([event.details rangeOfString: name].location != NSNotFound)
          matching = YES;

        else
          {
          NSRange found =
            [event.details
              rangeOfCharacterFromSet:
                [NSCharacterSet whitespaceCharacterSet]];
            
          if(matching && (found.location == 0))
            matching = YES;
          else
            matching = NO;
          }
        
        if(matching)
          {
          [result appendString: event.details];
          [result appendString: @"\n"];
          }
        }];
    
  if([result length])
    {
    DiagnosticEvent * event = [DiagnosticEvent new];

    event.type = kLog;
    event.name = name;
    event.details = result;
      
    [[[Model model] diagnosticEvents] setObject: event forKey: name];
    
    [event release];

    return YES;
    }

  return NO;
  }

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date
  {
  NSDate * startDate = [date dateByAddingTimeInterval: -60*5];
  NSDate * endDate = [date dateByAddingTimeInterval: 60*5];
  
  NSArray * lines = [[Model model] logEntries];
  
  __block NSMutableString * result = [NSMutableString string];
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        DiagnosticEvent * event = (DiagnosticEvent *)obj;
        
        if([endDate compare: event.date] == NSOrderedAscending)
          *stop = YES;
        
        else if([startDate compare: event.date] == NSOrderedAscending)
          if([event.details length])
            {
            [result appendString: event.details];
            [result appendString: @"\n"];
            }
        }];
    
  return result;
  }

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://detail/%@", query];
  
  [urlString
    appendString: NSLocalizedString(@"[Details]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Create an open URL for a file.
- (NSAttributedString *) getOpenURLFor: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  // Use UUIDs since these are sometimes printed in plain text.
  NSString * UUID = [self createUUIDForPath: path];
  
  NSString * url =
    [NSString stringWithFormat: @"etrecheck://open/%@", UUID];
  
  [urlString
    appendString: NSLocalizedString(@"[Open]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Is this file an adware file?
- (bool) checkForAdware: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  if([path length] == 0)
    return NO;
    
  if([self isWhitelistFile: [path lastPathComponent]])
    return NO;

  bool adware = NO;
  
  NSMutableDictionary * newFileInfo = nil;
  NSMutableDictionary * fileInfo = [self.adwareFiles objectForKey: path];
  
  if(fileInfo)
    adware = YES;
    
  if(!fileInfo)
    {
    newFileInfo = [NSMutableDictionary new];
    fileInfo = newFileInfo;
    }
    
  if([self isAdwareSuffix: path info: fileInfo])
    adware = YES;
  else if([self isAdwarePattern: info])
    adware = YES;
  else if([self isAdwareMatch: path info: fileInfo])
    adware = YES;
  else if([self isAdwareTrio: path info: fileInfo])
    adware = YES;
    
  if(adware)
    {
    if([self.adwareFiles objectForKey: path] == nil)
      [self.adwareFiles setObject: fileInfo forKey: path];
      
    NSMutableDictionary * launchdInfo =
      [self.launchdFiles objectForKey: path];
    
    if(launchdInfo)
      {
      [launchdInfo removeObjectForKey: kUnknown];
      [launchdInfo
        setObject: [NSNumber numberWithBool: YES] forKey: kAdware];
    
      [fileInfo setObject: launchdInfo forKey: kAdwareLaunchdInfo];
      }
    }
    
  [newFileInfo release];
  
  return adware;
  }

// Is this an adware suffix file?
- (bool) isAdwareSuffix: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  for(NSString * suffix in self.blacklistSuffixes)
    if([path hasSuffix: suffix])
      {
      NSString * name = [path lastPathComponent];
      
      NSString * tag =
        [name substringToIndex: [name length] - [suffix length]];
      
      [info setObject: [tag lowercaseString] forKey: kAdwareType];
      
      return YES;
      }
    
  return NO;
  }

// Do the plist file contents look like adware?
- (bool) isAdwarePattern: (NSMutableDictionary *) info
  {
  // First check for /etc/*.sh files.
  NSString * executable = [info objectForKey: kExecutable];
  
  if([executable hasPrefix: @"/etc/"] && [executable hasSuffix: @".sh"])
    return YES;
    
  // Now check for /Library/*.
  if([executable hasPrefix: @"/Library/"])
    {
    NSString * dirname = [executable stringByDeletingLastPathComponent];
  
    if([dirname isEqualToString: @"/Library"])
      if([[executable pathExtension] length] == 0)
        return YES;
        
    // Now check for /Library/*/*.
    NSString * name = [executable lastPathComponent];
    NSString * parent = [dirname lastPathComponent];
    
    if([name isEqualToString: parent])
      if([[executable pathExtension] length] == 0)
        return YES;
    }
    
  NSArray * command = [info objectForKey: kCommand];

  if([command count] >= 5)
    {
    NSString * arg1 =
      [[[command objectAtIndex: 0] lowercaseString] lastPathComponent];
    
    NSString * commandString =
      [NSString
        stringWithFormat:
          @"%@ %@ %@ %@ %@",
          arg1,
          [[command objectAtIndex: 1] lowercaseString],
          [[command objectAtIndex: 2] lowercaseString],
          [[command objectAtIndex: 3] lowercaseString],
          [[command objectAtIndex: 4] lowercaseString]];
    
    if([commandString hasPrefix: @"installer -evnt agnt -oprid "])
      return YES;
    }
    
  NSString * app = [executable lastPathComponent];
  
  if([app hasPrefix: @"App"] && ([app length] == 5))
    if([command count] >= 2)
      {
      NSString * trigger = [command objectAtIndex: 1];
      
      if([trigger isEqualToString: @"-trigger"])
        return YES;
      }

  // This is good enough for now.
  return NO;
  }

// Is this an adware match file?
- (bool) isAdwareMatch: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  NSString * name = [path lastPathComponent];
  
  for(NSString * match in self.blacklistFiles)
    {
    if([name isEqualToString: match])
      {
      [info setObject: name forKey: kAdwareType];
      
      return YES;
      }
    }
    
  for(NSString * match in self.blacklistMatches)
    {
    NSRange range = [name rangeOfString: match];
    
    if(range.location != NSNotFound)
      {
      NSString * tag = [name substringWithRange: range];
      
      [info setObject: [tag lowercaseString] forKey: kAdwareType];
      
      return YES;
      }
    }
    
  return NO;
  }

// Is this an adware trio of daemon/agent/helper?
- (bool) isAdwareTrio: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  NSString * name = [path lastPathComponent];
  
  NSString * prefix = name;
  
  if([name hasSuffix: @".daemon.plist"])
    {
    prefix = [name substringToIndex: [name length] - 13];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"daemon"];
    }
    
  if([name hasSuffix: @".agent.plist"])
    {
    prefix = [name substringToIndex: [name length] - 12];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"agent"];
    }
    
  if([name hasSuffix: @".helper.plist"])
    {
    prefix = [name substringToIndex: [name length] - 13];
    
    [self addPotentialAdwareTrioFile: path prefix: prefix type: @"helper"];
    }
    
  NSDictionary * trioFiles =
    [self.potentialAdwareTrioFiles objectForKey: prefix];

  BOOL hasDaemon = [trioFiles objectForKey: @"daemon"] != nil;
  BOOL hasAgent = [trioFiles objectForKey: @"agent"] != nil;
  BOOL hasHelper = [trioFiles objectForKey: @"helper"] != nil;
  
  if(hasDaemon && hasAgent && hasHelper)
    {
    NSArray * parts = [prefix componentsSeparatedByString: @"."];
    
    if([parts count] > 1)
      prefix = [parts objectAtIndex: 1];
      
    for(NSString * type in trioFiles)
      {
      NSString * trioPath = [trioFiles objectForKey: type];
      
      [info setObject: [prefix lowercaseString] forKey: kAdwareType];

      NSMutableDictionary * launchdInfo =
        [self.launchdFiles objectForKey: trioPath];
      
      if(launchdInfo)
        {
        [launchdInfo removeObjectForKey: kUnknown];
        [launchdInfo
          setObject: [NSNumber numberWithBool: YES] forKey: kAdware];
        }
      }

    return YES;
    }
    
  return NO;
  }

// Add a potential adware trio file.
- (void) addPotentialAdwareTrioFile: (NSString *) path
  prefix: (NSString *) prefix type: (NSString *) type
  {
  NSMutableDictionary * trioFiles =
    [self.potentialAdwareTrioFiles objectForKey: prefix];
    
  if(!trioFiles)
    {
    trioFiles = [NSMutableDictionary dictionary];
    
    [self.potentialAdwareTrioFiles setObject: trioFiles forKey: prefix];
    }
  
  [trioFiles setObject: path forKey: type];
  }

// Is this file an adware extension?
- (bool) isAdwareExtension: (NSString *) name path: (NSString *) path
  {
  if(([name length] > 0) && ([path length] > 0))
    {
    NSString * search = [path lowercaseString];
    
    for(NSString * extension in self.adwareExtensions)
      if([search rangeOfString: extension].location != NSNotFound)
        return YES;

    for(NSString * match in self.blacklistMatches)
      {
      NSRange range = [path rangeOfString: match];
      
      if(range.location != NSNotFound)
        return YES;

      range = [name rangeOfString: match];
      
      if(range.location != NSNotFound)
        return YES;
      }
    }
    
  return NO;
  }

// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;
  {
  [self.whitelistFiles addObjectsFromArray: names];
  }
  
// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;
  {
  [self.whitelistPrefixes addObjectsFromArray: names];
  }
  
// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names
  {
  [self.blacklistFiles addObjectsFromArray: names];
  }

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names
  {
  [self.blacklistSuffixes addObjectsFromArray: names];
  }

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names
  {
  [self.blacklistMatches addObjectsFromArray: names];
  }

// Is this file known?
- (bool) isKnownFile: (NSString *) name path: (NSString *) path
  {
  if([self isWhitelistFile: name])
    return YES;
    
  NSMutableDictionary * info = [self.launchdFiles objectForKey: path];
  
  if([self checkForAdware: path info: info])
    return YES;
    
  if(info)
    [info setObject: [NSNumber numberWithBool: YES] forKey: kUnknown];

  return NO;
  }

// Is this file in the whitelist?
- (bool) isWhitelistFile: (NSString *) name
  {
  if(!kWhitelistDisabled)
    if([self.whitelistFiles count] < kMinimumWhitelistSize)
      return YES;
    
  if([self.whitelistFiles containsObject: name])
    return YES;
    
  for(NSString * whitelistPrefix in self.whitelistPrefixes)
    if([name hasPrefix: whitelistPrefix])
      return YES;
      
  return NO;
  }

// What kind of adware is this?
- (NSString *) adwareType: (NSString *) path
  {
  return [self.adwareFiles objectForKey: path];
  }

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args
  {
  NSMutableString * command = [NSMutableString string];
  
  [command appendString: program];
  
  for(NSString * argument in args)
    {
    [command appendString: @" "];
    [command appendString: [Utilities cleanPath: argument]];
    }
    
  [self.terminatedTasks addObject: command];
  }

// Get the expected Apple signature for an executable.
- (NSString *) expectedAppleSignature: (NSString *) path
  {
  return [[self appleSoftware] objectForKey: path];
  }

// Is this a known Apple executable
- (BOOL) isKnownAppleExecutable: (NSString *) path
  {
  if([path length])
    {
    path = [Utilities resolveBundlePath: path];
  
    return [[self appleSoftware] objectForKey: path] != nil;
    }
    
  return NO;
  }

// Is this a known Apple executable but not a shell script?
- (BOOL) isKnownAppleNonShellExecutable: (NSString *) path
  {
  if([path length])
    {
    NSString * signature = [Utilities checkAppleExecutable: path];
    
    if([signature isEqualToString: kSignatureApple])
      return YES;
      
    if([signature isEqualToString: kSignatureValid])
      return YES;      
    }
    
  return NO;
  }

// Simulate adware.
- (void) simulateAdware
  {
  [self.whitelistFiles removeObject: @"com.oracle.java.Java-Updater.plist"];
  [self.whitelistFiles removeObject: @"com.google.keystone.agent.plist"];
  [self.blacklistFiles addObject: @"com.google.keystone.agent.plist"];
  }
  
// Associate a path with a UUID to hide it.
- (NSString *) createUUIDForPath: (NSString *) path
  {
  NSString * UUID = [NSString UUID];
  
  if([UUID length] > 0)
    [self.pathsForUUIDs setObject: path forKey: UUID];
    
  return UUID;
  }
  
@end
