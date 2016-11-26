/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "HiddenAppsCollector.h"
#import "Utilities.h"
#import "LaunchdCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "SubProcess.h"

@interface LaunchdCollector ()

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSMutableDictionary *) info
  for: (NSString *) path;

// Format adware.
- (NSAttributedString *) formatAdware: (NSDictionary *) info
  for: (NSString *) path;

@end

// Collect "other" files like modern login items.
@implementation HiddenAppsCollector

@synthesize processes = myProcesses;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"hiddenapps";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.processes = nil;
  
  [super dealloc];
  }

// Collect user launch agents.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for hidden apps", NULL)];

  // Make sure the base class is setup.
  [super collect];

  [self collectProcesses];
  
  [self collectHiddenApps];
  
  [self printHiddenApps];

  dispatch_semaphore_signal(self.complete);
  }

// Collect all running processes.
- (void) collectProcesses
  {
  NSMutableDictionary * currentProcesses = [NSMutableDictionary dictionary];
    
  NSArray * args = @[ @"-raxww", @"-o", @"pid, comm" ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/bin/ps" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      if([line hasPrefix: @"STAT"])
        continue;

      NSNumber * pid = nil;
      NSString * command = nil;

      [self parsePs: line pid: & pid command: & command];
      
      if(pid && command)
        [currentProcesses setObject: command forKey: pid];
      }
    }
    
  [subProcess release];
    
  myProcesses = [currentProcesses copy];
  }

// Parse a line from the ps command.
- (void) parsePs: (NSString *) line
  pid: (NSNumber **) pid
  command: (NSString **) command
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];

  NSInteger pidValue;
  
  bool found = [scanner scanInteger: & pidValue];

  if(!found)
    return;

  *pid = [NSNumber numberWithInteger: pidValue];
  
  [scanner scanUpToString: @"\n" intoString: command];
  }

// Collect apps that weren't printed elsewhere.
- (void) collectHiddenApps
  {
  for(NSString * bundleID in [self.launchdStatus allKeys])
    {
    NSMutableDictionary * status =
      [self collectJobStatusForLabel: bundleID];
    
    [self updateDynamicStatus: status];
    
    [self updateAppleCounts: status];
    }
  }

// Print apps that weren't printed elsewhere.
- (void) printHiddenApps
  {
  bool titlePrinted = NO;
  bool unprintedItems = NO;
  
  NSArray * sortedBundleIDs =
    [[self.launchdStatus allKeys]
      sortedArrayUsingSelector: @selector(compare:)];

  for(NSString * bundleID in sortedBundleIDs)
    {
    NSMutableDictionary * status =
      [self collectJobStatusForLabel: bundleID];
    
    if([[status objectForKey: kPrinted] boolValue])
      continue;
      
    if([[status objectForKey: kIgnored] boolValue])
      continue;
      
    if(!titlePrinted)
      {
      [self.result appendAttributedString: [self buildTitle]];
      titlePrinted = YES;
      }
      
    [self.result
      appendAttributedString: [self formatPropertyListStatus: status]];
    
    [self.result appendString: bundleID];
    
    // Add any extra content.
    [self.result
      appendAttributedString: [self formatExtraContent: status for: nil]];
      
    [self.result appendString: @"\n"];
  
    unprintedItems = YES;
    }
    
  if([[Model model] hideAppleTasks])
    {
    if(!titlePrinted)
      [self.result appendAttributedString: [self buildTitle]];
     
    if([self formatAppleCounts: self.result])
      unprintedItems = YES;
    }
    
  if(unprintedItems)
    [self.result appendCR];
  }

