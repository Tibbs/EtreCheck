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

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self != nil)
    {
    }
    
  return self;
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
    NSString * version =
      [[NSString alloc]
        initWithData: sw_vers.standardOutput
        encoding: NSUTF8StringEncoding];
      
    if(version.length >= 3)
      {
      NSString * major = 
        [version substringWithRange: NSMakeRange(0, 2)];
      
      NSString * minor = 
        [version substringWithRange: NSMakeRange(2, 1)];
                
      [self willChangeValueForKey: @"major"];
      [self willChangeValueForKey: @"minor"];
        
      myMajor = 
        [[[NumberFormatter sharedNumberFormatter] 
          convertFromString: major] intValue];
            
      myMinor = [minor characterAtIndex: 0] - 'A';

      [self didChangeValueForKey: @"minor"];
      [self didChangeValueForKey: @"major"];        
      }
      
    [version release];
    }
    
  [sw_vers release];
  }
  
@end
