/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LaunchdCollector.h"
#import <ServiceManagement/ServiceManagement.h>
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSDictionary+Etresoft.h"
#import "TTTLocalizedPluralString.h"
#import "NSDate+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "SearchEngine.h"

@implementation LaunchdCollector

// These need to be shared by all launchd collector objects.
@dynamic launchdStatus;
@dynamic appleLaunchd;
@synthesize showExecutable = myShowExecutable;
@synthesize pressureKilledCount = myPressureKilledCount;
@synthesize AppleNotLoadedCount = myAppleNotLoadedCount;
@synthesize AppleLoadedCount = myAppleLoadedCount;
@synthesize AppleRunningCount = myAppleRunningCount;
@synthesize AppleKilledCount = myAppleKilledCount;
@dynamic knownAppleFailures;

#pragma mark - Properties

// Property accessors to route through a singleton.
- (NSMutableDictionary *) launchdStatus
  {
  return [LaunchdCollector launchdStatus];
  }

- (NSMutableSet *) appleLaunchd
  {
  return [LaunchdCollector appleLaunchd];
  }

- (NSMutableSet *) knownAppleFailures
  {
  return [LaunchdCollector knownAppleFailures];
  }

// Singleton accessor for launchd status.
+ (NSMutableDictionary *) launchdStatus
  {
  static NSMutableDictionary * dictionary = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     dictionary = [NSMutableDictionary new];
    });
    
  return dictionary;
  }

// Singleton access for Apple launchd items.
+ (NSMutableSet *) appleLaunchd
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Singleton access for Apple known filure items.
+ (NSMutableSet *) knownAppleFailures
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Singleton access for Apple known signature failure items.
+ (NSMutableSet *) knownAppleSignatureFailures
  {
  static NSMutableSet * set = nil;
  
  static dispatch_once_t onceToken;

  dispatch_once(
    & onceToken,
    ^{
     set = [NSMutableSet new];
    });
    
  return set;
  }

// Release memory.
+ (void) cleanup
  {
  [[LaunchdCollector launchdStatus] release];
  [[LaunchdCollector appleLaunchd] release];
  }

#pragma mark - Launchd routines

// Collect the status of all launchd items.
- (void) performCollection
  {
  // Don't do this more than once.
  if([self.launchdStatus count])
    return;
    
  [self
    updateStatus: NSLocalizedString(@"Checking launchd information", NULL)];
  
  // Collect all launchd items.
  [self collectLaunchdStatus: kSMDomainSystemLaunchd];

  [self collectLaunchdStatus: kSMDomainUserLaunchd];
  
  // Add expected items that ship with the OS.
  [self setupExpectedItems];
  }

// Collect launchd status for a particular domain.
- (void) collectLaunchdStatus: (CFStringRef) domain
  {
  // Get the last exist result for all jobs in this domain.
  CFArrayRef jobs = SMCopyAllJobDictionaries(domain);

  if(!jobs)
    return;

  for(NSDictionary * job in (NSArray *)jobs)
    {
    NSString * label = [job objectForKey: @"Label"];
    
    if(label)
      if(![self.launchdStatus objectForKey: label])
        {
        NSMutableDictionary * jobData =
          [NSMutableDictionary dictionaryWithDictionary: job];
        
        // I don't want all of the keys, only a few.
        NSNumber * lastExitStatus =
          [jobData objectForKey: @"LastExitStatus"];
        NSNumber * PID =
          [jobData objectForKey: @"PID"];
        
        NSMutableDictionary * status = [NSMutableDictionary new];
        
        [status setObject: label forKey: kLabel];
        [status setObject: [NSNumber numberWithBool: NO] forKey: kPrinted];
        [status setObject: [NSNumber numberWithBool: NO] forKey: kIgnored];
        
        if(lastExitStatus)
          [status setObject: lastExitStatus forKey: @"LastExitStatus"];
    
        if(PID)
          [status setObject: PID forKey: @"PID"];

        [self.launchdStatus setObject: status forKey: label];
        
        [status release];
        }
    }
    
  CFRelease(jobs);
  }

#pragma mark - Expected items

// Setup launchd items that are expected because they ship with the OS.
- (void) setupExpectedItems
  {
  [self setupKnownAppleFailures];
  }

