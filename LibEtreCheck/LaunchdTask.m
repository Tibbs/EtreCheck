/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"
#import "Utilities.h"
#import "OSVersion.h"
#import "SubProcess.h"
#import "EtreCheckConstants.h"
#import "NSString+Etresoft.h"
#import <unistd.h>

// A wrapper around a launchd task.
@implementation LaunchdTask

// Path to the config script.
@synthesize path = myPath;

// Is the config script valid?
@synthesize configScriptValid = myConfigScriptValid;

// The launchd context.
@synthesize context = myContext;

// The launchd domain. 
@synthesize domain = myDomain;
  
// The query source. (oldlaunchd, newlaunchd, list, file)
@synthesize source = mySource;

// The launchd label.
@synthesize label = myLabel;

// The process ID.
@synthesize PID = myPID;

// The last exit code.
@synthesize lastExitCode = myLastExitCode;

// The executable or script.
@synthesize executable = myExecutable;

// The arguments.
@synthesize arguments = myArguments;

// The signature.
@synthesize signature = mySignature;

// The developer.
@synthesize developer = myDeveloper;

// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict
  {
  if(dict.count > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      mySource = kLaunchdServiceManagementSource;
      
      [self parseDictionary: dict];

      [self readSignature];

      [self findContext];  
      }
    }
    
  return self;
  }

// Constructor with new 10.10 launchd output.
- (nullable instancetype) initWithNewLaunchdData: (nonnull NSData *) data
  {
  if(data.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      mySource = kLaunchdNewLaunchctlSource;

      [self parseNewPlistData: data];

      [self readSignature];

      [self findContext];  
      }
    }
    
  return self;
  }
  
// Constructor with old launchd output.
- (nullable instancetype) initWithOldLaunchdData: (nonnull NSData *) data
  {
  if(data.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      mySource = kLaunchdOldLaunchctlSource;

      [self parseOldPlistData: data];

      [self readSignature];

      [self findContext];  
      }
    }
    
  return self;
  }
  
// Constructor with label.
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  PID: (nonnull NSString *) PID
  lastExitCode: (nonnull NSString *) lastExitCode
  {
  if(label.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      mySource = kLaunchdLaunchctlListingSource;

      myLabel = [label retain];
      myPID = [PID retain];
      myLastExitCode = [lastExitCode retain];
      myContext = kLaunchdUnknownContext;
      }
    }
    
  return self;
  }
  
// Constructor with path.
- (nullable instancetype) initWithPath: (nonnull NSString *) path
  {
  if(path.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      mySource = kLaunchdFileSource;

      [self parseFromPath: path];

      [self readSignature];

      [self findContext];  
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myContext release];
  [myLabel release];
  [myExecutable release];
  [myArguments release];
  [mySignature release];
  
  [super dealloc];
  }
  
#pragma mark - Parse "old" dictionary

// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict 
  {
  NSString * label = dict[@"Label"];
  id PID = dict[@"PID"];
  id lastExitStatus = dict[@"LastExitStatus"];
  NSString * program = dict[@"Program"];
  NSArray * arguments = dict[@"ProgramArguments"];
  
  if(label.length > 0)
    myLabel = [label retain];
    
  myPID = 
    [PID respondsToSelector: @selector(longValue)]
      ? [PID stringValue]
      : [PID retain];
      
  myLastExitCode = 
    [lastExitStatus respondsToSelector: @selector(longValue)]
      ? [lastExitStatus stringValue]
      : [lastExitStatus retain];
  
  [self parseExecutable: program arguments: arguments];  
  }
  
#pragma mark - Parse "new" text output

// Parse a new plist.
- (void) parseNewPlistData: (nonnull NSData *) data 
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  NSMutableArray * arguments = [NSMutableArray new];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  // Am I parsing arguments now?
  bool parsingArguments = false;
  
  for(NSString * line in lines)
    {
    NSArray * parts = [self parseLine: line];

    NSString * key = [parts firstObject];
    NSString * value = 
      parts.count == 1
        ? nil
        : [parts lastObject];
    
    if(key.length == 0)
      continue;
      
    // If I am parsing arguments, look for the end indicator.
    if(parsingArguments)
      {
      // An argument could be a bare "}". Do a string check with whitespace.
      if([line isEqualToString: @"	}"])
        parsingArguments = false;        
      else
        [arguments addObject: key];
      }
      
    else if([key isEqualToString: @"program"])
      myExecutable = [value retain];
    
    else if([key isEqualToString: @"pid"])
      myPID = [value retain];
    
    else if([key isEqualToString: @"last exit code"])
      myLastExitCode = [value retain];
    
    else if([line isEqualToString: @"	arguments = {"])
      parsingArguments = true;
    }
    
  [arguments release];
  [plist release];
  }
  
