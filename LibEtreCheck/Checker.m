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
#import "NetworkCollector.h"
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

// The model for this run.
@synthesize  model = myModel;

// Constructor.
- (instancetype) initWithModel: (Model *) model
  {
  self = [super init];
  
  if(self != nil)
    {
    myModel = [model retain];
    }
    
  return self;
  }
  
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
  
  [myModel release];
  
  [super dealloc];
  }
  
// Do the check.
- (NSAttributedString *) check
  {
  myResults = [NSMutableDictionary new];
  myCompleted = [NSMutableDictionary new];
  
  int collectorCount = 41;
  double increment = 100.0/collectorCount;
  
  ApplicationsCollector * applicationsCollector = 
    [ApplicationsCollector new];
    
  EtreCheckCollector * etrecheckCollector = [EtreCheckCollector new];
  
  [self 
    performCollections: 
      @[
        [HardwareCollector new],
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
        [LogCollector new],
        [DiskCollector new],
        [VideoCollector new],
        [USBCollector new],
        [FirewireCollector new],
        [VirtualVolumeCollector new]
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        [NetworkCollector new],
        [SystemSoftwareCollector new],
        [ConfigurationCollector new],
        [TimeMachineCollector new],
        [FontsCollector new],
        [InstallCollector new],
        [DiagnosticsCollector new],
        [GatekeeperCollector new],
        [SafariExtensionsCollector new],
        [KernelExtensionCollector new],
        [CPUUsageCollector new]
      ]
    increment: increment];
  
  [self 
    performCollections: 
      @[
        [SystemLaunchAgentsCollector new],
        [SystemLaunchDaemonsCollector new],
        [LaunchAgentsCollector new],
        [LaunchDaemonsCollector new],
        [UserLaunchAgentsCollector new],
        [PreferencePanesCollector new],
        [StartupItemsCollector new],
        [LoginItemsCollector new],
        [InternetPlugInsCollector new],
        [UserInternetPlugInsCollector new],
        [AudioPlugInsCollector new],
        [UserAudioPlugInsCollector new],
        [ITunesPlugInsCollector new],
        [UserITunesPlugInsCollector new],
        [MemoryUsageCollector new],
        [NetworkUsageCollector new],
        [EnergyUsageCollector new],
        [VirtualMemoryCollector new]
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        [AdwareCollector new],
        [UnsignedCollector new],
        [CleanupCollector new],
        [EtreCheckDeletedFilesCollector new]
      ]
    increment: increment];

  [self 
    performCollections: @[etrecheckCollector] increment: increment];

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
    collector.model = self.model;
    
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
    
    [collector release];
    
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
  [result appendAttributedString: [self getResult: @"virtualvolume"]];
  [result appendAttributedString: [self getResult: @"usb"]];
  [result
    appendAttributedString: [self getResult: @"firewire"]];
  [result appendAttributedString: [self getResult: @"network"]];
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
  [result appendAttributedString: [self getResult: @"networkusage"]];
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
  return [(Collector *)[self.completed objectForKey: key] result];
  }

// Return an individual XML fragment.
- (XMLBuilderElement *) getXML: (NSString *) key
  {
  return [[[self.completed objectForKey: key] xml] root];
  }

// Collect output.
- (void) collectOutput
  {
  [[self.model xml] startElement: @"etrecheck"];
  
  [[self.model xml] addFragment: [[self.model header] root]];
  [[self.model xml] addFragment: [self getXML: @"header"]];
  [[self.model xml] addFragment: [self getXML: @"hardware"]];
  [[self.model xml] addFragment: [self getXML: @"video"]];
  [[self.model xml] addFragment: [self getXML: @"disk"]];
  [[self.model xml] addFragment: [self getXML: @"usb"]];
  [[self.model xml] addFragment: [self getXML: @"firewire"]];
  [[self.model xml] addFragment: [self getXML: @"virtualvolume"]];
  [[self.model xml] addFragment: [self getXML: @"network"]];
  [[self.model xml] addFragment: [self getXML: @"systemsoftware"]];
  [[self.model xml] addFragment: [self getXML: @"configurationfiles"]];
  [[self.model xml] addFragment: [self getXML: @"gatekeeper"]];
  [[self.model xml] addFragment: [self getXML: @"applications"]];
  [[self.model xml] addFragment: [self getXML: @"adware"]];
  [[self.model xml] addFragment: [self getXML: @"unsigned"]];
  [[self.model xml] addFragment: [self getXML: @"cleanup"]];
  [[self.model xml] addFragment: [self getXML: @"kernelextensions"]];
  [[self.model xml] addFragment: [self getXML: @"startupitems"]];
  [[self.model xml] addFragment: [self getXML: @"systemlaunchagents"]];
  [[self.model xml] addFragment: [self getXML: @"systemlaunchdaemons"]];
  [[self.model xml] addFragment: [self getXML: @"launchagents"]];
  [[self.model xml] addFragment: [self getXML: @"launchdaemons"]];
  [[self.model xml] addFragment: [self getXML: @"userlaunchagents"]];
  [[self.model xml] addFragment: [self getXML: @"loginitems"]];
  [[self.model xml] addFragment: [self getXML: @"internetplugins"]];
  [[self.model xml] addFragment: [self getXML: @"userinternetplugins"]];
  [[self.model xml] addFragment: [self getXML: @"safariextensions"]];
  [[self.model xml] addFragment: [self getXML: @"audioplugins"]];
  [[self.model xml] addFragment: [self getXML: @"useraudioplugins"]];
  [[self.model xml] addFragment: [self getXML: @"itunesplugins"]];
  [[self.model xml] addFragment: [self getXML: @"useritunesplugins"]];
  [[self.model xml] addFragment: [self getXML: @"preferencepanes"]];
  [[self.model xml] addFragment: [self getXML: @"fonts"]];
  [[self.model xml] addFragment: [self getXML: @"timemachine"]];
  [[self.model xml] addFragment: [self getXML: @"cpu"]];
  [[self.model xml] addFragment: [self getXML: @"memory"]];
  [[self.model xml] addFragment: [self getXML: @"networkusage"]];
  [[self.model xml] addFragment: [self getXML: @"energy"]];
  [[self.model xml] addFragment: [self getXML: @"vm"]];
  [[self.model xml] addFragment: [self getXML: @"install"]];
  [[self.model xml] addFragment: [self getXML: @"diagnostics"]];
  [[self.model xml] 
    addFragment: [self getXML: @"etrecheckdeletedfiles"]]; 
  
  [[self.model xml] endElement: @"etrecheck"];
  }
  
@end