// Setup known Apple failures.
- (void) setupKnownAppleFailures
  {
  [self.knownAppleFailures addObject: @"com.apple.mtrecorder.plist"];
  [self.knownAppleFailures addObject: @"com.apple.spirecorder.plist"];
  [self.knownAppleFailures addObject: @"com.apple.MRTd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.MRTa.plist"];
  [self.knownAppleFailures addObject: @"com.apple.logd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.xprotectupdater.plist"];
  [self.knownAppleFailures addObject: @"com.apple.xprotectupdater.plist"];
  [self.knownAppleFailures addObject: @"com.apple.afpstat.plist"];
  [self.knownAppleFailures
    addObject: @"com.apple.KerberosHelper.LKDCHelper.plist"];
  [self.knownAppleFailures addObject: @"com.apple.emond.aslmanager.plist"];
  [self.knownAppleFailures addObject: @"com.apple.mrt.uiagent.plist"];
  [self.knownAppleFailures addObject: @"com.apple.accountsd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.wdhelper.plist"];
  [self.knownAppleFailures addObject: @"com.apple.suhelperd.plist"];
  [self.knownAppleFailures addObject: @"com.apple.Kerberos.renew.plist"];
  [self.knownAppleFailures addObject: @"org.samba.winbindd.plist"];
  [self.knownAppleFailures
    addObject: @"com.apple.Kerberos.digest-service.plist"];
  [self.knownAppleFailures
    addObject: @"com.apple.mobile.keybagd.plist"];
  [self.knownAppleFailures
    addObject: @"com.apple.SafariBookmarksSyncer.plist"];
  }

#pragma mark - Collection

// Collect property list files.
// Returns an array of labels for printing.
- (NSArray *) collectPropertyListFiles: (NSArray *) paths
  {
  NSMutableArray * plists = [NSMutableArray array];
  
  for(NSString * path in paths)
    {
    NSMutableDictionary * plist = [self collectPropertyListFile: path];
    
    if(plist)
      [plists addObject: plist];
    }
    
  return plists;
  }

// Collect a single property list file.
- (NSMutableDictionary *) collectPropertyListFile: (NSString *) path
  {
  NSString * file = [path lastPathComponent];
  
  // Ignore .DS_Store files.
  if([file isEqualToString: @".DS_Store"])
    return nil;
    
  // Ignore zero-byte files.
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
  
  if([attributes fileSize] == 0)
    return nil;
    
  // Collect the info.
  return [self collectLaunchdItemInfo: path];
  }

// Collect the status of a launchd item.
- (NSMutableDictionary *) collectLaunchdItemInfo: (NSString *) path
  {
  // I need this.
  NSString * filename = [path lastPathComponent];
  
  // Get the status and plist and use them to seed the info.
  NSMutableDictionary * info =
    [NSMutableDictionary
      dictionaryWithDictionary: [self collectJobStatus: path]];
    
  // Set attributes.
  [info setObject: path forKey: kPath];
  
  [info setObject: filename forKey: kFilename];
  
  if([filename hasPrefix: @"."])
    [info setObject: [NSNumber numberWithBool: YES] forKey: kHidden];
    
  NSDate * modificationDate = [self modificationDate: path];
  
  if(modificationDate)
    [info setObject: modificationDate forKey: kModificationDate];

  [self setDetailsURL: info];
  [self setExecutable: info];
  
  [[[Model model] launchdFiles] setObject: info forKey: path];

  if([[[Model model] appleLaunchd] objectForKey: path])
    {
    [info setObject: [NSNumber numberWithBool: YES] forKey: kApple];
    
    [self checkAppleSignature: info];
    }
  else
    {
    // Check for a new Apple file.
    NSString * label = [info objectForKey: kLabel];
    
    if([label hasPrefix: @"com.apple."])
      {
      [self checkAppleSignature: info];
      
      NSString * signature = [info objectForKey: kSignature];
      
      if([signature isEqualToString: kSignatureApple])
        {
        [info setObject: [NSNumber numberWithBool: YES] forKey: kApple];
        
        return info;
        }
      else if([signature isEqualToString: kExecutableMissing])
        return info;
      }
      
    [info
      setObject: [self getSupportURLFor: info name: nil bundleID: path]
      forKey: kSupportURL];
    
    [self checkSignature: info];
    
    // See if this is a file I know about, either good or bad.
    [self checkForKnownFile: path info: info];
    }
    
  return info;
  }

// Get the job status.
- (NSMutableDictionary *) collectJobStatus: (NSString *) path
  {
  // Get the properties.
  NSDictionary * plist = [NSDictionary readPropertyList: path];

  if(plist)
    {
    NSMutableDictionary * info =
      [NSMutableDictionary dictionaryWithDictionary: plist];
    
    NSString * label = [plist objectForKey: @"Label"];
      
    if(label)
      {
      NSMutableDictionary * status =
        [self collectJobStatusForLabel: label];
      
      [info addEntriesFromDictionary: status];
      
      return info;
      }
    }
    
  return nil;
  }

