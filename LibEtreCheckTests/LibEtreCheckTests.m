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
#import "SystemLaunchAgentsCollector.h"
#import "LaunchDaemonsCollector.h"
#import "LaunchAgentsCollector.h"
#import "UserLaunchAgentsCollector.h"
#import "SafariExtensionsCollector.h"
#import "AdwareCollector.h"
#import "EtreCheckConstants.h"
#import "Adware.h"
#import "UnsignedCollector.h"

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
    (unsigned long)[[launchd filesByPath] count]);
  
  NSArray * paths = 
    [[[launchd filesByPath] allKeys] 
      sortedArrayUsingSelector: @selector(compare:)];
  
  for(NSString * path in paths)
    {
    LaunchdFile * file = [[launchd filesByPath] objectForKey: path];
      
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
  SystemLaunchDaemonsCollector * systemDaemons = 
    [SystemLaunchDaemonsCollector new];
  
  [systemDaemons collect];
  
  SystemLaunchAgentsCollector * systemAgents = 
    [SystemLaunchAgentsCollector new];
  
  [systemAgents collect];

  LaunchDaemonsCollector * daemons = 
    [LaunchDaemonsCollector new];
  
  [daemons collect];
  
  LaunchAgentsCollector * agents = 
    [LaunchAgentsCollector new];
  
  [agents collect];

  UserLaunchAgentsCollector * userAgents = 
    [UserLaunchAgentsCollector new];
  
  [userAgents collect];

  NSLog(@"%@", systemDaemons.result.string);
  NSLog(@"%@", systemAgents.result.string);

  NSLog(@"%@", daemons.result.string);
  NSLog(@"%@", agents.result.string);

  NSLog(@"%@", userAgents.result.string);
  }

- (void) testSafariCollector 
  {
  SafariExtensionsCollector * collector = 
    [SafariExtensionsCollector new];
  
  [collector collect];
  
  NSAttributedString * result = collector.result;
  
  NSLog(@"Output: %@", result.string);
  }

- (void) testAdwareCollector 
  {
  Model * model = [Model model];
  
  [[model adware] simulate];
  
  LaunchDaemonsCollector * launchdCollector = 
    [LaunchDaemonsCollector new];
  
  [launchdCollector collect];

  SafariExtensionsCollector * safariCollector = 
    [SafariExtensionsCollector new];
  
  [safariCollector collect];
  
  AdwareCollector * adwareCollector = 
    [AdwareCollector new];
  
  [adwareCollector collect];

  NSAttributedString * result = adwareCollector.result;
  
  NSLog(@"Output: %@", result.string);
  }
  
- (void) testUnsignedCollector 
  {
  [[Model model] setIgnoreKnownAppleFailures: true];
  
  SystemLaunchDaemonsCollector * systemDaemons = 
    [SystemLaunchDaemonsCollector new];
  
  [systemDaemons collect];
  
  SystemLaunchAgentsCollector * systemAgents = 
    [SystemLaunchAgentsCollector new];
  
  [systemAgents collect];

  LaunchDaemonsCollector * daemons = 
    [LaunchDaemonsCollector new];
  
  [daemons collect];
  
  LaunchAgentsCollector * agents = 
    [LaunchAgentsCollector new];
  
  [agents collect];

  UserLaunchAgentsCollector * userAgents = 
    [UserLaunchAgentsCollector new];
  
  [userAgents collect];

  UnsignedCollector * collector = 
    [UnsignedCollector new];
  
  [collector collect];

  NSLog(@"%@", collector.result.string);
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
