/***********************************************************************
 ** Etresoft, Inc.
 ** Copyright (c) 2017. All rights reserved.
 **********************************************************************/

#import <XCTest/XCTest.h>
#import "Model.h"
#import "Launchd.h"
#import "LaunchdFile.h"
#import "LaunchdLoadedTask.h"
#import "LaunchdCollector.h"
#import "SystemLaunchDaemonsCollector.h"
#import "SafariExtensionsCollector.h"
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
  Launchd * launchd = [[Model model] launchd];
  
  [launchd load];
  
  NSLog(
    @"Found %lu tasks", 
    (unsigned long)[[launchd tasksByPath] count]);
  
  NSArray * paths = 
    [[[launchd tasksByPath] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * path in paths)
    {
    LaunchdFile * file = [[launchd tasksByPath] objectForKey: path];
      
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
      
  NSUInteger ephemeralCount = [[launchd ephemeralTasks] count];
  
  if(ephemeralCount > 0)
    {
    for(LaunchdLoadedTask * task in [launchd ephemeralTasks])
      {
      if(task.label.length > 0)
        NSLog(@"Found %@ task %@", task.domain, task.label);
      else
        {
        NSLog(@"Found %@ task %@", task.domain, task.label);
        }
        
      if(task.path.length > 0)
        NSLog(@"    %@", task.path);
        
      NSLog(@"    %@", task.executable);
      }
      
    NSLog(
      @"Still have %lu ephemeral tasks", (unsigned long)ephemeralCount);
    }
  }

- (void) testLaunchdCollector 
  {
  SystemLaunchDaemonsCollector * collector = 
    [SystemLaunchDaemonsCollector new];
  
  [collector collect];
  
  NSAttributedString * result = collector.result;
  
  NSLog(@"Output: %@", result.string);
  }

- (void) testSafariCollector 
  {
  SafariExtensionsCollector * collector = 
    [SafariExtensionsCollector new];
  
  [collector collect];
  
  NSAttributedString * result = collector.result;
  
  NSLog(@"Output: %@", result.string);
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