// Collect the job status for a label.
- (NSMutableDictionary *) collectJobStatusForLabel: (NSString *) label
  {
  NSMutableDictionary * status =
    [self.launchdStatus objectForKey: label];

  NSNumber * pid = [status objectForKey: @"PID"];
  NSNumber * lastExitStatus = [status objectForKey: @"LastExitStatus"];

  long exitStatus = [lastExitStatus intValue];
  
  NSString * jobStatus = kStatusUnknown;

  if(pid)
    jobStatus = kStatusRunning;
  else if(exitStatus == 172)
    {
    jobStatus = kStatusKilled;
    
    self.pressureKilledCount = self.pressureKilledCount + 1;
    }
  else if(exitStatus != 0)
    jobStatus = kStatusFailed;
  else if(status)
    jobStatus = kStatusLoaded;
  else
    jobStatus = kStatusNotLoaded;
    
  // I need to check for status == nil for "not loaded", so I have
  // to wait to create a new status in that case.
  if(!status)
    {
    status = [NSMutableDictionary new];
    [self.launchdStatus setObject: status forKey: label];
    [status release];
    }
    
  NSString * currentStatus = [status objectForKey: kStatus];
  
  if([currentStatus length] > 0)
    [status
      setObject: [NSNumber numberWithBool: YES] forKey: kStatusDuplicate];
    
  [status setObject: jobStatus forKey: kStatus];
  [status setObject: label forKey: kLabel];
  
  return status;
  }

// Is this an Apple file that I expect to see?
- (bool) isAppleFile: (NSString *) path
  {
  return [[Model model] isKnownAppleExecutable: path];
  }

// Should I hide Apple tasks?
- (bool) hideAppleTasks
  {
  return [[Model model] hideAppleTasks];
  }

// Try to construct a support URL.
- (NSString *) getSupportURLFor: (NSDictionary *) info
  name: (NSString *) name bundleID: (NSString *) path
  {
  NSString * bundleID = [path lastPathComponent];
  
  // See if I can construct a real web host.
  NSString * host = [self convertBundleIdToHost: bundleID];
  
  if(host)
    {
    // If I seem to have a web host, construct a support URL just for that
    // site.
    NSString * nameParameter =
      [name length]
        ? name
        : bundleID;

    return
      [NSString
        stringWithFormat:
          @"%@%@+support+site:%@",
          [SearchEngine searchEngineURL], nameParameter, host];
    }
  
  // This file isn't following standard conventions. Look for uninstall
  // instructions.
  return
    [NSString
      stringWithFormat:
        @"%@%@+uninstall+support", [SearchEngine searchEngineURL], bundleID];
  }

// Set the details URL.
- (void) setDetailsURL: (NSMutableDictionary *) info
  {
  NSAttributedString * detailsURL = nil;
  
  NSString * jobStatus = [info objectForKey: kStatus];
  
  if([jobStatus isEqualToString: kStatusFailed])
    {
    NSString * executableName =
      [[info objectForKey: kExecutable] lastPathComponent];

    if([[Model model] hasLogEntries: executableName])
      detailsURL = [[Model model] getDetailsURLFor: executableName];
    }
    
  if(detailsURL)
    [info setObject: detailsURL forKey: kDetailsURL];
  }

// Set command and executable information.
- (void) setExecutable: (NSMutableDictionary *) info
  {
  // Get the command.
  NSArray * command = [self collectLaunchdItemCommand: info];
  
  if([command count])
    {
    // Get the executable.
    NSString * executable = [self collectLaunchdItemExecutable: command];
  
    if([executable length])
      {
      [info setObject: command forKey: kCommand];
      [info setObject: executable forKey: kExecutable];
      [self updateModificationDate: info path: executable];

      [info
        setObject: [NSNumber numberWithBool: [self isAppleFile: executable]]
        forKey: kApple];
      }
    }
  }

// Collect the command of the launchd item.
- (NSArray *) collectLaunchdItemCommand: (NSDictionary *) info
  {
  NSMutableArray * command = [NSMutableArray array];
  
  if(info)
    {
    NSString * program = [info objectForKey: @"Program"];
    
    if(program)
      [command addObject: program];
      
    NSArray * arguments = [info objectForKey: @"ProgramArguments"];
    
    if([arguments respondsToSelector: @selector(isEqualToArray:)])
      if(arguments.count > 0)
        {
        NSString * argument = [arguments objectAtIndex: 0];
        
        if([command count] == 0)
          [command addObject: argument];
          
        for(int i = 1; i < arguments.count; ++i)
          [command addObject: [arguments objectAtIndex: i]];
      }
    }
    
  return command;
  }

