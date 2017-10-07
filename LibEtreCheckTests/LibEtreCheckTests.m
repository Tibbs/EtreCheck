/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <XCTest/XCTest.h>
#import "Launchd.h"
#import "LaunchdFile.h"
#import "LaunchdLoadedTask.h"
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
    @"Found %lu tasks", 
    (unsigned long)[[[Launchd shared] tasksByPath] count]);
  
  NSArray * paths = 
    [[[[Launchd shared] tasksByPath] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * path in paths)
    {
    LaunchdFile * file = 
      [[[Launchd shared] tasksByPath] objectForKey: path];
      
    NSString * validity =
      file.configScriptValid
        ? @""
        : @"(invalid) ";
        
    NSLog(
      @"%@ %@ %@(%lu loaded tasks)", 
      file.status,
      file.path, 
      validity, 
      (unsigned long)file.loadedTasks.count);
      
    NSLog(@"    %@", file.executable);
      
    NSMutableSet * labels = [NSMutableSet new];
    
    for(LaunchdLoadedTask * task in file.loadedTasks)
      [labels addObject: task.label];
      
    bool different = false;
    
    for(NSString * label in labels)
      if(![file.label isEqualToString: label])
        different = true;
        
    if(different)
      for(LaunchdLoadedTask * task in file.loadedTasks)
        NSLog(
          @"    %@", task.label);
    }
      
  NSUInteger ephemeralCount = [[[Launchd shared] ephemeralTasks] count];
  
  if(ephemeralCount > 0)
    {
    NSLog(
      @"Still have %lu ephemeral tasks", (unsigned long)ephemeralCount);
    
    for(LaunchdLoadedTask * task in [[Launchd shared] ephemeralTasks])
      {
      NSLog(@"Found %@ task %@", task.domain, task.label);
      
      if(task.path.length > 0)
        NSLog(@"    %@", task.path);
        
      NSLog(@"    %@", task.executable);
      }
    }
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
