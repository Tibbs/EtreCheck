/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "Checker.h"
#import "ApplicationsCollector.h"
#import "AudioPlugInsCollector.h"
#import "CPUUsageCollector.h"
#import "ConfigurationCollector.h"
#import "VirtualVolumeCollector.h"
#import "DiskCollector.h"
#import "FirewireCollector.h"
#import "FontsCollector.h"
#import "GatekeeperCollector.h"
#import "HardwareCollector.h"
#import "ITunesPlugInsCollector.h"
#import "InternetPlugInsCollector.h"
#import "KernelExtensionCollector.h"
#import "LaunchAgentsCollector.h"
#import "LaunchDaemonsCollector.h"
#import "LoginItemsCollector.h"
#import "MemoryUsageCollector.h"
#import "NetworkUsageCollector.h"
#import "EnergyUsageCollector.h"
#import "PreferencePanesCollector.h"
#import "SafariExtensionsCollector.h"
#import "StartupItemsCollector.h"
#import "SystemLaunchAgentsCollector.h"
#import "SystemLaunchDaemonsCollector.h"
#import "SystemSoftwareCollector.h"
#import "ThunderboltCollector.h"
#import "TimeMachineCollector.h"
#import "USBCollector.h"
#import "UserAudioPlugInsCollector.h"
#import "UserITunesPlugInsCollector.h"
#import "UserInternetPlugInsCollector.h"
#import "UserLaunchAgentsCollector.h"
#import "VideoCollector.h"
#import "VirtualMemoryCollector.h"
#import "InstallCollector.h"
#import "DiagnosticsCollector.h"
#import "Utilities.h"
#import "Model.h"
#import "LogCollector.h"
#import "AdwareCollector.h"
#import "UnsignedCollector.h"
#import "CleanupCollector.h"
#import "EtreCheckCollector.h"
#import "XMLBuilder.h"

// Perform the check.
@implementation Checker

@synthesize results = myResults;
@synthesize completed = myCompleted;
@synthesize queue = myQueue;

@synthesize startSection = myStartSection;
@synthesize completeSection = myCompleteSection;
@synthesize progress = myProgress;
@synthesize applicationIcon = myApplicationIcon;
@synthesize complete = myComplete;
@synthesize status = myStatus;

@synthesize currentProgress = myCurrentProgress;

// Destructor.
- (void) dealloc
  {
  [myResults release];
  [myCompleted release];
  dispatch_release(self.queue);
  
  [myStartSection release];
  [myCompleteSection release];
  [myProgress release];
  [myApplicationIcon release];
  [myComplete release];
  [myStatus release];
  
  [LaunchdCollector cleanup];

  [super dealloc];
  }
  
// Do the check.
- (NSAttributedString *) check
  {
  NSString * label = @"CheckQ";
  
  myQueue =
    dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_CONCURRENT);
  
  myResults = [NSMutableDictionary new];
  myCompleted = [NSMutableDictionary new];
  
  // Let the animations drive the show.
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName: kCollectionStatus
    object: NSLocalizedString(@"Checking hardware", NULL)];

  if(self.status != nil)
    self.status(NSLocalizedString(@"Checking hardware", NULL));
    
  // Run stage 1.
  [self checkStage1To: 30.0];
    
  dispatch_barrier_sync(
    self.queue,
    ^{
      // As soon as the hardware collection finishes, move to software mode.
      [[NSNotificationCenter defaultCenter]
        postNotificationName: kCollectionStatus
        object: NSLocalizedString(@"Checking software", NULL)];

      if(self.status != nil)
        self.status(NSLocalizedString(@"Checking software", NULL));
    });
  
  // Now do stage 2.
  [self checkStage2To: 50.0];
  
  dispatch_barrier_sync(
    self.queue,
    ^{
    [[NSNotificationCenter defaultCenter]
      postNotificationName: kCollectionStatus
      object: NSLocalizedString(@"Checking daemons and agents", NULL)];

    if(self.status != nil)
      self.status(NSLocalizedString(@"Checking daemons and agents", NULL));
    });

  // Finally do stage 3.
  [self checkStage3To: 100.0];
  
  dispatch_release(self.queue);
  
  NSAttributedString * report = [self collectResults];
  
  return report;
  }

