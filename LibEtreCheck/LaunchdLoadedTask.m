/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "LaunchdLoadedTask.h"
#import "SubProcess.h"
#import "NSString+Etresoft.h"

// A wrapper around a launchd task.
@interface LaunchdTask ()

// Parse an executable.
- (void) parseExecutable: (NSString *) program 
  arguments: (NSArray *) arguments;

@end

// A wrapper around a launchd task.
@implementation LaunchdLoadedTask

// The launchd domain. 
@synthesize domain = myDomain;
  
// The process ID.
@synthesize PID = myPID;

// The last exit code.
@synthesize lastExitCode = myLastExitCode;

// There can be multiple tasks per service identifier. Such tasks
// have a UUID appended to the label. Try to remove that.
@synthesize baseLabel = myBaseLabel;

// There can be multiple tasks per service identifier. Such tasks
// have a UUID appended to the label. Try to remove that.
- (NSString *) baseLabel
  {
  if(myBaseLabel == nil)
    {
    myBaseLabel = self.label;
    
    if(myBaseLabel.length > 37)
      {
      NSString * UUID = 
        [myBaseLabel substringFromIndex: myBaseLabel.length - 37];
      
      bool UUIDFound = true;
      
      if([UUID characterAtIndex: 0] != '.')
        UUIDFound = false;
      if([UUID characterAtIndex: 9] != '-')
        UUIDFound = false;
      if([UUID characterAtIndex: 14] != '-')
        UUIDFound = false;
      if([UUID characterAtIndex: 24] != '-')
        UUIDFound = false;

      if(UUIDFound)
        myBaseLabel = [[self.label substringToIndex: 37] retain];
      }
    }
    
  return myBaseLabel;
  }
  
// Constructor with NSDictionary.
- (nullable instancetype) initWithDictionary: (nonnull NSDictionary *) dict
  inDomain: (NSString *) domain
  {
  if(dict.count > 0)
    {
    self = [super initWithDictionary: dict];
    
    if(self != nil)
      {
      myDomain = [domain retain];
      
      [self parseDictionary: dict];
      }
    }
    
  return self;
  }
  
// Constructor with label.
- (nullable instancetype) initWithLabel: (nonnull NSString *) label
  inDomain: (NSString *) domain
  {
  if(label.length > 0)
    {
    NSData * data = 
      [LaunchdLoadedTask loadDataWithLabel: label inDomain: domain];
    
    self = [super initWithLabel: label data: data];
    
    if(self != nil)
      {
      myDomain = [domain retain];
      
      [self parseData: data];
      }
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myDomain release];
  [myPID release];
  [myLastExitCode release];
  
  [super dealloc];
  }
  
// Parse a dictionary.
- (void) parseDictionary: (NSDictionary *) dict 
  {
  NSString * PID = dict[@"PID"];
  NSString * lastExitCode = dict[@"LastExitStatus"];
  
  myPID = [PID retain];
  myLastExitCode = [lastExitCode retain];
  }

// Parse a new plist.
- (void) parseData: (nonnull NSData *) data 
  {
  NSString * program = nil;
  NSMutableArray * arguments = [NSMutableArray new];
  
  NSString * plist = 
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  // Split lines by new lines.
  NSArray * lines = [plist componentsSeparatedByString: @"\n"];
  
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

    else if([key isEqualToString: @"pid"])
      myPID = [value retain];
    
    else if([key isEqualToString: @"last exit code"])
      myLastExitCode = [value retain];

    else if([key isEqualToString: @"path"])
      self.path = [value stringByAbbreviatingWithTildeInPath];
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
  
// Reload new launchd data from a label.
+ (NSData *) loadDataWithLabel: (nonnull NSString *) label 
  inDomain: (NSString *) domain
  {
  SubProcess * launchctl = [[SubProcess alloc] init];
  
  NSString * target = nil;
  
  if([domain isEqualToString: kLaunchdSystemDomain])
    target = [[NSString alloc] initWithFormat: @"system/%@", label];
  else
    {
    uid_t uid = getuid();
    
    if([domain isEqualToString: kLaunchdUserDomain])
      target = [[NSString alloc] initWithFormat: @"user/%d/%@", uid, label];
    else if([domain isEqualToString: kLaunchdGUIDomain])
      target = [[NSString alloc] initWithFormat: @"gui/%d/%@", uid, label];
    }
  
  NSArray * arguments = 
    [[NSArray alloc] initWithObjects: @"print", target, nil];
    
  [target release];
  
  NSData * data = nil;
  
  if([launchctl execute: @"/bin/launchctl" arguments: arguments])
    if(launchctl.standardOutput.length > 0)
      data = [[launchctl.standardOutput copy] autorelease];
    
  [arguments release];
  [launchctl release];
  
  return data;
  }

// Re-query a launchd task.
- (void) requery
  {
  NSData * data = 
    [LaunchdLoadedTask loadDataWithLabel: self.label inDomain: self.domain];
  
  [self parseData: data];
  }
  
@end
