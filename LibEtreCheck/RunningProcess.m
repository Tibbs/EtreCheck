/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "RunningProcess.h"

// Encapsulate a running process.
@implementation RunningProcess

// The command being run.
@synthesize command = myCommand;

// The path to the process.
@synthesize path = myPath;

// The process ID.
@synthesize PID = myPID;

// Is this an Apple app?
@synthesize apple = myApple;

// Was this app reported on an EtreCheck report?
@synthesize reported = myReported;

// Get the path.
- (NSString *) path
  {
  if(myPath == nil)
    {
    NSString * resolvedPath = 
      [[self resolveExecutable: self.command] retain];
    
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
      
    if(resolvedPath != nil)
      myPath = resolvedPath;
    }
    
  return myPath;
  }
  
// Destructor.
- (void) dealloc
  {
  self.command = nil;
  [myPath release];
  
  [super dealloc];
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
