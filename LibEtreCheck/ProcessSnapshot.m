/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "ProcessSnapshot.h"
#import "Utilities.h"
#import "NumberFormatter.h"

// Encapsulate a running process.
@implementation ProcessSnapshot
  
// Constructor with line from the following ps command:
// @"-raxcww", @"-o", @"pid, %cpu, rss, command"
- (instancetype) initWithPsLine: (NSString *) line
  {
  self = [super init];
  
  if(self != nil)
    {
    if([self parsePsLine: line])
      return self;
      
    [self release];
    }
    
  return nil;
  }
  
// Constructor with a line from the following top command:
// @"-stats", @"pid,cpu,rsize,power,command"
- (instancetype) initWithTopLine: (NSString *) line
  {
  self = [super init];
  
  if(self != nil)
    {
    if([self parseTopLine: line])
      return self;
      
    [self release];
    }
    
  return nil;
  }
  
// Constructor with a line from a complex nettop command.
- (instancetype) initWithNettopLine: (NSString *) line
  {
  self = [super init];
  
  if(self != nil)
    {
    if([self parseNettopLine: line])
      return self;
      
    [self release];
    }
    
  return nil;
  }
  
// Destructor.
- (void) dealloc
  {
  self.command = nil;
  
  [super dealloc];
  }
    
// Parse a line from the ps command.
// @"-raxcww", @"-o", @"pid, %cpu, rss, command"
- (bool) parsePsLine: (NSString *) line
  {
  bool success = false;
  
  NSScanner * scanner = [[NSScanner alloc] initWithString: line];

  if([scanner scanInt: & myPID])
    {
    double cpuValue;

    if([scanner scanDouble: & cpuValue])
      {
      self.cpuUsage = cpuValue;
      self.cpuUsageSampleCount = 1;
      
      double memValue;
      
      if([scanner scanDouble: & memValue])
        {
        self.memoryUsage = memValue * 1024;
        
        NSString * command = nil;
        
        if([scanner scanUpToString: @"\n" intoString: & command])
          {
          @autoreleasepool 
            {
            [self parseCommand: command];
            }
            
          success = true;
          }
        }
      }
    }
    
  [scanner release];
  
  return success;
  }

// Parse a line from the following top command.
// @"-stats", @"pid,cpu,rsize,power,command"
- (bool) parseTopLine: (NSString *) line
  {
  bool success = false;
  
  NSScanner * scanner = [[NSScanner alloc] initWithString: line];

  if([scanner scanInt: & myPID])
    {
    double cpuValue;

    if([scanner scanDouble: & cpuValue])
      {
      self.cpuUsage = cpuValue;
      self.cpuUsageSampleCount = 1;
      
      double memValue = [Utilities scanTopMemory: scanner];
    
      self.memoryUsage = memValue;
      
      double energyValue;
      
      if([scanner scanDouble: & energyValue])
        {
        self.energyUsage = energyValue;
        self.energyUsageSampleCount = 1;
        
        NSString * name = nil;
        
        if([scanner scanUpToString: @"\n" intoString: & name])
          {
          self.name = name;
          self.path = name;
          
          success = true;
          }
        }
      }
    }
    
  [scanner release];
  
  return success;
  }
  
// Parse a line from a complex nettop command.
- (bool) parseNettopLine: (NSString *) line
  {
  NSScanner * scanner = [[NSScanner alloc] initWithString: line];
  
  NSString * time = NULL;
  
  bool success = false;
  
  BOOL valid =
    [scanner
      scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
      intoString: & time];

  if(valid)
    {
    NSString * process = NULL;
    
    valid =
      [scanner
        scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
        intoString: & process];

    if(process)
      {
      NSRange PIDRange =
        [process rangeOfString: @"." options: NSBackwardsSearch];
      
      NSNumber * pid = nil;
      
      if(PIDRange.location != NSNotFound)
        if(PIDRange.location < [process length])
          {
          pid =
            [[NumberFormatter sharedNumberFormatter]
              convertFromString:
                [process substringFromIndex: PIDRange.location + 1]];
          
          self.PID = pid.intValue;
          
          self.name = [process substringToIndex: PIDRange.location];
          self.path = self.name;
          
          long long bytesIn;
          
          if([scanner scanLongLong: & bytesIn])
            {
            self.networkInputUsage = bytesIn;
          
            long long bytesOut;
          
            if([scanner scanLongLong: & bytesOut])
              {
              self.networkOutputUsage = bytesOut;
                
              success = YES;
              }
            }
          }
      }
    }
    
  [scanner release];
    
  return success;
  }
  
