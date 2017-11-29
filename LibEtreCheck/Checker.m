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
  
  ApplicationsCollector * applications = [ApplicationsCollector new];
  EtreCheckCollector * etrecheck = [EtreCheckCollector new];
  HardwareCollector * hardware = [HardwareCollector new];
  LogCollector * log = [LogCollector new];
  DiskCollector * disk = [DiskCollector new];
  VideoCollector * video = [VideoCollector new];
  USBCollector * USB = [USBCollector new];
  FirewireCollector * firewire = [FirewireCollector new];
  VirtualVolumeCollector * virtualVolume = [VirtualVolumeCollector new];
  NetworkCollector * network = [NetworkCollector new];
  SystemSoftwareCollector * systemSoftware = [SystemSoftwareCollector new];
  ConfigurationCollector * configuration = [ConfigurationCollector new];
  TimeMachineCollector * timeMachine = [TimeMachineCollector new];
  FontsCollector * fonts = [FontsCollector new];
  InstallCollector * install = [InstallCollector new];
  DiagnosticsCollector * diagnostics = [DiagnosticsCollector new];
  GatekeeperCollector * gatekeeper = [GatekeeperCollector new];
  SafariExtensionsCollector * safari = [SafariExtensionsCollector new];
  KernelExtensionCollector * kernel = [KernelExtensionCollector new];
  CPUUsageCollector * CPUUsage = [CPUUsageCollector new];
  SystemLaunchAgentsCollector * sla = [SystemLaunchAgentsCollector new];
  SystemLaunchDaemonsCollector * sld = [SystemLaunchDaemonsCollector new];
  LaunchAgentsCollector * la = [LaunchAgentsCollector new];
  LaunchDaemonsCollector * ld = [LaunchDaemonsCollector new];
  UserLaunchAgentsCollector * ula = [UserLaunchAgentsCollector new];
  PreferencePanesCollector * prefPanes = [PreferencePanesCollector new];
  StartupItemsCollector * startupItems = [StartupItemsCollector new];
  LoginItemsCollector * loginItems = [LoginItemsCollector new];
  InternetPlugInsCollector * ipi = [InternetPlugInsCollector new];
  UserInternetPlugInsCollector * uipi = [UserInternetPlugInsCollector new];
  AudioPlugInsCollector * api = [AudioPlugInsCollector new];
  UserAudioPlugInsCollector * uapi = [UserAudioPlugInsCollector new];
  ITunesPlugInsCollector * iTunespi = [ITunesPlugInsCollector new];
  UserITunesPlugInsCollector * uiTunespi = [UserITunesPlugInsCollector new];
  MemoryUsageCollector * memoryUsage = [MemoryUsageCollector new];
  NetworkUsageCollector * networkUsage = [NetworkUsageCollector new];
  EnergyUsageCollector * energyUsage = [EnergyUsageCollector new];
  VirtualMemoryCollector * virtualMemory = [VirtualMemoryCollector new];
  AdwareCollector * adware = [AdwareCollector new];
  UnsignedCollector * unsignedFiles = [UnsignedCollector new];
  CleanupCollector * cleanup = [CleanupCollector new];
  EtreCheckDeletedFilesCollector * e = [EtreCheckDeletedFilesCollector new];
  
  [self 
    performCollections: 
      @[
        hardware,
        applications
      ]
    increment: increment];
    
  if(self.applicationIcon != nil)
    {
    NSArray * icons = [applications applicationIcons];
    
    for(NSImage * icon in icons)
      self.applicationIcon(icon);
    }

  [self 
    performCollections: 
      @[
        log,
        disk,
        video,
        USB,
        firewire,
        virtualVolume
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        network,
        systemSoftware,
        configuration,
        timeMachine,
        fonts,
        install,
        diagnostics,
        gatekeeper,
        safari,
        kernel,
        CPUUsage
      ]
    increment: increment];
  
  [self 
    performCollections: 
      @[
        sla,
        sld,
        la,
        ld,
        ula,
        prefPanes,
        startupItems,
        loginItems,
        ipi,
        uipi,
        api,
        uapi,
        iTunespi,
        uiTunespi,
        memoryUsage,
        networkUsage,
        energyUsage,
        virtualMemory
      ]
    increment: increment];

  [self 
    performCollections: 
      @[
        adware,
        unsignedFiles,
        cleanup,
        e
      ]
    increment: increment];

  [self 
    performCollections: @[etrecheck] increment: increment];

  NSAttributedString * report = [self collectResults];
  
  if(self.complete)
    self.complete();

  [applications release];
  [etrecheck release];
  [hardware release];
  [log release];
  [disk release];
  [video release];
  [USB release];
  [firewire release];
  [virtualVolume release];
  [network release];
  [systemSoftware release];
  [configuration release];
  [timeMachine release];
  [fonts release];
  [install release];
  [diagnostics release];
  [gatekeeper release];
  [safari release];
  [kernel release];
  [CPUUsage release];
  [sla release];
  [sld release];
  [la release];
  [ld release];
  [ula release];
  [prefPanes release];
  [startupItems release];
  [loginItems release];
  [ipi release];
  [uipi release];
  [api release];
  [uapi release];
  [iTunespi release];
  [uiTunespi release];
  [memoryUsage release];
  [networkUsage release];
  [energyUsage release];
  [virtualMemory release];
  [adware release];
  [unsignedFiles release];
  [cleanup release];
  [e release];

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