// Check stage 1.
- (void) checkStage1To: (double) to
  {
  NSMutableArray * collectors = [NSMutableArray array];
  
  HardwareCollector * hardwareCollector =
    [[HardwareCollector new] autorelease];
    
  // Collect items that will be needed by other collectors.
  [collectors addObject: [[SystemSoftwareCollector new] autorelease]];
  [collectors addObject: [[ApplicationsCollector new] autorelease]];
  [collectors addObject: hardwareCollector];
  [collectors addObject: [[LogCollector new] autorelease]];
  [collectors addObject: [[DiskCollector new] autorelease]];
  [collectors addObject: [[VideoCollector new] autorelease]];
  [collectors addObject: [[USBCollector new] autorelease]];
  [collectors addObject: [[FirewireCollector new] autorelease]];
  [collectors addObject: [[ThunderboltCollector new] autorelease]];
  [collectors addObject: [[VirtualVolumeCollector new] autorelease]];
  [collectors addObject: [[TimeMachineCollector new] autorelease]];
  
  [self performCollections: collectors to: to];
  }

// Check stage 2.
- (void) checkStage2To: (double) to
  {
  NSMutableArray * collectors = [NSMutableArray array];
  
  // Start the application animation.
  
  Collector * lastCollector = [[DiagnosticsCollector new] autorelease];
    
  // This searches through applications, and takes some time, so it is
  // somewhat related to applications.
  [collectors addObject: [[KernelExtensionCollector new] autorelease]];
  [collectors addObject: [[ConfigurationCollector new] autorelease]];
  [collectors addObject: [[GatekeeperCollector new] autorelease]];
  [collectors addObject: [[PreferencePanesCollector new] autorelease]];
  [collectors addObject: [[FontsCollector new] autorelease]];
  [collectors addObject: [[CPUUsageCollector new] autorelease]];
  [collectors addObject: [[MemoryUsageCollector new] autorelease]];
  [collectors addObject: [[NetworkUsageCollector new] autorelease]];
  [collectors addObject: [[EnergyUsageCollector new] autorelease]];
  [collectors addObject: [[VirtualMemoryCollector new] autorelease]];
  [collectors addObject: [[InstallCollector new] autorelease]];
  [collectors addObject: lastCollector];
  
  [self performCollections: collectors to: to];
  }

// Check stage 3.
- (void) checkStage3To: (double) to
  {
  NSMutableArray * collectors = [NSMutableArray array];
  
  // In order to find adware in Safari extensions, the Adware collector has
  // to be created first, but then the Safari extension collection has to
  // run fist. Such is life.
  AdwareCollector * adwareCollector = [[AdwareCollector new] autorelease];
  
  [collectors addObject: [[SafariExtensionsCollector new] autorelease]];
  
  // Run the rest of the collectors.
  [collectors addObject: [[StartupItemsCollector new] autorelease]];
  [collectors addObject: [[SystemLaunchAgentsCollector new] autorelease]];
  [collectors addObject: [[SystemLaunchDaemonsCollector new] autorelease]];
  [collectors addObject: [[LaunchAgentsCollector new] autorelease]];
  [collectors addObject: [[LaunchDaemonsCollector new] autorelease]];
  [collectors addObject: [[UserLaunchAgentsCollector new] autorelease]];
  [collectors addObject: [[LoginItemsCollector new] autorelease]];
  [collectors addObject: [[InternetPlugInsCollector new] autorelease]];
  [collectors addObject: [[UserInternetPlugInsCollector new] autorelease]];
  [collectors addObject: [[AudioPlugInsCollector new] autorelease]];
  [collectors addObject: [[UserAudioPlugInsCollector new] autorelease]];
  [collectors addObject: [[ITunesPlugInsCollector new] autorelease]];
  [collectors addObject: [[UserITunesPlugInsCollector new] autorelease]];

  [collectors addObject: adwareCollector];
  [collectors addObject: [[UnsignedCollector new] autorelease]];
  [collectors addObject: [[CleanupCollector new] autorelease]];
  [collectors addObject: [[EtreCheckCollector new] autorelease]];

  [self performCollections: collectors to: to];

  if(self.complete)
    self.complete();
  }