// Get a status and expand with all the information I can find.
- (void) updateDynamicStatus: (NSMutableDictionary *) status
  {
  [self updateDynamicTask: status];
  
  // I'm only guaranteed of having a Label here, not necessarily a
  // bundle ID.
  NSString * label = [status objectForKey: @"Label"];
  
  NSNumber * ignore =
    [NSNumber numberWithBool: [[Model model] hideAppleTasks]];
  
  NSString * executable =
    [self getExecutableForBundle: label status: status];
    
  bool isApple = [self isAppleFile: executable];
  
  [status setObject: [NSNumber numberWithBool: isApple] forKey: kApple];

  if(isApple)
    {
    // Sometimes these don't have executables.
    if(!executable)
      {
      [status setObject: ignore forKey: kIgnored];
      
      return;
      }
      
    NSString * signature = [Utilities checkAppleExecutable: executable];
    
    [status setObject: signature forKey: kSignature];
    
    // Should I ignore this failure?
    if([self hasExpectedSignature: label signature: signature])
      [status setObject: ignore forKey: kIgnored];
    }
  else
    {
    [status
      setObject: [Utilities checkExecutable: executable]
      forKey: kSignature];
      
    if([self ignoreTask: label])
      [status setObject: [NSNumber numberWithBool: YES] forKey: kIgnored];
    }
  }

// Get the executable for the app.
- (NSString *) getExecutableForBundle: (NSString *) bundleID
  status: (NSMutableDictionary *) status
  {
  NSString * executable = nil;
  NSArray * command = [status objectForKey: kCommand];
  
  if(!command)
    {
    command = [self collectLaunchdItemCommand: status];
    
    if([command count])
      {
      executable = [self collectLaunchdItemExecutable: command];

      if([executable length])
        {
        [status setObject: command forKey: kCommand];
        [status setObject: executable forKey: kExecutable];
        }
      }
    }
    
  executable = [status objectForKey: kExecutable];
  
  // Next try NSWorkspace.
  if(![executable length])
    executable =
      [[NSWorkspace sharedWorkspace]
        absolutePathForAppBundleWithIdentifier: bundleID];
    
  // Now try ps.
  if(![executable length])
    executable = [self.processes objectForKey: [status objectForKey: kPID]];
    
  if([executable length] && ![command count])
    {
    [status setObject: executable forKey: kExecutable];
    [status
      setObject: [NSArray arrayWithObject: executable] forKey: kCommand];
    }
    
  return executable;
  }

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSMutableDictionary *) info
  for: (NSString *) path
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  [extra autorelease];
  
  if([path length])
    {
    // I need to check again for adware due to the agent/daemon/helper
    // adware trio.
    [[Model model] checkForAdware: path];
    
    if([[info objectForKey: @"adware"] boolValue])
      {
      [extra appendAttributedString: [self formatAdware: info for: path]];
      
      return extra;
      }
    }
    
  [extra
    appendAttributedString: [self formatSignature: info forPath: path]];
  [extra appendAttributedString: [self formatSupportLink: info]];
    
  return extra;
  }

// This area needs more relaxed rules because Apple hides this information.
- (bool) ignoreTask: (NSString *) label
  {
  if([[[Model model] appleLaunchdByLabel] objectForKey: label] != nil)
    return YES;
    
  //if([label hasPrefix: @"com.apple."])
  //  return YES;
    
  if([[Model model] majorOSVersion] < kYosemite)
    {
    if([label hasPrefix: @"0x"])
      {
      if([label rangeOfString: @".anonymous."].location != NSNotFound)
        return YES;
      }
    else if([label hasPrefix: @"[0x"])
      {
      if([label rangeOfString: @".com.apple."].location != NSNotFound)
        return YES;
      }
    }
    
  if([[Model model] majorOSVersion] < kLion)
    {
    if([label hasPrefix: @"0x"])
      if([label rangeOfString: @".mach_init."].location != NSNotFound)
        return YES;
    }

  return NO;
  }

// Does this file have the expected signature?
- (bool) hasExpectedSignature: (NSString *) label
  signature: (NSString *) signature
  {
  if(![[Model model] showSignatureFailures])
    return YES;
    
  NSString * expectedSignature =
    [[[Model model] appleSoftware] objectForKey: label];
  
  if([expectedSignature length] > 0)
    return [signature isEqualToString: expectedSignature];
    
  return NO;
  }

@end
