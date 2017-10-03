/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"
#import "NumberFormatter.h"
#import "Utilities.h"

// A wrapper around a launchd task.
@implementation LaunchdTask

// The launchd domain.
@synthesize domain = myDomain;

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
  inDomain: (nonnull NSString *) domain
  {
  if(dict.count > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      [self parseDictionary: dict inDomain: domain];
      }
    }
    
  return self;
  }

// Constructor with new 10.10 launchd output.
- (nullable instancetype) initWithLaunchd: (nullable NSString *) plist
  inDomain: (nonnull NSString *) domain
  {
  if(plist.length > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      [self parsePlist: plist inDomain: domain];
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myDomain release];
  [myLabel release];
  [myExecutable release];
  [myArguments release];
  [mySignature release];
  
  [super dealloc];
  }
  
#pragma mark - Parse "old" dictionary

// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict 
  inDomain: (NSString *) domain
  {
  NSString * label = dict[@"Label"];
  NSNumber * PID = dict[@"PID"];
  NSNumber * lastExitStatus = dict[@"LastExitStatus"];
  NSString * program = dict[@"Program"];
  NSArray * arguments = dict[@"ProgramArguments"];
  
  if(label.length > 0)
    myLabel = [label retain];
    
  myPID = [PID longValue];
  myLastExitCode = [lastExitStatus longValue];
  
  [self parseExecutable: program arguments: arguments];
  
  [self readSignature];
  }
  
#pragma mark - Parse "new" text output

// Parse a plist.
- (void) parsePlist: (NSString *) plist 
  inDomain: (nonnull NSString *) domain
  {
  NSMutableArray * arguments = [NSMutableArray new];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
  // Am I parsing arguments now?
  bool parsingArguments = false;
  
  for(NSString * line in lines)
    {
    NSString * trimmedLine =
      [line
        stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // If I am parsing arguments, look for the end indicator.
    if(parsingArguments)
      {
      // An argument could be a bare "}". Do a string check with whitespace.
      if([line isEqualToString: @"	}"])
        parsingArguments = false;        
      else if(trimmedLine.length > 0)
        [arguments addObject: trimmedLine];
      }
      
    else if([trimmedLine isEqualToString: @"bundle id"])
      myLabel = [self parseString: trimmedLine];
    
    else if([trimmedLine isEqualToString: @"program"])
      myExecutable = [self parseString: trimmedLine];
    
    else if([trimmedLine isEqualToString: @"pid"])
      myPID = [[self parseNumber: trimmedLine] longValue];
    
    else if([trimmedLine isEqualToString: @"last exit code"])
      myLastExitCode = [[self parseNumber: trimmedLine] longValue];
    
    else if([line isEqualToString: @"	arguments = {"])
      parsingArguments = true;
    }
    
  [arguments release];
  }
  
// Parse a string value in a new 10.10 launchd output.
- (NSString *) parseString: (NSString *) string
  {
  NSRange range = [string rangeOfString: @"="];
  
  NSString * valueString = [string substringFromIndex: range.location + 1];
  
  return
    [valueString 
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  }
  
// Parse a numeric value in a new 10.10 launchd output.
- (NSNumber *) parseNumber: (NSString *) string
  {
  return 
    [[NumberFormatter sharedNumberFormatter] 
      convertFromString: [self parseString: string]];
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
  
@end
