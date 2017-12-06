/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Launchd.h"
#import "LaunchdFile.h"
#import "LaunchdLoadedTask.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import "NSDictionary+Etresoft.h"
#import <ServiceManagement/ServiceManagement.h>

// A wrapper around all things launchd.
@implementation Launchd

// Launchd files keyed by config file path. 
// Values are task objects since they are guaranteed to be unique.
@synthesize filesByPath = myFilesByPath;

/// Launchd files keyed by label. 
// Values are NSMutableArrays since they might not be unique.
@synthesize filesByLabel = myFilesByLabel;

// Set of launchd files with missing executables.
@synthesize orphanFiles = myOrphanFiles;

// Set of launchd files identified as adware.
@synthesize adwareFiles = myAdwareFiles;

// Files lacking a signature.
@synthesize unsignedFiles = myUnsignedFiles;

// Array of loaded launchd tasks.
@synthesize ephemeralTasks = myEphemeralTasks;

// Only load once.
@synthesize loaded = myLoaded;

// Apple launchd file.
@synthesize appleFiles = myAppleFiles;

// Launchd files indexed by identifier.
@synthesize launchdFileLookup = myLaunchdFileLookup;

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myFilesByPath = [NSMutableDictionary new];
    myFilesByLabel = [NSMutableDictionary new];
    myOrphanFiles = [NSMutableSet new];
    myAdwareFiles = [NSMutableSet new];
    myUnsignedFiles = [NSMutableSet new];
    myEphemeralTasks = [NSMutableSet new];
    myAppleFiles = [NSMutableDictionary new];
    myLaunchdFileLookup = [NSMutableDictionary new];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myFilesByPath release];
  [myFilesByLabel release];
  [myOrphanFiles release];
  [myAdwareFiles release];
  [myUnsignedFiles release];
  [myEphemeralTasks release];
  [myAppleFiles release];
  [myLaunchdFileLookup release];
  
  [super dealloc];
  }
  
// Load all entries.
- (void) load
  {
  if(self.loaded)
    return;
    
  myLoaded = YES;
  
  // Load Apple files.
  [self loadAppleFiles];
  
  // Load "truth" files.
  [self loadTruthFiles];
  
  // Now load "reality" data.
  [self loadEphemeralTasks];
  
  // Reconcile all the data.
  [self reconcileTasks];
  
  // Build the lookup table.
  for(NSString * path in self.filesByPath)
    {
    LaunchdFile * file = [self.filesByPath objectForKey: path];
    
    if(file != nil)
      [self.launchdFileLookup setObject: file forKey: file.identifier];
    }
  }
  
// Load all "truth" files. Later, I will compare with reality.
- (void) loadTruthFiles
  {
  [self loadDirectory: @"/System/Library/LaunchDaemons"];
  
  [self loadDirectory: @"/System/Library/LaunchAgents"];
  
  [self loadDirectory: @"/Library/LaunchDaemons"];
  
  [self 
    loadDirectory: @"/Library/LaunchAgents"];
  
  [self 
    loadDirectory: 
      [NSHomeDirectory() 
        stringByAppendingPathComponent: @"/Library/LaunchAgents"]];
  }
  
// Load all config files in a directory.
- (void) loadDirectory: (NSString *) directory
  {
  NSArray * args =
    @[
      directory,
      @"-type", @"f",
      @"-or",
      @"-type", @"l"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * file in files)
      [self addFileAtPath: file];
    }
    
  [subProcess release];
  }
  
// Add a task at a path.
- (void) addFileAtPath: (NSString *) path 
  {
  if([path hasSuffix: @"/.DS_Store"])
    return;
    
  NSString * safePath = [path stringByAbbreviatingWithTildeInPath];
  
  if(safePath.length > 0)
    {
    LaunchdFile * file = [[LaunchdFile alloc] initWithPath: safePath];
  
    [file checkSignature: self];
    
    if(file != nil)
      [self.filesByPath setObject: file forKey: safePath];
      
    if(file.label.length > 0)
      [self.filesByLabel setObject: file forKey: file.label];
  
    [file release];
    }
  }
  
