/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdTask.h"
#import "NSString+Etresoft.h"
#import "LocalizedString.h"
#import "Utilities.h"
#import "EtreCheckConstants.h"
#import "NSMutableAttributedString+Etresoft.h"

// A wrapper around a launchd task.
@implementation LaunchdTask

// Path to the config script.
@synthesize path = myPath;

// The launchd label.
@synthesize label = myLabel;

// The executable or script.
@synthesize executable = myExecutable;

// The arguments.
@synthesize arguments = myArguments;

// Overall status.
@synthesize status = myStatus;

// The last exit code.
@synthesize lastExitCode = myLastExitCode;

// Append the file status.
+ (NSAttributedString *) formatStatus: (NSString *) status
  {
  NSString * statusString = ECLocalizedString(@"not loaded");
  
  NSColor * color = [[Utilities shared] gray];
  
  if([status isEqualToString: kStatusLoaded])
    {
    statusString = ECLocalizedString(@"loaded");
    color = [[Utilities shared] blue];
    }
  else if([status isEqualToString: kStatusRunning])
    {
    statusString = ECLocalizedString(@"running");
    color = [[Utilities shared] green];
    }
  else if([status isEqualToString: kStatusFailed])
    {
    statusString = ECLocalizedString(@"failed");
    color = [[Utilities shared] red];
    }
  else if([status isEqualToString: kStatusKilled])
    {
    statusString = ECLocalizedString(@"killed");
    color = [[Utilities shared] red];
    }
  
  NSMutableAttributedString * result = [NSMutableAttributedString new];
  
  [result
    appendString: [NSString stringWithFormat: @"[%@]", statusString]
    attributes:
      @{
        NSForegroundColorAttributeName : color,
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
      
  return [result autorelease];
  }

// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict
  {
  if(dict.count > 0)
    {
    self = [super init];
    
    if(self != nil)
      {
      [self parseDictionary: dict];
      }
    }
    
  return self;
  }
  
// Constructor with label.
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  data: (nonnull NSData *) data
  {
  if((label.length > 0) && (data.length > 0))
    {
    self = [super init];
    
    if(self != nil)
      {
      myLabel = [label retain];
      
      [self parseData: data];
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myPath release];
  [myLabel release];
  [myExecutable release];
  [myArguments release];
  [myStatus release];
  [myLastExitCode release];
  
  [super dealloc];
  }
  
// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict 
  {
  NSString * label = [dict objectForKey: @"Label"];
  NSString * program = [dict objectForKey: @"Program"];
  NSArray * arguments = [dict objectForKey: @"ProgramArguments"];
  
  if(label.length > 0)
    myLabel = [label retain];
    
  [self parseExecutable: program arguments: arguments];  
  }
  
// Parse launchctl data.
- (void) parseData: (NSData *) data
  {
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  NSString * program = nil;
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
      {
      [program release];
      
      program = [value retain];
      }
      
    else if([line isEqualToString: @"	arguments = {"])
      parsingArguments = true;
    }
    
  [self parseExecutable: program arguments: arguments];  

  [arguments release];
  [program release];
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
    }
    
  // I should have an executabel at this point. If I don't, try to pull it
  // from the label.
  if(self.executable.length == 0)
    myExecutable = 
      [[[NSWorkspace sharedWorkspace] 
        absolutePathForAppBundleWithIdentifier: self.label] retain];
    
  if(self.executable.length)
  
    // OK, I've found the executable, but it could be some script 
    // interpreter or similar. I need to try to dereference those again.
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
    
    myExecutable = [[arguments firstObject] retain];
    }
    
  if(arguments.count > 0)
    {
    myArguments = 
      [arguments subarrayWithRange: NSMakeRange(1, arguments.count - 1)];
    
    [myArguments retain];
    }
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
    
  NSString * resolvedExecutable = 
    [self.executable 
      stringByReplacingOccurrencesOfString: @"//" withString: @"/"];
    
  // Clean up URLs and quasi-URLs.
  if([self.executable hasPrefix: @"file:"])
    resolvedExecutable = [resolvedExecutable substringFromIndex: 5];
    
  if(resolvedExecutable.length > 0)
    {
    [myExecutable release];
    myExecutable = [resolvedExecutable retain];
    }
  }

@end