// Collect the actual executable from a command.
- (NSString *) collectLaunchdItemExecutable: (NSArray *) command
  {
  NSString * executable = [command firstObject];
  
  if(![executable hasPrefix: @"/"])
    executable = [self resolveRelativeExecutable: executable];
    
  BOOL sandboxExec = NO;
  
  if([executable isEqualToString: @"/usr/bin/sandbox-exec"])
    sandboxExec = YES;
    
  if(sandboxExec)
    {
    NSUInteger argumentCount = command.count;
    
    for(NSUInteger i = 1; i < argumentCount; ++i)
      {
      NSString * argument = [command objectAtIndex: i];
      
      if([argument isEqualToString: @"-f"])
        ++i;
      else if([argument isEqualToString: @"-n"])
        ++i;
      else if([argument isEqualToString: @"-p"])
        ++i;
      else if([argument isEqualToString: @"-D"])
        ++i;
      else
        {
        executable = argument;
        break;
        }
      }
    }
    
  return executable;
  }

// Resolve a relative executable as per launchd.plist man page.
- (NSString *) resolveRelativeExecutable: (NSString *) executable
  {
  NSString * absoluteExecutable =
    [@"/usr/bin" stringByAppendingPathComponent: executable];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    return absoluteExecutable;
    
  absoluteExecutable = [@"/bin" stringByAppendingPathComponent: executable];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    return absoluteExecutable;

  absoluteExecutable =
    [@"/usr/sbin" stringByAppendingPathComponent: executable];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    return absoluteExecutable;
    
  absoluteExecutable =
    [@"/sbin" stringByAppendingPathComponent: executable];
    
  if([[NSFileManager defaultManager] fileExistsAtPath: absoluteExecutable])
    return absoluteExecutable;
    
  return executable;
  }
  
// Collect the signagure of an Apple launchd item.
- (void) checkAppleSignature: (NSMutableDictionary *) info
  {
  if(![info objectForKey: kSignature])
    {
    NSString * executable = [info objectForKey: kExecutable];

    if([executable length] > 0)
      [info
        setObject: [Utilities checkAppleExecutable: executable]
        forKey: kSignature];
    }
  }

// Collect the signagure of a launchd item.
- (void) checkSignature: (NSMutableDictionary *) info
  {
  if(![info objectForKey: kSignature])
    {
    NSString * executable = [info objectForKey: kExecutable];

    if([executable length] > 0)
      [info
        setObject: [Utilities checkExecutable: executable]
        forKey: kSignature];
    }
  }

// See if this is a file I know about, either good or bad.
- (void) checkForKnownFile: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  // I need this.
  NSString * filename = [path lastPathComponent];
  
  // See if this file is known (whitelist or adware). If not, double-check
  // to see if it should be exempted from unknown files.
  // This will record adware as a side effect.
  bool knownFile = [[Model model] isKnownFile: filename path: path];
  
  if(!knownFile)
    if([self isWhitelistException: info path: path])
      knownFile = YES;
    
  [info
    setObject: [NSNumber numberWithBool: !knownFile] forKey: kUnknown];
  }

// Remove any files from the list of unknown files if they match certain
// criteria.
- (bool) isWhitelistException: (NSMutableDictionary *) info
  path: (NSString *) path
  {
  bool whitelist = NO;
  
  // Special case for Folder Actions Dispatcher.
  NSArray * command = [info objectForKey: kCommand];

  for(NSString * part in command)
    {
    NSRange foundRange = [part rangeOfString: @"Folder Actions Dispatcher"];
    
    if(foundRange.location != NSNotFound)
      whitelist = true;
    }
    
  if(whitelist)
    [info removeObjectForKey: kUnknown];
    
  return whitelist;
  }

#pragma mark - Print property lists