// Parse the command.
- (void) parseCommand: (NSString *) command
  {
  NSString * resolvedPath = nil;
  
  if(command.length > 0)
    {
    self.command = command;
    
    resolvedPath = [[self resolveExecutable: command] retain];
    
    // If the path doesn't exist, keep looking.
    if(resolvedPath == nil)
      {
      NSArray * parts = [self.command componentsSeparatedByString: @" "];
      
      if(parts.count > 0)
        {
        NSMutableString * current = 
          [[NSMutableString alloc] 
            initWithString: [parts objectAtIndex: 0]];
        
        NSUInteger index = 0;
        
        while(true)
          {
          NSString * currentPath = [self resolveExecutable: current];
          
          if(currentPath != nil)
            {
            [resolvedPath release];
            resolvedPath = [currentPath retain];
            
            break;
            }
            
          ++index;
          
          if(index >= parts.count)
            break;
            
          [current appendString: @" "];
          [current appendString: [parts objectAtIndex: index]];
          }
          
        [current release];
        }
      }
    }
    
  bool change = false;
  
  if(resolvedPath == nil)
    change = true;
  else if(![self.path isEqualToString: resolvedPath])
    change = true;
    
  if(change)
    {
    if(resolvedPath == nil)
      resolvedPath = command;
      
    self.path = resolvedPath;
    self.name = [self.path lastPathComponent];
    }
    
  [resolvedPath release];
  }
  
// Resolve a relative executable as per launchd.plist man page.
- (NSString *) resolveExecutable: (NSString *) path
  {
  if([path hasPrefix: @"/"])
    {
    if([[NSFileManager defaultManager] fileExistsAtPath: path])
      return path;
    else
      return nil;
    }
    
  if([path hasPrefix: @"-"])
    path = [path substringFromIndex: 1];
    
  else if(path.length > 2)
    if([path hasPrefix: @"("] && [path hasSuffix: @")"])
      path = [path substringWithRange: NSMakeRange(1, path.length - 2)];
    
  NSString * resolvedPath = nil;
  
  resolvedPath = [self resolveExecutable: path relativeTo: @"/usr/bin"];
  
  if(resolvedPath)
    return resolvedPath;
    
  resolvedPath = [self resolveExecutable: path relativeTo: @"/bin"];
  
  if(resolvedPath)
    return resolvedPath;

  resolvedPath = [self resolveExecutable: path relativeTo: @"/usr/sbin"];
  
  if(resolvedPath)
    return resolvedPath;

  resolvedPath = [self resolveExecutable: path relativeTo: @"/sbin"];
  
  if(resolvedPath)
    return resolvedPath;
    
  resolvedPath = [self resolveExecutable: path relativeTo: @"/usr/libexec"];
  
  if(resolvedPath)
    return resolvedPath;

  NSURL * url = 
    [[NSWorkspace sharedWorkspace] 
      URLForApplicationWithBundleIdentifier: path];
      
  if(url != nil)
    resolvedPath = url.path;
  
  if(resolvedPath)
    return resolvedPath;

  return nil;
  }

// Resolve an executable relative to a given path.
- (NSString *) resolveExecutable: (NSString *) path 
  relativeTo: (NSString *) dir
  {
  NSString * absoluteExecutable =
    [dir stringByAppendingPathComponent: path];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    return absoluteExecutable;
    
  return nil;
  }

@end
