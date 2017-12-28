/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Process.h"
#import "Utilities.h"
#import "NumberFormatter.h"

// Encapsulate a running process.
@implementation Process

// The command being run.
@synthesize command = myCommand;

// The process ID.
@synthesize PID = myPID;

// CPU usage sample count.
@synthesize cpuUsageSampleCount = myCpuUsageSampleCount;

// Energy usage sample count.
@synthesize energyUsageSampleCount = myEnergyUsageSampleCount;
    
// Destructor.
- (void) dealloc
  {
  self.command = nil;
  
  [super dealloc];
  }
        
// Update withnew process attributes.
- (void) update: (ProcessAttributes *) processAttributes types: (int) types
  {
  if(types & kCPUUsage)
    {
    double nextSampleCount = self.cpuUsageSampleCount + 1;
    
    self.cpuUsage = 
      (self.cpuUsage * (self.cpuUsageSampleCount / nextSampleCount)) 
        + (processAttributes.cpuUsage / nextSampleCount);

    ++self.cpuUsageSampleCount;
    }
    
  if(types & kMemoryUsage)
    self.memoryUsage = processAttributes.memoryUsage;
    
  if(types & kEnergyUsage)
    {
    double nextSampleCount = self.energyUsageSampleCount + 1;
    
    self.energyUsage = 
      (self.energyUsage * (self.energyUsageSampleCount / nextSampleCount)) 
        + (processAttributes.energyUsage / nextSampleCount);
        
    ++self.energyUsageSampleCount;
    }
    
  // This is an accumulator.
  if(types & kNetworkUsage)
    {
    self.networkInputUsage = processAttributes.networkInputUsage;
    self.networkOutputUsage = processAttributes.networkOutputUsage;
    }
  }
  
#pragma mark - Private methods

// Parse the command.
- (void) parseCommand: (NSString *) command
  {
  NSString * resolvedPath = nil;
  
  if(command.length > 0)
    {
    self.command = command;
    
    resolvedPath = [self resolveExecutable: command];
    
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
            resolvedPath = [[currentPath copy] autorelease];
            
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
  else if(![myPath isEqualToString: resolvedPath])
    change = true;
    
  if(change)
    {
    [self willChangeValueForKey: @"path"];
    
    [myPath release];
    
    myPath = [resolvedPath retain];
    
    [self didChangeValueForKey: @"path"];

    [self willChangeValueForKey: @"name"];
    
    [myName release];
    
    myName = [[myPath lastPathComponent] retain];
    
    [self didChangeValueForKey: @"name"];
    }
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