// Print property lists files.
- (void) printPropertyLists: (NSArray *) plists
  {
  NSMutableAttributedString * formattedOutput =
    [self formatPropertyLists: plists];

  if(formattedOutput)
    {
    [self.result appendAttributedString: [self buildTitle]];

    [self.result appendAttributedString: formattedOutput];

    if(self.pressureKilledCount)
      [self.result
        appendString:
          TTTLocalizedPluralString(
            self.pressureKilledCount, @"pressurekilledcount", nil)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    
    if(!self.launchdStatus)
      [self.result
        appendString:
          NSLocalizedString(
            @"    Launchd job status not available.\n", NULL)
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    
    [self.result appendCR];
    }
  }

// Format a list of files.
- (NSMutableAttributedString *) formatPropertyLists: (NSArray *) plists
  {
  NSMutableAttributedString * formattedOutput =
    [NSMutableAttributedString new];

  [formattedOutput autorelease];
  
  bool haveOutput = NO;
  
  NSArray * sortedPlists =
    [plists
      sortedArrayUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
          {
          NSString * name1 = [obj1 objectForKey: kPath];
          NSString * name2 = [obj2 objectForKey: kPath];

          return [name1 compare: name2];
          }];
    
  for(NSMutableDictionary * plist in sortedPlists)
    if([self formatPropertyList: plist output: formattedOutput])
      haveOutput = YES;
      
  if([[Model model] hideAppleTasks])
    if([self formatAppleCounts: formattedOutput])
      haveOutput = YES;
  
  if(!haveOutput)
    return nil;
    
  return formattedOutput;
  }

// Format property list file.
// Return YES if there was any output.
- (bool) formatPropertyList: (NSMutableDictionary *) info
  output: (NSMutableAttributedString *) output
  {
  NSString * path = [info objectForKey: kPath];

  NSString * file = [path lastPathComponent];
  
  // Ignore .DS_Store files.
  if([file isEqualToString: @".DS_Store"])
    return NO;
    
  // Ignore zero-byte files.
  NSDictionary * attributes =
    [[NSFileManager defaultManager]
      attributesOfItemAtPath: path error: NULL];
  
  if([attributes fileSize] == 0)
    return NO;
    
  // It is a plist file at least.
  return
    [self
      formatValidPropertyListFile: path
      info: (NSMutableDictionary *) info
      output: output];
  }

// Format a valid property list file.
- (bool) formatValidPropertyListFile: (NSString *) path
  info: (NSMutableDictionary *) info
  output: (NSMutableAttributedString *) output
  {
  NSDate * modificationDate = [self modificationDate: path];
  
  if(modificationDate)
    [info setObject: modificationDate forKey: kModificationDate];

  bool knownFailure =
    [self.knownAppleFailures containsObject: [path lastPathComponent]];
  
  if(knownFailure)
    [info setObject: [NSNumber numberWithBool: YES] forKey: kKnownFailure];

  [self emitPropertyListXML: path info: info];
  
  // Apples file get special treatment.
  if([[info objectForKey: kApple] boolValue])
    if(![self formatApplePropertyListFile: path info: info])
      {
      [self updateAppleCounts: info];
  
      return NO;
      }
      
  NSString * filename = [info objectForKey: kFilename];

  // Format the status.
  [output appendAttributedString: [self formatPropertyListStatus: info]];
  
  // Add the name.
  [output appendString: [Utilities prettyPath: filename]];
  
  // Add any extra content.
  [output
    appendAttributedString: [self formatExtraContent: info for: path]];
  
  [output appendString: @"\n"];
  
  NSString * label = [info objectForKey: kLabel];
  
  NSMutableDictionary * status = [self.launchdStatus objectForKey: label];
  
  [status setObject: [NSNumber numberWithBool: YES] forKey: kPrinted];
  
  return YES;
  }

// Format an Apple property list file.
// Returns NO if the Apple task should be hidden.
- (bool) formatApplePropertyListFile: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  // Does the user want to hide Apple tasks? 3rd party and user domains
  // always return NO.
  bool hideAppleTasks = [self hideAppleTasks];

  NSString * signature = [info objectForKey: kSignature];
  NSNumber * ignore = [NSNumber numberWithBool: hideAppleTasks];
    
  NSString * label = [info objectForKey: kLabel];
  NSMutableDictionary * status = [self.launchdStatus objectForKey: label];
  
  // I may want to report a failure.
  if([[info objectForKey: kStatus] isEqualToString: kStatusFailed])
    {
    bool knownFailure = [[info objectForKey: kKnownFailure] boolValue];
    
    // Should I ignore this failure?
    if(knownFailure || [[Model model] ignoreKnownAppleFailures])
      {
      [status setObject: ignore forKey: kIgnored];

      if(hideAppleTasks)
        return NO;
      }
    }
    
  // These will be rolled up normally.
  else if([[info objectForKey: kStatus] isEqualToString: kStatusKilled])
    {
    [status setObject: ignore forKey: kIgnored];
    
    if(hideAppleTasks)
      return NO;
    }
    
  // Does the file have an expected signature
  else if([self hasExpectedSignature: path signature: signature])
    {
    // If the user has turned off ignore known failures, maybe an expected
    // signature isn't good enough.
    if(![[Model model] ignoreKnownAppleFailures])
      {
      // These aren't errors.
      if([signature isEqualToString: kSignatureApple])
        {
        }
      else if([signature isEqualToString: kSignatureValid])
        {
        }
      else if([signature isEqualToString: kShell])
        {
        }
        
      // These are errors.
      else if([signature isEqualToString: kExecutableMissing])
        return YES;
        
      // Anything else will cause the item to be printed.
      else if((signature != nil) && [[Model model] showSignatureFailures])
        return YES;
      }
      
    [status setObject: ignore forKey: kIgnored];

    if(hideAppleTasks)
      return NO;
    }
    
  return YES;
  }

// Format Apple counts.
// Return YES if there was any output.
- (bool) formatAppleCounts: (NSMutableAttributedString *) output
  {
  bool haveOutput = NO;
  
  haveOutput =
    [self
      formatAppleCount: self.AppleNotLoadedCount
      output: output
      status: kStatusNotLoaded]
      || haveOutput;
  
  haveOutput =
    [self
      formatAppleCount: self.AppleLoadedCount
      output: output
      status: kStatusLoaded]
      || haveOutput;

  haveOutput =
    [self
      formatAppleCount: self.AppleRunningCount
      output: output
      status: kStatusRunning]
      || haveOutput;

  haveOutput =
    [self
      formatAppleCount: self.AppleKilledCount
      output: output
      status: kStatusKilled]
      || haveOutput;

  return haveOutput;
  }

// Format Apple counts for a given status.
// Return YES if there was any output.
- (bool) formatAppleCount: (NSUInteger) count
  output: (NSMutableAttributedString *) output
  status: (NSString *) statusString
  {
  if(count)
    {
    NSDictionary * status =
      [NSDictionary
        dictionaryWithObjectsAndKeys: statusString, kStatus, nil];
      
    [output
      appendAttributedString: [self formatPropertyListStatus: status]];
    
    [output
      appendString: TTTLocalizedPluralString(count, @"applecount", nil)];
    
    [output appendString: @"\n"];
      
    return YES;
    }
    
  return NO;
  }

// Handle whitelist exceptions.
- (void) updateAppleCounts: (NSDictionary *) info
  {
  if([[info objectForKey: kStatus] isEqualToString: kStatusNotLoaded])
    self.AppleNotLoadedCount = self.AppleNotLoadedCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusLoaded])
    self.AppleLoadedCount = self.AppleLoadedCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusRunning])
    self.AppleRunningCount = self.AppleRunningCount + 1;
  else if([[info objectForKey: kStatus] isEqualToString: kStatusKilled])
    self.AppleKilledCount = self.AppleKilledCount + 1;
  }