// Load "reality" data.
- (void) loadEphemeralTasks
  {
  if([[OSVersion shared] major] >= kYosemite)
    [self loadLaunchdTasks];
  else
    [self loadServiceManagementTasks];
  }
  
// New load all entries.
- (void) loadLaunchdTasks
  {
  [self loadSystemLaunchdTasks];
  [self loadUserLaunchdTasks];
  [self loadGUILaunchdTasks];
  }
  
// Load all system domain tasks.
- (void) loadSystemLaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = @"system/";
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        parseLaunchdOutput: launchctl.standardOutput 
        inDomain: kLaunchdSystemDomain];
      
  [arguments release];
  [launchctl release];
  }

// Load all user domain tasks.
- (void) loadUserLaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  uid_t uid = getuid();
    
  NSString * target = [[NSString alloc] initWithFormat: @"user/%d/", uid];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        parseLaunchdOutput: launchctl.standardOutput 
        inDomain: kLaunchdUserDomain];
      
  [arguments release];
  [launchctl release];
  }

// Load all gui domain tasks.
- (void) loadGUILaunchdTasks
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  uid_t uid = getuid();
    
  NSString * target = [[NSString alloc] initWithFormat: @"gui/%d/", uid];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self 
        parseLaunchdOutput: launchctl.standardOutput 
        inDomain: kLaunchdGUIDomain];
      
  [arguments release];
  [launchctl release];
  }

// Parse a launchctl output.
- (void) parseLaunchdOutput: (NSData *) data inDomain: (NSString *) domain
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  // Am I parsing services now?
  bool parsingServices = false;
  
  for(NSString * line in lines)
    {
    // If I am parsing services, look for the end indicator.
    if(parsingServices)
      {
      // An argument could be a bare "}". Do a string check with whitespace.
      if([line isEqualToString: @"	}"])
        break;        
    
      [self parseLine: line inDomain: domain];
      }
      
    else if([line isEqualToString: @"	services = {"])
      parsingServices = true;
    }
    
  [plist release];
  }
  
