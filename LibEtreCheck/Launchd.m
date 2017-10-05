/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Launchd.h"
#import "LaunchdTask.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"
#import <ServiceManagement/ServiceManagement.h>

// A wrapper around all things launchd.
@implementation Launchd

// Launchd tasks. Tasks are not unique by either label or path.
@synthesize tasks = myTasks;

// Return the singeton.
+ (nonnull Launchd *) shared
  {
  static Launchd * launchd = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      launchd = [Launchd new];
    });
    
  return launchd;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    myTasks = [NSMutableArray new];
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myTasks release];
  
  [super dealloc];
  }
  
// Load all entries.
- (void) load
  {
  [self loadServiceManagement];

  if([[OSVersion shared] major] >= kYosemite)
    [self newLoad];
  else
    [self oldLoad];
  }
  
// Load Service Management jobs.
- (void) loadServiceManagement
  {
  if(& SMCopyAllJobDictionaries != NULL)
    {
    CFArrayRef systemJobs = 
      SMCopyAllJobDictionaries(kSMDomainSystemLaunchd);
    
    CFArrayRef userJobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    
    for(NSDictionary * dict in (NSArray *)systemJobs)
      {
      LaunchdTask * task = [[LaunchdTask alloc] initWithDictionary: dict];
      
      if(task != nil)
        [self.tasks addObject: task];
      }

    for(NSDictionary * dict in (NSArray *)userJobs)
      {
      LaunchdTask * task = [[LaunchdTask alloc] initWithDictionary: dict];
      
      if(task != nil)
        [self.tasks addObject: task];
      }
    }
  }
  
// New load all entries.
- (void) newLoad
  {
  [self newLoadSystem];
  [self newLoadUser];
  }
  
// New load all system domain tasks.
- (void) newLoadSystem
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = @"system/";
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self parseNewList: launchctl.standardOutput];
      
  [arguments release];
  [launchctl release];
  }

// New load all user domain tasks.
- (void) newLoadUser
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  uid_t uid = getuid();
    
  NSString * target = [[NSString alloc] initWithFormat: @"user/%d/", uid];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self parseNewList: launchctl.standardOutput];
      
  [arguments release];
  [launchctl release];
  }

// Parse a new launchctl listing.
- (void) parseNewList: (NSData *) data
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
    
      [self parseLine: line];
      }
      
    else if([line isEqualToString: @"	services = {"])
      parsingServices = true;
    }
    
  [plist release];
  }
  
// Parse a line from a launchd listing.
- (void) parseLine: (NSString *) line
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
        [self loadTaskWithLabel: label PID: PID lastExitCode: lastExitCode];
      }
    }
    
  [scanner release];
  }
  
// Old load all entries.
- (void) oldLoad
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = [[NSArray alloc] initWithObjects: @"list",nil];
    
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self parseOldList: launchctl.standardOutput];
    
  [arguments release];
  [launchctl release];
  }

// Parse an old launchctl listing.
- (void) parseOldList: (NSData *) data
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  for(NSString * line in lines)
    [self parseLine: line];
    
  [plist release];
  }

// Load a task. Just do my best.
- (void) loadTaskWithLabel: (NSString *) label
  PID: (NSString *) PID lastExitCode: (NSString *) lastExitCode
  {
  LaunchdTask * task = nil;
  
  task =
    [[LaunchdTask alloc] 
      initWithLabel: label PID: PID lastExitCode: lastExitCode];
    
  if(task != nil)
    [self.tasks addObject: task];
    
  [task release];
  }
  
@end