// Parse a key/value pair line in launchd output.
- (NSArray *) parseLine: (NSString *) string
  {
  NSRange range = [string rangeOfString: @"="];
  
  if(range.location == NSNotFound)
    {
    NSString * key =
      [string 
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    key = [key stringByRemovingQuotes];
    
    return [NSArray arrayWithObjects: key, nil];
    }
    
  NSString * key = [string substringToIndex: range.location];
  NSString * value = [string substringFromIndex: range.location + 1];
  
  key =
    [key 
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  value =
    [value 
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
  key = [key stringByRemovingQuotes];
  value = [value stringByRemovingQuotes];
  
  return [NSArray arrayWithObjects: key, value, nil];
  }
  
// Parse an old plist.
- (void) parseOldPlistData: (nonnull NSData *) data 
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  NSMutableArray * arguments = [NSMutableArray new];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  // Am I parsing arguments now?
  bool parsingArguments = false;
  
  for(NSString * line in lines)
    {
    NSArray * parts = [self parseOldLine: line];

    NSString * key = [parts firstObject];
    NSString * value = 
      parts.count == 1
        ? nil
        : [parts lastObject];
    
    if(key.length == 0)
      continue;
      
    // If I am parsing arguments, look for the end indicator.
    if(parsingArguments)
      {
      // An argument could be a bare "}". Do a string check with whitespace.
      if([line isEqualToString: @"	);"])
        parsingArguments = false;        
      else
        [arguments addObject: key];
      }
      
    else if([key isEqualToString: @"Label"])
      myLabel = [value retain];
    
    else if([key isEqualToString: @"Program"])
      myExecutable = [value retain];
    
    else if([key isEqualToString: @"PID"])
      myPID = [value retain];
    
    else if([key isEqualToString: @"LastExitStatus"])
      myLastExitCode = [value retain];
    
    else if([line isEqualToString: @"	\"ProgramArguments\" = ("])
      parsingArguments = true;
    }
    
  [arguments release];
  [plist release];
  }

// Parse a key/value pair line in old launchd output.
- (NSArray *) parseOldLine: (NSString *) string
  {
  if([string hasSuffix: @";"])
    return [self parseLine: [string substringToIndex: string.length - 1]];
    
  return [self parseLine: string];
  }
  
// Reload new launchd data from a label.
- (void) newReloadFromLabel: (nonnull NSString *) label 
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = nil;
  
  if([self.context isEqualToString: kLaunchdUserContext])
    {
    uid_t uid = getuid();
    
    target = [[NSString alloc] initWithFormat: @"user/%d/%@", uid, label];
    }
  else
    target = [[NSString alloc] initWithFormat: @"system/%@", label];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      {
      myLabel = [label retain];
      
      [self parseNewPlistData: launchctl.standardOutput];
      }
    
  [arguments release];
  [launchctl release];
  }

// Parse old launchd data from a label.
- (void) oldReloadFromLabel: (nonnull NSString *) label 
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"list", label, nil];
    
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      [self parseOldPlistData: launchctl.standardOutput];
    
  [arguments release];
  [launchctl release];
  }

// Parse from a path.
- (void) parseFromPath: (nonnull NSString *) path 
  {
  if([[OSVersion shared] major] >= kYosemite)
    [self newParseFromPath: path];
  else
    [self oldParseFromPath: path];
  }

// Parse new launchd data from a path.
- (void) newParseFromPath: (nonnull NSString *) path 
  {
  NSData * data = [[NSData alloc] initWithContentsOfFile: path];
  
  [self parseNewPlistData: data];
  
  [data release];
  }
  