// Does this file have the expected signature?
- (bool) hasExpectedSignature: (NSString *) file
  signature: (NSString *) signature
  {
  if(![[Model model] showSignatureFailures])
    return YES;
    
  NSDictionary * info = [[[Model model] appleLaunchd] objectForKey: file];
  
  if(info)
    {
    NSString * expectedSignature = [info objectForKey: kSignature];
    
    if([expectedSignature length] > 0)
      return [signature isEqualToString: expectedSignature];
    
    // Apple is now putting "other stuff" in launchd plist files.
    else if([signature length] == 0)
      return YES;
    }
    
  return NO;
  }


// Update the modification date.
- (void) updateModificationDate: (NSMutableDictionary *) status
  path: (NSString *) path
  {
  NSDate * currentModificationDate =
    [status objectForKey: kModificationDate];
  
  NSDate * modificationDate = [self modificationDate: path];
  
  if([modificationDate isLaterThan: currentModificationDate])
    [status setObject: modificationDate forKey: kModificationDate];
  }

// Update the modification date.
- (void) updateModificationDate: (NSMutableDictionary *) info
  bundleID: (NSString *) bundleID
  {
  NSURL * url =
    [[NSWorkspace sharedWorkspace]
      URLForApplicationWithBundleIdentifier: bundleID];
    
  if(url)
    [self updateModificationDate: info path: [url path]];
  }

// Get the modification date of a file.
- (NSDate *) modificationDate: (NSString *) path
  {
  NSRange appRange = [path rangeOfString: @".app/Contents/MacOS/"];
  
  if(appRange.location != NSNotFound)
    path = [path substringToIndex: appRange.location + 4];

  return [Utilities modificationDate: path];
  }

// Is the executable valid?
- (bool) isValidExecutable: (NSArray *) executable
  {
  NSString * program = [executable firstObject];
  
  if(program)
    {
    NSDictionary * attributes = [Utilities lookForFileAttributes: program];
    
    if(attributes)
      {
      NSUInteger permissions = attributes.filePosixPermissions;
      
      if(permissions & S_IXUSR)
        return YES;
        
      if(permissions & S_IXGRP)
        return YES;

      if(permissions & S_IXOTH)
        return YES;
      }
      //if([[NSFileManager defaultManager] isExecutableFileAtPath: program])
      //  return YES;
    }
    
  return NO;
  }

