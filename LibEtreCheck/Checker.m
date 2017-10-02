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
#import "EtreCheckDeletedFilesCollector.h"
#import "EtreCheckCollector.h"
#import "XMLBuilder.h"

// Perform the check.
@implementation Checker

@synthesize results = myResults;
@synthesize completed = myCompleted;

@synthesize startSection = myStartSection;
@synthesize completeSection = myCompleteSection;
@synthesize progress = myProgress;
@synthesize applicationIcon = myApplicationIcon;
@synthesize complete = myComplete;

@synthesize currentProgress = myCurrentProgress;

// Destructor.
- (void) dealloc
  {
  [myResults release];
  [myCompleted release];
  
  [myStartSection release];
  [myCompleteSection release];
  [myProgress release];
  [myApplicationIcon release];
  [myComplete release];
  
  [LaunchdCollector cleanup];

  [super dealloc];
  }
  
// Do the check.
- (NSAttributedString *) check
  {
  myResults = [NSMutableDictionary new];
  myCompleted = [NSMutableDictionary new];
  
  int collectorCount = 39;
  double increment = 100.0/collectorCount;
  
  // These are all special.
  EtreCheckCollector * etrecheckCollector = 
    [[EtreCheckCollector new] autorelease];
    
  HardwareCollector * hardwareCollector =
    [[HardwareCollector new] autorelease];

  ApplicationsCollector * applicationsCollector = 
    [[ApplicationsCollector new] autorelease];
    
  [self 
    performCollections: 
      @[
        [[SystemSoftwareCollector new] autorelease],
        applicationsCollector
      ]
    increment: increment];
    
  if(self.applicationIcon != nil)
    {
    NSArray * icons = [applicationsCollector applicationIcons];
    
    for(NSImage * icon in icons)
      self.applicationIcon(icon);
    }

  [self 
    performCollections: 
      @[
        hardwareCollector,
        [[LogCollector new] autorelease],
        [[DiskCollector new] autorelease],
        [[VideoCollector new] autorelease],
        [[USBCollector new] autorelease],
        [[FirewireCollector new] autorelease],
        [[ThunderboltCollector new] autorelease],
        [[VirtualVolumeCollector new] autorelease]
      ]
    increment: increment];

  // In order to find adware in Safari extensions, the Adware collector has
  // to be created first, but then the Safari extension collection has to
  // run fist. Such is life.
  AdwareCollector * adwareCollector = [[AdwareCollector new] autorelease];
  
  [self 
    performCollections: 
      @[
        [[SafariExtensionsCollector new] autorelease],
        [[KernelExtensionCollector new] autorelease],
        [[PreferencePanesCollector new] autorelease],
        [[StartupItemsCollector new] autorelease],
        [[SystemLaunchAgentsCollector new] autorelease],
        [[SystemLaunchDaemonsCollector new] autorelease],
        [[LaunchAgentsCollector new] autorelease],
        [[LaunchDaemonsCollector new] autorelease],
        [[UserLaunchAgentsCollector new] autorelease],
        [[LoginItemsCollector new] autorelease],
        [[InternetPlugInsCollector new] autorelease],
        [[UserInternetPlugInsCollector new] autorelease],
        [[AudioPlugInsCollector new] autorelease],
        [[UserAudioPlugInsCollector new] autorelease],
        [[ITunesPlugInsCollector new] autorelease],
        [[UserITunesPlugInsCollector new] autorelease],
        adwareCollector,
        [[UnsignedCollector new] autorelease],
        [[CleanupCollector new] autorelease],
        [[EtreCheckDeletedFilesCollector new] autorelease]
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        [[TimeMachineCollector new] autorelease],
        [[ConfigurationCollector new] autorelease],
        [[FontsCollector new] autorelease],
        [[InstallCollector new] autorelease],
        [[DiagnosticsCollector new] autorelease],
        [[GatekeeperCollector new] autorelease]
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        [[CPUUsageCollector new] autorelease],
        [[MemoryUsageCollector new] autorelease],
        [[NetworkUsageCollector new] autorelease],
        [[EnergyUsageCollector new] autorelease],
        [[VirtualMemoryCollector new] autorelease]
      ]
    increment: increment];
  
  [self performCollections: @[etrecheckCollector] increment: increment];

  NSAttributedString * report = [self collectResults];
  
  if(self.complete)
    self.complete();

  return report;
  }

// Perform some collections.
- (void) performCollections: (NSArray *) collectors 
  increment: (double) increment
  {
  NSDictionary * environment = [[NSProcessInfo processInfo] environment];
  
  bool simulate =
    [[environment objectForKey: @"ETRECHECK_SIMULATE"] boolValue];
    
  for(Collector * collector in collectors)
    {
    if(self.progress)
      self.progress(self.currentProgress += increment);    

    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    if(self.startSection)
      self.startSection([collector name]);
      
    if(simulate)
      [collector simulate];
    else
      [collector collect];
    
    if(self.completeSection)
      self.completeSection([collector name]);

    if(collector.result != nil)
      [self.results setObject: collector.result forKey: collector.name];
    
    // Keep a reference to the collector in case it is needed later.
    [self.completed setObject: collector forKey: collector.name];
    
    [pool drain];
    }
  }

// Collect the results in report order.
- (NSAttributedString *) collectResults
  {
  NSMutableAttributedString * result = [NSMutableAttributedString new];

  [result appendAttributedString: [self getResult: @"header"]];
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
- (XMLBuilderElement *) getXML: (NSString *) key
  {
  return [[[self.completed objectForKey: key] model] root];
  }

// Collect output.
- (void) collectOutput
  {
  [[[Model model] xml] startElement: @"etrecheck"];
  
  [[[Model model] xml] addFragment: [[[Model model] header] root]];
  [[[Model model] xml] addFragment: [self getXML: @"header"]];
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