// Parse old launchd data from a path.
- (void) oldParseFromPath: (nonnull NSString *) path 
  {
  NSData * data = [[NSData alloc] initWithContentsOfFile: path];
  
  [self parseOldPlistData: data];
  
  [data release];
  }
  
// Load a launchd task.
- (void) load
  {
  if([[OSVersion shared] major] >= kYosemite)
    [self newLoad];
  else
    [self oldLoad];
  }

// Load new launchd data from a label.
- (void) newLoad
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = nil;
  
  if([self.context isEqualToString: kLaunchdUserContext])
    {
    uid_t uid = getuid();
    
    target = 
      [[NSString alloc] initWithFormat: @"user/%d/%@", uid, self.label];
    }
  else
    target = [[NSString alloc] initWithFormat: @"system/%@", self.label];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"enable", target, nil];
    
  [target release];
  
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  
  [self newReloadFromLabel: self.label];
  }

// Load old launchd data from a label.
- (void) oldLoad
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"load", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];

  [self oldReloadFromLabel: self.label];
  }

// Unload a launchd task.
- (void) unload
  {
  if([[OSVersion shared] major] >= kYosemite)
    [self newUnload];
  else
    [self oldUnload];
  }
  
// Unload new launchd data from a label.
- (void) newUnload
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = nil;
  
  if([self.context isEqualToString: kLaunchdUserContext])
    {
    uid_t uid = getuid();
    
    target = 
      [[NSString alloc] initWithFormat: @"user/%d/%@", uid, self.label];
    }
  else
    target = [[NSString alloc] initWithFormat: @"system/%@", self.label];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"disable", target, nil];
    
  [target release];
  
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];
  
  [self newReloadFromLabel: self.label];
  }

// Unload old launchd data from a label.
- (void) oldUnload
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"unload", @"-wF", self.path, nil];
    
  [launchctl execute: @"/bin/launchctl" arguments: arguments];
    
  [arguments release];
  [launchctl release];

  [self oldReloadFromLabel: self.label];
  }

#pragma mark - Executable

// Parse an executable.
- (void) parseExecutable: (NSString *) program 
  arguments: (NSArray *) arguments
  {
  // If there is no program, try to pull it from the arguments.
  if(program.length == 0)
    [self parseExecutable: arguments];
    
  // There is a program, so just accept it and read the arguments.
  else
    {
    [myExecutable release];
    
    myExecutable = [program retain];
    
    [self parseArguments: arguments];
    }
    
  // OK, I've found the executable, but it could be some script interpreter
  // or similar. I need to try to dereference those again.
  [self dereferenceExecutable];
  }
  
// Parse an executable from an arguments array.
- (void) parseExecutable: (NSArray *) arguments
  {
  if(arguments.count == 0)
    return;
    
  [myExecutable release];
    
  myExecutable = [[arguments firstObject] retain];
  
  [self parseArguments: arguments];
  }
  
// Parse the arguments from an arguments array.
- (void) parseArguments: (NSArray *) arguments
  {
  // If I don't already appear to have a valid executable, try to get it
  // from the arguments.
  if(![[NSFileManager defaultManager] fileExistsAtPath: self.executable])
    {
    [myExecutable release];
    
    myExecutable = [arguments firstObject];
    }
    
  myArguments = 
    [arguments subarrayWithRange: NSMakeRange(1, arguments.count - 1)];
  }
  
// Try to find the "true" executable, not some script interpreter.
- (void) dereferenceExecutable
  {
  if(![self.executable hasPrefix: @"/"])
    [self resolveRelativeExecutable];
    
  if([self.executable isEqualToString: @"/usr/bin/sandbox-exec"])
    [self resolveSandboxExecExecutable];
  else if([self.executable isEqualToString: @"/usr/bin/open"])
    [self resolveOpenExecutable];
  }
  
// Resolve a relative executable as per launchd.plist man page.
- (void) resolveRelativeExecutable
  {
  [self resolveExecutableRelativeTo: @"/usr/bin"];
  [self resolveExecutableRelativeTo: @"/bin"];
  [self resolveExecutableRelativeTo: @"/usr/sbin"];
  [self resolveExecutableRelativeTo: @"/sbin"];
  }

