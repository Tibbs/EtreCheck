/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import "OSVersion.h"
#import "SubProcess.h"
#import "NumberFormatter.h"
#import "EtreCheckConstants.h"

// A wrapper around the OS version.
@implementation OSVersion

// The OS major version.
@synthesize major = myMajor;

// The OS minor version.
@synthesize minor = myMinor;

// The OS build.
@synthesize build = myBuild;

// The full version.
@synthesize version = myVersion;

// Return the singeton.
+ (nonnull OSVersion *) shared
  {
  static OSVersion * version = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(
    & onceToken,
    ^{
      version = [OSVersion new];
    });
    
  return version;
  }

// The OS major version.
- (int) major
  {
  if(myMajor == 0)
    [self setOSVersion];
    
  return myMajor;
  }
  
// The OS minor version.
- (int) minor
  {
  if(myMajor == 0)
    [self setOSVersion];
    
  return myMinor;
  }

// Get the build.
- (NSString *) build
  {
  if(myBuild == nil)
    [self setOSVersion];
    
  return myBuild;
  }
  
// Get the version.
- (NSString *) version    
  {
  if(myVersion == nil)
    [self setOSVersion];
    
  return myVersion;
  }
  
// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    }
    
  return self;
  }
  
// Destructor.
- (void) dealloc
  {
  [myBuild release];
  [myVersion release];
  
  [super dealloc];
  }
  
// Set the OS version.
- (void) setOSVersion
  {
  SubProcess * sw_vers = [[SubProcess alloc] init];
  
  NSArray * args =
    @[
      @"-buildVersion"
    ];

  if([sw_vers execute: @"/usr/bin/sw_vers" arguments: args])
    {
    NSString * data =
      [[NSString alloc]
        initWithData: sw_vers.standardOutput
        encoding: NSUTF8StringEncoding];
      
    myBuild = 
      [data 
        stringByTrimmingCharactersInSet: 
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [data release];
    
    [myBuild retain];
    
    if(self.build.length >= 3)
      {
      NSString * major = 
        [self.build substringWithRange: NSMakeRange(0, 2)];
      
      NSString * minor = 
        [self.build substringWithRange: NSMakeRange(2, 1)];
                
      [self willChangeValueForKey: @"major"];
      [self willChangeValueForKey: @"minor"];
        
      myMajor = 
        [[[NumberFormatter sharedNumberFormatter] 
          convertFromString: major] intValue];
            
      myMinor = [minor characterAtIndex: 0] - 'A';

      if(self.minor > 0)
        myVersion = 
          [[NSString alloc] 
            initWithFormat: @"10.%d.%d", self.major - 4, self.minor];
      else
        myVersion = 
          [[NSString alloc] 
            initWithFormat: @"10.%d", self.major];
        
      [self didChangeValueForKey: @"minor"];
      [self didChangeValueForKey: @"major"];        
      }
    }
    
  [sw_vers release];
  }
    
@end
