/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "Process.h"

// Encapsulate a running process.
@implementation Process

// The command being run.
@synthesize command = myCommand;

// The path to the process.
@synthesize path = myPath;

// The name of the process.
@synthesize name = myName;

// The process ID.
@synthesize PID = myPID;

// Is this an Apple app?
@synthesize apple = myApple;

// Was this app reported on an EtreCheck report?
@synthesize reported = myReported;

// Set the command.
- (void) setCommand: (NSString *) command
  {
  bool change = false;
  
  if(command == nil)
    change = true;
  else if(![myCommand isEqualToString: command])
    change = true;
    
  if(change)
    {
    [self willChangeValueForKey: @"command"];
    
    [myCommand release];
    
    myCommand = [command retain];
    
    [self parseCommand: myCommand];
    
    [self didChangeValueForKey: @"command"];
    }
  }
  
// Get the command.
- (NSString *) command
  {
  return myCommand;
  }
  
// Destructor.
- (void) dealloc
  {
  self.command = nil;
  [myPath release];
  [myName release];
  
  [super dealloc];
  }
  
// Parse the command.
- (void) parseCommand: (NSString *) command
  {
  NSString * resolvedPath = nil;
  
  if(command.length > 0)
    {
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
  else if(![myPath isEqualToString: resolvedPath])
    change = true;
    
  if(change)
    {
    [self willChangeValueForKey: @"path"];
    
    [myPath release];
    
    myPath = resolvedPath;
    
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
