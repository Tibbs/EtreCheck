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
#import <ServiceManagement/ServiceManagement.h>

// A wrapper around all things launchd.
@implementation Launchd

// Launchd tasks keyed by config file path. 
// Values are task objects since they are guaranteed to be unique.
@synthesize tasksByPath = myTasksByPath;

/// Launchd tasks keyed by label. 
// Values are NSMutableArrays since they might not be unique.
@synthesize tasksByLabel = myTasksByLabel;

// Array of loaded launchd tasks.
@synthesize ephemeralTasks = myEphemeralTasks;

// Only load once.
@synthesize loaded = myLoaded;

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myTasksByPath = [NSMutableDictionary new];
    myTasksByLabel = [NSMutableDictionary new];
    myEphemeralTasks = [NSMutableArray new];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myTasksByPath release];
  [myTasksByLabel release];
  [myEphemeralTasks release];
  
  [super dealloc];
  }
  
// Load all entries.
- (void) load
  {
  if(self.loaded)
    return;
    
  myLoaded = YES;
  
  // Load "truth" files.
  [self loadTruthFiles];
  
  // Now load "reality" data.
  [self loadEphemeralTasks];
  
  // Reconcile all the data.
  [self reconcileTasks];
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
  NSString * safePath = [path stringByAbbreviatingWithTildeInPath];
  
  if(safePath.length > 0)
    {
    LaunchdFile * file = [[LaunchdFile alloc] initWithPath: safePath];
  
    if(file != nil)
      [self.tasksByPath setObject: file forKey: safePath];
      
    if(file.label.length > 0)
      [self.tasksByLabel setObject: file forKey: file.label];
  
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
      success = 
        [scanner 
          scanUpToCharactersFromSet: 
            [NSCharacterSet whitespaceAndNewlineCharacterSet] 
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
  NSMutableArray * orphanTasks = [NSMutableArray new];
  
  for(LaunchdLoadedTask * task in self.ephemeralTasks)
    {
    if(task.path.length > 0)
      {
      LaunchdFile * truth = [self.tasksByPath objectForKey: task.path];
      
      if(truth != nil)
        {
        [truth.loadedTasks addObject: task];
        
        continue;
        }
      }
      
    // Labels could have a UUID tacked onto the end. 
    LaunchdFile * truth = [self.tasksByLabel objectForKey: task.baseLabel];
    
    if(truth != nil)
      {
      [truth.loadedTasks addObject: task];
      
      continue;
      }
      
    [orphanTasks addObject: task];
    }
    
  [self.ephemeralTasks setArray: orphanTasks];
    
  [orphanTasks release];
  }
  
@end