// Parse a line from a launchd listing.
- (void) parseLine: (NSString *) line inDomain: (NSString *) domain
  {
  NSString * trimmedLine =
    [line
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  NSScanner * scanner = [[NSScanner alloc] initWithString: trimmedLine];
  
  // Yes. These must all be strings. Apple likes to be clever.
  NSString * PID = nil;
  NSString * lastExitCode = nil;
  NSString * label = nil;
  
  BOOL success = 
    [scanner 
      scanUpToCharactersFromSet: 
        [NSCharacterSet whitespaceAndNewlineCharacterSet] 
      intoString: & PID];
  
  if(success)
    {
    success = 
      [scanner 
        scanUpToCharactersFromSet: 
          [NSCharacterSet whitespaceAndNewlineCharacterSet] 
        intoString: & lastExitCode];

    if(success)
      {
      // Labels can have spaces.
      success = 
        [scanner 
          scanUpToCharactersFromSet: [NSCharacterSet newlineCharacterSet] 
          intoString: & label];
  
      if(success && ![PID isEqualToString: @"PID"])
        [self loadTaskWithLabel: label inDomain: domain];
      }
    }
    
  [scanner release];
  }
  
// Load a task. Just do my best.
- (void) loadTaskWithLabel: (NSString *) label inDomain: (NSString *) domain
  {
  LaunchdLoadedTask * task = 
    [[LaunchdLoadedTask alloc] initWithLabel: label inDomain: domain];
   
  if(task != nil)
    [self.ephemeralTasks addObject: task];
    
  [task release];
  }
  
// Load Service Management jobs.
- (void) loadServiceManagementTasks
  {
  if(& SMCopyAllJobDictionaries != NULL)
    {
    CFArrayRef systemJobs = 
      SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    
    for(NSDictionary * dict in (NSArray *)systemJobs)
      {
      LaunchdLoadedTask * task = 
        [[LaunchdLoadedTask alloc] 
          initWithDictionary: dict inDomain: kLaunchdSystemDomain];
      
      if(task != nil)
        [self.ephemeralTasks addObject: task];
      
      [task release];
      }

    if(systemJobs != NULL)
      CFRelease(systemJobs);
      
    CFArrayRef userJobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    
    for(NSDictionary * dict in (NSArray *)userJobs)
      {
      LaunchdLoadedTask * task = 
        [[LaunchdLoadedTask alloc] 
          initWithDictionary: dict inDomain: kLaunchdUserDomain];
      
      if(task != nil)
        [self.ephemeralTasks addObject: task];
      
      [task release];
      }
      
    if(userJobs != NULL)
      CFRelease(userJobs);
    }
  }
  
// Reconcile all the tasks.
- (void) reconcileTasks
  {
  NSMutableSet * orphanTasks = [NSMutableSet new];
  
  for(LaunchdLoadedTask * task in self.ephemeralTasks)
    {
    if(task.path.length > 0)
      {
      LaunchdFile * truthFile = [self.filesByPath objectForKey: task.path];
      
      if(truthFile != nil)
        {
        [truthFile.loadedTasks addObject: task];
        
        continue;
        }
      }
      
    if(task.label.length > 0)
      {
      LaunchdFile * truthFile = 
        [self.filesByLabel objectForKey: task.label];
      
      if(truthFile != nil)
        {
        [truthFile.loadedTasks addObject: task];
        
        continue;
        }
      }

    // Labels could have a UUID tacked onto the end. 
    LaunchdFile * truthFile = 
      [self.filesByLabel objectForKey: task.baseLabel];
    
    if(truthFile != nil)
      {
      [truthFile.loadedTasks addObject: task];
      
      continue;
      }
      
    [orphanTasks addObject: task];
    }
    
  [self.ephemeralTasks setSet: orphanTasks];
    
  [orphanTasks release];
  
  for(NSString * path in self.filesByPath)
    {
    LaunchdFile * file = [self.filesByPath objectForKey: path];
    
    if(file.executable.length > 0)
      {
      BOOL exists =
        [[NSFileManager defaultManager] fileExistsAtPath: file.executable];
        
      if(!exists)
        [self.orphanFiles addObject: file];
      }
    }
  }
  
// Load Apple launchd files.
- (void) loadAppleFiles
  {
  NSBundle * bundle = [NSBundle bundleForClass: [self class]];

  NSString * launchdPath =
    [bundle pathForResource: @"appleLaunchd" ofType: @"plist"];
    
  NSData * plistData = [NSData dataWithContentsOfFile: launchdPath];
  
  if(plistData)
    {
    NSDictionary * plist = [NSDictionary readPropertyListData: plistData];
  
    if(plist)
      {
      switch([[OSVersion shared] major])
        {
        case kSnowLeopard:
          [self loadAppleLaunchd: [plist objectForKey: @"10.6"]];
          break;
        case kLion:
          [self loadAppleLaunchd: [plist objectForKey: @"10.7"]];
          break;
        case kMountainLion:
          [self loadAppleLaunchd: [plist objectForKey: @"10.8"]];
          break;
        case kMavericks:
          [self loadAppleLaunchd: [plist objectForKey: @"10.9"]];
          break;
        case kYosemite:
          [self loadAppleLaunchd: [plist objectForKey: @"10.10"]];
          break;
        case kElCapitan:
          [self loadAppleLaunchd: [plist objectForKey: @"10.11"]];
          break;
        case kSierra:
          [self loadAppleLaunchd: [plist objectForKey: @"10.12"]];
          break;
        case kHighSierra:
        default:
          [self loadAppleLaunchd: [plist objectForKey: @"10.13"]];
          break;
        }
      }
    }
  }

// Load apple launchd files for a specific OS version.
- (void) loadAppleLaunchd: (NSDictionary *) launchdFiles
  {
  if(launchdFiles != nil)
    [self.appleFiles addEntriesFromDictionary: launchdFiles];
  }

@end