// Format a status string.
- (NSAttributedString *) formatPropertyListStatus: (NSDictionary *) info
  {
  NSString * statusString = NSLocalizedString(@"[not loaded]", NULL);
  NSColor * color = [[Utilities shared] gray];
  
  NSString * statusCode = [info objectForKey: kStatus];
  
  if([statusCode isEqualToString: kStatusLoaded])
    {
    statusString = NSLocalizedString(@"[loaded]", NULL);
    color = [[Utilities shared] blue];
    }
  else if([statusCode isEqualToString: kStatusRunning])
    {
    statusString = NSLocalizedString(@"[running]", NULL);
    color = [[Utilities shared] green];
    }
  else if([statusCode isEqualToString: kStatusFailed])
    {
    statusString = NSLocalizedString(@"[failed]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusUnknown])
    {
    statusString = NSLocalizedString(@"[unknown]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusInvalid])
    {
    statusString = NSLocalizedString(@"[invalid?]", NULL);
    color = [[Utilities shared] red];
    }
  else if([statusCode isEqualToString: kStatusKilled])
    {
    statusString = NSLocalizedString(@"[killed]", NULL);
    color = [[Utilities shared] red];
    }
  
  NSMutableAttributedString * output =
    [[NSMutableAttributedString alloc] init];
    
  [output
    appendString: [NSString stringWithFormat: @"    %@    ", statusString]
    attributes:
      @{
        NSForegroundColorAttributeName : color,
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  
  return [output autorelease];
  }

// Include any extra content that may be useful.
- (NSAttributedString *) formatExtraContent: (NSMutableDictionary *) info
  for: (NSString *) path
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  NSDate * modificationDate =
    [info objectForKey: kModificationDate];

  NSString * modificationDateString =
    [Utilities dateAsString: modificationDate format: @"yyyy-MM-dd"];
  
  if(modificationDateString)
    [extra
      appendString:
        [NSString stringWithFormat: @" (%@)", modificationDateString]];

  [extra autorelease];
  
  if([path length])
    {
    // I need to check again for adware due to the agent/daemon/helper
    // adware trio.
    [[Model model] checkForAdware: path];
    
    if([[info objectForKey: kAdware] boolValue])
      {
      [extra appendAttributedString: [self formatAdware: info for: path]];
      
      return extra;
      }
    }
    
  [extra
    appendAttributedString: [self formatSignature: info forPath: path]];
    
  return extra;
  }

// Format adware.
- (NSAttributedString *) formatAdware: (NSDictionary *) info
  for: (NSString *) path
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  [extra appendString: @" "];

  [extra
    appendString: NSLocalizedString(@"Adware!", NULL)
    attributes:
      @{
        NSForegroundColorAttributeName : [[Utilities shared] red],
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
    
  NSAttributedString * removeLink = [self generateRemoveAdwareLink];

  if(removeLink)
    {
    [extra appendString: @" "];
    
    [extra appendAttributedString: removeLink];
    }
    
  NSString * executable = [info objectForKey: kExecutable];
  
  if([executable length] > 0)
    if([[NSFileManager defaultManager] fileExistsAtPath: executable])
      {
      [extra appendString: @"\n        "];
      [extra appendString: [Utilities cleanPath: executable]];
      }
    
  return [extra autorelease];
  }

// Format a signature result.
- (NSAttributedString *) formatSignature: (NSDictionary *) info
  forPath: (NSString *) path
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  [extra autorelease];
  
  // If it isn't Apple append a useless support link.
  if(![[info objectForKey: kApple] boolValue])
    [extra appendAttributedString: [self formatSupportLink: info]];

  NSString * signature = [info objectForKey: kSignature];
  
  // These are good.
  if([signature isEqualToString: kSignatureApple])
    return extra;
    
  else if([signature isEqualToString: kSignatureValid])
    return extra;
    
  // The signature failure message.
  NSString * message = nil;
    
  // The executable is missing.
  if([signature isEqualToString: kExecutableMissing])
    {
    NSString * executable = [info objectForKey: kExecutable];
  
    if([path length])
      message =
        [NSString
          stringWithFormat:
            NSLocalizedString(@" - %@: Executable not found!", NULL),
            [Utilities cleanPath: executable]];
    else
      message =
        [NSString
          stringWithFormat:
            NSLocalizedString(@" - Executable not found!", NULL)];
    }
  else if([signature isEqualToString: kNotSigned])
    message = NSLocalizedString(@" - No signature!", NULL);
  else if([signature isEqualToString: kShell])
    message = NSLocalizedString(@" - Shell script!", NULL);
  else if([signature isEqualToString: kCodesignFailed])
    message = NSLocalizedString(@" - codesign failed!", NULL);
  else
    message = NSLocalizedString(@" - Invalid signature!", NULL);
    
  // If this is an Apple file things are complicated.
  if([[info objectForKey: kApple] boolValue])
    {
    // If I am ignoring known Apple failures,
    if([[Model model] ignoreKnownAppleFailures])
      {
      // And if this is one of those known Apple failures (or no failure),
      // then clear the failure, if any.
      if([self hasExpectedSignature: path signature: signature])
        message = nil;
      }
      
    // Else if I am not ignoring known Apple failures, then if I'm not
    // showing signature failures, clear the failure, if any.
    else if(![[Model model] showSignatureFailures])
      {
      // I still want to report things that aren't actual signature
      // failures.
      if([signature isEqualToString: kExecutableMissing])
        {
        }
      else
        message = nil;
      }
    }
    
  // Else if this is not an Apple file things aren't so complicated.
  // If I'm not showing signature failures, then clear the failure, if any.
  else if(![[Model model] showSignatureFailures])
    if(![signature isEqualToString: kExecutableMissing])
      message = nil;
    
  if([message length])
    [extra
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
  return extra;
  }

// Create a support link for a plist dictionary.
- (NSAttributedString *) formatSupportLink: (NSDictionary *) info
  {
  NSMutableAttributedString * extra =
    [[NSMutableAttributedString alloc] init];

  // Get the support link.
  if([[info objectForKey: kSupportURL] length])
    {
    [extra appendString: @" "];

    [extra
      appendString: NSLocalizedString(@"[Support]", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] blue],
          NSLinkAttributeName : [info objectForKey: kSupportURL]
        }];
    }
    
  // Get the details link.
  NSAttributedString * detailsURL = [info objectForKey: kDetailsURL];
  
  if([detailsURL length])
    {
    [extra appendString: @" "];

    [extra appendAttributedString: detailsURL];
    }

  // Show what is being hidden.
  if([[info objectForKey: kHidden] boolValue] || self.showExecutable)
    [extra appendString:
      [NSString
        stringWithFormat:
          @"\n        %@",
          [Utilities
            formatExecutable: [info objectForKey: kCommand]]]];
    
  return [extra autorelease];
  }

// Emit a property list as XML.
- (void) emitPropertyListXML: (NSString *) path
  info: (NSMutableDictionary *) info
  {
  [self.XML startElement: @"task"];
  
  NSString * status = [info objectForKey: kStatus];
  
  if([status length] == 0)
    status = @"notloaded";
    
  [self.XML addAttribute: @"status" value: status];
  
  if([[info objectForKey: kKnownFailure] boolValue])
    [self.XML addAttribute: @"knownfailure" boolValue: YES];

  NSString * signature = [info objectForKey: kSignature];

  if([signature isEqualToString: kShell])
    [self.XML addAttribute: @"analysis" value: signature];
  else if([signature isEqualToString: kExecutableMissing])
    {
    [self.XML addAttribute: @"analysis" value: signature];
    [self.XML
      addAttribute: @"severity_explanation" value: @"executablemissing"];
    }
  else
    [self.XML addAttribute: @"signature" value: signature];
    
  if([[info objectForKey: kApple] boolValue])
    [self.XML addAttribute: @"analysis" value: @"apple"];
  else if([[info objectForKey: kUnknown] boolValue])
    [self.XML addAttribute: @"analysis" value: @"unknown"];
  else if([[info objectForKey: @"adware"] boolValue])
    [self.XML addAttribute: @"analysis" value: @"adware"];
  
  NSString * safePath = [Utilities cleanPath: path];
  NSString * safeExecutable =
    [Utilities cleanPath: [info objectForKey: kExecutable]];
  
  [self.XML addElement: @"path" value: safePath];
  [self.XML addElement: @"name" value: [safePath lastPathComponent]];
  [self.XML addElement: @"label" value: [info objectForKey: kLabel]];
  [self.XML
    addElement: @"date" date: [info objectForKey: kModificationDate]];
  [self.XML
    addElement: @"executable" value: safeExecutable];
  [self.XML
    addElement: @"command"
    value: [Utilities formatExecutable: [info objectForKey: kCommand]]];
  
  [self.XML endElement: @"task"];
  }

@end
