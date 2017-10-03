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
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSArray * args =
    @[
      @"/usr/bin/sw_vers",
      @"-productVersion"
    ];

  [subProcess autorelease];

  if([subProcess execute: @"/bin/launchctl" arguments: args])
    {
    NSString * version =
      [[NSString alloc]
        initWithData: subProcess.standardOutput
        encoding: NSUTF8StringEncoding];
      
    if([version hasPrefix: @"10."])
      {
      NSString * key = [version substringFromIndex: 3];
      
      NSRange range = [key rangeOfString: @"."];
      
      if(range.location != NSNotFound)
        {
        NSString * major = 
          [key substringWithRange: NSMakeRange(0, range.location)];
        
        NSString * minor = 
          [key 
            substringWithRange: 
              NSMakeRange(
                range.location + 1, key.length - range.location - 1)];
                
        [self willChangeValueForKey: @"major"];
        [self willChangeValueForKey: @"minor"];
        
        myMajor = 
          [[[NumberFormatter sharedNumberFormatter] 
            convertFromString: major] intValue];
            
        myMinor = 
          [[[NumberFormatter sharedNumberFormatter] 
            convertFromString: minor] intValue];

        [self didChangeValueForKey: @"minor"];
        [self didChangeValueForKey: @"major"];        
        }
      }
      
    [version release];
    }
  }
  
@end
