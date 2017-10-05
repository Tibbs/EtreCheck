/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <XCTest/XCTest.h>
#import "Launchd.h"
#import "LaunchdTask.h"
#import "EtreCheckConstants.h"

@interface LibEtreCheckTests : XCTestCase

@end

@implementation LibEtreCheckTests

- (void) setUp 
  {
  [super setUp];
  
  // Put setup code here. This method is called before the invocation of 
  // each test method in the class.
  }

- (void) tearDown 
  {
  // Put teardown code here. This method is called after the invocation of 
  // each test method in the class.
  [super tearDown];
  }

- (void) testLaunchdFunctionality 
  {
  [[Launchd shared] load];
  
  NSLog(
    @"Found %lu tasks", (unsigned long)[[[Launchd shared] tasks] count]);
  
  for(LaunchdTask * task in [[Launchd shared] tasks])
    NSLog(@"Found task %@", task.label);
  }

- (void) testPerformanceExample 
  {
  // This is an example of a performance test case.
  [self 
    measureBlock:
      ^{
        // Put the code you want to measure the time of here.
      }];
  }

@end