// Perform some collections.
- (void) performCollections: (NSArray *) collectors to: (double) to
  {
  [[NSNotificationCenter defaultCenter]
    postNotificationName: kProgressUpdate
    object: [NSNumber numberWithDouble: to]];
  
  double increment = (to - self.currentProgress) / collectors.count;
  
  NSDictionary * environment = [[NSProcessInfo processInfo] environment];
  
  bool simulate =
    [[environment objectForKey: @"ETRECHECK_SIMULATE"] boolValue];
    
  for(Collector * collector in collectors)
    {
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    if(self.startSection)
      self.startSection([collector name]);
      
    if(simulate)
      [collector simulate];
    else
      [collector collect];
    
    [self reportApplicationIcons: collector];
    
    if(self.completeSection)
      self.completeSection([collector name]);

    if(self.progress)
      self.progress(self.currentProgress += increment);    

    if(collector.result != nil)
      [self.results setObject: collector.result forKey: collector.name];
    
    // Keep a reference to the collector in case it is needed later.
    [self.completed setObject: collector forKey: collector.name];
    
    [pool drain];
    }

  if(self.progress)
    self.progress(to);    
  }

// Report application icons.
- (void) reportApplicationIcons: (Collector *) collector
  {
  if([collector respondsToSelector: @selector(applicationIcons)])
    if(self.applicationIcon != nil)
      {
      NSArray * icons = 
        [(ApplicationsCollector *)collector applicationIcons];
      
      for(NSImage * icon in icons)
        self.applicationIcon(icon);
      }
  }
  
// Collect the results in report order.
- (NSAttributedString *) collectResults
  {
  NSMutableAttributedString * result = [NSMutableAttributedString new];

  [result appendAttributedString: [self getResult: @"hardware"]];
  [result appendAttributedString: [self getResult: @"video"]];
  [result appendAttributedString: [self getResult: @"disk"]];
  [result appendAttributedString: [self getResult: @"usb"]];
  [result
    appendAttributedString: [self getResult: @"firewire"]];
  [result
    appendAttributedString: [self getResult: @"thunderbolt"]];
  [result appendAttributedString: [self getResult: @"virtualvolume"]];
  [result appendAttributedString: [self getResult: @"systemsoftware"]];
  [result appendAttributedString: [self getResult: @"configurationfiles"]];
  [result appendAttributedString: [self getResult: @"gatekeeper"]];
  [result appendAttributedString: [self getResult: @"applications"]];
  [result appendAttributedString: [self getResult: @"adware"]];
  [result appendAttributedString: [self getResult: @"unsigned"]];
  [result appendAttributedString: [self getResult: @"cleanup"]];
  [result appendAttributedString: [self getResult: @"kernelextensions"]];
  [result appendAttributedString: [self getResult: @"startupitems"]];
  [result appendAttributedString: [self getResult: @"systemlaunchagents"]];
  [result appendAttributedString: [self getResult: @"systemlaunchdaemons"]];
  [result appendAttributedString: [self getResult: @"launchagents"]];
  [result appendAttributedString: [self getResult: @"launchdaemons"]];
  [result appendAttributedString: [self getResult: @"userlaunchagents"]];
  [result appendAttributedString: [self getResult: @"loginitems"]];
  [result appendAttributedString: [self getResult: @"internetplugins"]];
  [result appendAttributedString: [self getResult: @"userinternetplugins"]];
  [result appendAttributedString: [self getResult: @"safariextensions"]];
  [result appendAttributedString: [self getResult: @"audioplugins"]];
  [result appendAttributedString: [self getResult: @"useraudioplugins"]];
  [result appendAttributedString: [self getResult: @"itunesplugins"]];
  [result appendAttributedString: [self getResult: @"useritunesplugins"]];
  [result appendAttributedString: [self getResult: @"preferencepanes"]];
  [result appendAttributedString: [self getResult: @"fonts"]];
  [result appendAttributedString: [self getResult: @"timemachine"]];
  [result appendAttributedString: [self getResult: @"cpu"]];
  [result appendAttributedString: [self getResult: @"memory"]];
  [result appendAttributedString: [self getResult: @"network"]];
  [result appendAttributedString: [self getResult: @"energy"]];
  [result appendAttributedString: [self getResult: @"vm"]];
  [result appendAttributedString: [self getResult: @"install"]];
  [result appendAttributedString: [self getResult: @"diagnostics"]];
  [result
    appendAttributedString: [self getResult: @"etrecheckdeletedfiles"]];
  
  return [result autorelease];
  }

