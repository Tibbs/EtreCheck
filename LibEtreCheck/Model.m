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
#import "EtreCheckConstants.h"
#import "LocalizedString.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "Safari.h"

@implementation Model

@synthesize majorOSVersion = myMajorOSVersion;
@synthesize minorOSVersion = myMinorOSVersion;
@synthesize OSBuild = myOSBuild;
@synthesize OSVersion = myOSVersion;
@synthesize problem = myProblem;
@synthesize problemDescription = myProblemDescription;
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
@synthesize launchd = myLaunchd;
@synthesize safari = mySafari;
@synthesize processes = myProcesses;
@synthesize adwareFound = myAdwareFound;
@synthesize unsignedFound = myUnsignedFound;
@synthesize adwareExtensions = myAdwareExtensions;
@synthesize whitelistFiles = myWhitelistFiles;
@synthesize whitelistPrefixes = myWhitelistPrefixes;
@synthesize blacklistFiles = myBlacklistFiles;
@synthesize blacklistMatches = myBlacklistMatches;
@synthesize blacklistSuffixes = myBlacklistSuffixes;
@synthesize computerName = myComputerName;
@synthesize hostName = myHostName;
@synthesize terminatedTasks = myTerminatedTasks;
@synthesize backupExists = myBackupExists;
@synthesize ignoreKnownAppleFailures = myIgnoreKnownAppleFailures;
@synthesize showSignatureFailures = myShowSignatureFailures;
@synthesize hideAppleTasks = myHideAppleTasks;
@synthesize oldEtreCheckVersion = myOldEtreCheckVersion;
@synthesize verifiedEtreCheckVersion = myVerifiedEtreCheckVersion;
@synthesize verifiedSystemVersion = myVerifiedSystemVersion;
@synthesize appleSoftware = myAppleSoftware;
@synthesize appleLaunchd = myAppleLaunchd;
@synthesize appleLaunchdByLabel = myAppleLaunchdByLabel;
@synthesize legitimateStrings = myLegitimateStrings;
@synthesize sip = mySIP;
@synthesize cleanupRequired = myCleanupRequired;
@synthesize notificationSPAMs = myNotificationSPAMs;
@synthesize pathsForUUIDs = myPathsForUUIDs;
@synthesize xml = myXMLBuilder;
@synthesize header = myXMLHeader;
  
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
    myLaunchd = [Launchd new];
    myVolumes = [NSMutableDictionary new];
    myPhysicalVolumes = [NSMutableSet new];
    myDiskErrors = [NSMutableDictionary new];
    myDiagnosticEvents = [NSMutableDictionary new];
    myLaunchd = [Launchd new];
    mySafari = [Safari new];
    myProcesses = [NSMutableSet new];
    myTerminatedTasks = [NSMutableArray new];
    myIgnoreKnownAppleFailures = YES;
    myShowSignatureFailures = NO;
    myHideAppleTasks = YES;
    myAdwareExtensions = [NSMutableSet new];
    myWhitelistFiles = [NSMutableSet new];
    myWhitelistPrefixes = [NSMutableSet new];
    myBlacklistFiles = [NSMutableSet new];
    myBlacklistSuffixes = [NSMutableSet new];
    myBlacklistMatches = [NSMutableSet new];
    myNotificationSPAMs = [NSMutableDictionary new];
    myPathsForUUIDs = [NSMutableDictionary new];
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
  [myPathsForUUIDs release];
  [myNotificationSPAMs release];
  [mySerialCode release];
  [myModel release];
  [myLogEntries release];
  [myHostName release];
  [myGPUErrors release];
  [myPhysicalVolumes release];
  [myComputerName release];
  [myAppleSoftware release];
  [myAppleLaunchd release];
  [myLegitimateStrings release];
  [myBlacklistSuffixes release];
  [myBlacklistMatches release];
  [myBlacklistFiles release];
  [myWhitelistFiles release];
  [myWhitelistPrefixes release];
  [myAdwareExtensions release];
  
  self.appleLaunchdByLabel = nil;
  self.terminatedTasks = nil;
  self.processes = nil;
  self.launchd = nil;
  self.diagnosticEvents = nil;
  self.launchd = nil;
  self.safari = nil;
  self.diskErrors = nil;
  self.volumes = nil;
  self.applications = nil;
  self.machineIcon = nil;
  self.processes = nil;
  self.OSVersion = nil;
  self.OSBuild = nil;
  self.problem = nil;
  self.problemDescription = nil;
  
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
    appendString: ECLocalizedString(@"[Details]")
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
    appendString: ECLocalizedString(@"[Open]")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSForegroundColorAttributeName : [[Utilities shared] blue],
        NSLinkAttributeName : url
      }];
  
  return [urlString autorelease];
  }

// Add to the adware extensions list.
- (void) appendToAdwareExtensions: (NSArray *) names
  {
  [self.adwareExtensions addObjectsFromArray: names];
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
  [self.blacklistMatches addObject: @"ASCPowerTools2"];
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