// Resolve an executable relative to a given path.
- (void) resolveExecutableRelativeTo: (NSString *) path
  {
  NSString * absoluteExecutable =
    [path stringByAppendingPathComponent: self.executable];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    {
    [myExecutable release];
    
    myExecutable = [absoluteExecutable retain];
    };
  }
  
// Resolve a sandbox-exec executable.
- (void) resolveSandboxExecExecutable
  {
  for(NSString * argument in self.arguments)
    if([argument isEqualToString: @"-f"])
      continue;
    else if([argument isEqualToString: @"-n"])
      continue;
    else if([argument isEqualToString: @"-p"])
      continue;
    else if([argument isEqualToString: @"-D"])
      continue;
    else
      {
      [myExecutable release];
      myExecutable = [argument retain];
      break;
      }
  }

// Resolve an open executable.
- (void) resolveOpenExecutable
  {
  for(NSUInteger i = 0; i < self.arguments.count; ++i)
    {
    NSString * argument = [self.arguments objectAtIndex: i];
    
    if([argument isEqualToString: @"-e"])
      continue;
    else if([argument isEqualToString: @"-t"])
      continue;
    else if([argument isEqualToString: @"-f"])
      continue;
    else if([argument isEqualToString: @"-F"])
      continue;
    else if([argument isEqualToString: @"--fresh"])
      continue;
    else if([argument isEqualToString: @"-W"])
      continue;
    else if([argument isEqualToString: @"--wait-apps"])
      continue;
    else if([argument isEqualToString: @"-R"])
      continue;
    else if([argument isEqualToString: @"--reveal"])
      continue;
    else if([argument isEqualToString: @"-n"])
      continue;
    else if([argument isEqualToString: @"--new"])
      continue;
    else if([argument isEqualToString: @"-g"])
      continue;
    else if([argument isEqualToString: @"--background"])
      continue;
    else if([argument isEqualToString: @"-j"])
      continue;
    else if([argument isEqualToString: @"--hide"])
      continue;
    else if([argument isEqualToString: @"-h"])
      continue;
    else if([argument isEqualToString: @"--header"])
      continue;
    else if([argument isEqualToString: @"-a"])
      continue;
    else if([argument isEqualToString: @"--args"])
      break;
    else if([argument isEqualToString: @"-s"])
      ++i;
    else if([argument isEqualToString: @"-b"])
      {
      if((i + 1) < self.arguments.count)
        {
        NSString * bundleID = [self.arguments objectAtIndex: i + 1];
        
        NSString * path =
          [[NSWorkspace sharedWorkspace]
            absolutePathForAppBundleWithIdentifier: bundleID];
          
        if([path length] > 0)
          {
          [myExecutable release];
          myExecutable = [path retain];
          break;
          }
        }
      }
    else
      {
      [myExecutable release];
      myExecutable = [argument retain];
      break;
      }
    }
    
  NSString * resolvedExecutable = nil;
  
  // Clean up URLs and quasi-URLs.
  if([self.executable hasPrefix: @"file:"])
    resolvedExecutable = [self.executable substringFromIndex: 5];
    
  resolvedExecutable = 
    [self.executable 
      stringByReplacingOccurrencesOfString: @"//" withString: @"/"];
      
  resolvedExecutable = 
    [self.executable 
      stringByReplacingOccurrencesOfString: @"//" withString: @"/"];
    
  if(resolvedExecutable.length > 0)
    {
    [myExecutable release];
    myExecutable = [resolvedExecutable retain];
    }
  }

#pragma mark - Signature

// Read the signature.
- (void) readSignature
  {
  }
  
#pragma mark - Context

// Find the context based on the path.
- (void) findContext
  {
  if([self.path hasPrefix: @"/System/Library/"])
    myContext = kLaunchdAppleContext;
  else if([self.path hasPrefix: @"/Library/"])
    myContext = kLaunchdSystemContext;
  else if([self.path hasPrefix: @"~/Library/"])
    myContext = kLaunchdUserContext;
  else
    {
    NSString * libraryPath = 
      [NSHomeDirectory() stringByAppendingPathComponent: @"Library"];
      
    if([self.path hasPrefix: libraryPath])
      myContext = kLaunchdUserContext;
    else 
      myContext = kLaunchdUnknownContext;
    }
  }
  
@end