// Return an individual result.
- (NSAttributedString *) getResult: (NSString *) key
  {
  return [[self.completed objectForKey: key] result];
  }

// Return an individual XML fragment.
- (XMLElement *) getXML: (NSString *) key
  {
  return [[[self.completed objectForKey: key] model] root];
  }

// Collect output.
- (void) collectOutput
  {
  [[[Model model] xml] startElement: @"etrecheck"];
  
  [[[Model model] xml] addFragment: [[[Model model] header] root]];
  [[[Model model] xml] addFragment: [self getXML: @"hardware"]];
  [[[Model model] xml] addFragment: [self getXML: @"video"]];
  [[[Model model] xml] addFragment: [self getXML: @"disk"]];
  [[[Model model] xml] addFragment: [self getXML: @"usb"]];
  [[[Model model] xml] addFragment: [self getXML: @"firewire"]];
  [[[Model model] xml] addFragment: [self getXML: @"thunderbolt"]];
  [[[Model model] xml] addFragment: [self getXML: @"virtualvolume"]];
  [[[Model model] xml] addFragment: [self getXML: @"systemsoftware"]];
  [[[Model model] xml] addFragment: [self getXML: @"configurationfiles"]];
  [[[Model model] xml] addFragment: [self getXML: @"gatekeeper"]];
  [[[Model model] xml] addFragment: [self getXML: @"applications"]];
  [[[Model model] xml] addFragment: [self getXML: @"adware"]];
  [[[Model model] xml] addFragment: [self getXML: @"unsigned"]];
  [[[Model model] xml] addFragment: [self getXML: @"cleanup"]];
  [[[Model model] xml] addFragment: [self getXML: @"kernelextensions"]];
  [[[Model model] xml] addFragment: [self getXML: @"startupitems"]];
  [[[Model model] xml] addFragment: [self getXML: @"systemlaunchagents"]];
  [[[Model model] xml] addFragment: [self getXML: @"systemlaunchdaemons"]];
  [[[Model model] xml] addFragment: [self getXML: @"launchagents"]];
  [[[Model model] xml] addFragment: [self getXML: @"launchdaemons"]];
  [[[Model model] xml] addFragment: [self getXML: @"userlaunchagents"]];
  [[[Model model] xml] addFragment: [self getXML: @"loginitems"]];
  [[[Model model] xml] addFragment: [self getXML: @"internetplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"userinternetplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"safariextensions"]];
  [[[Model model] xml] addFragment: [self getXML: @"audioplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"useraudioplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"itunesplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"useritunesplugins"]];
  [[[Model model] xml] addFragment: [self getXML: @"preferencepanes"]];
  [[[Model model] xml] addFragment: [self getXML: @"fonts"]];
  [[[Model model] xml] addFragment: [self getXML: @"timemachine"]];
  [[[Model model] xml] addFragment: [self getXML: @"cpu"]];
  [[[Model model] xml] addFragment: [self getXML: @"memory"]];
  [[[Model model] xml] addFragment: [self getXML: @"network"]];
  [[[Model model] xml] addFragment: [self getXML: @"energy"]];
  [[[Model model] xml] addFragment: [self getXML: @"vm"]];
  [[[Model model] xml] addFragment: [self getXML: @"install"]];
  [[[Model model] xml] addFragment: [self getXML: @"diagnostics"]];
  [[[Model model] xml] 
    addFragment: [self getXML: @"etrecheckdeletedfiles"]]; 
  
  [[[Model model] xml] endElement: @"etrecheck"];
  }
  
@end
