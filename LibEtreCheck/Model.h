/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Adware
#define kAdware @"adware"
#define kAdwareType @"adwaretype"
#define kAdwareLaunchdInfo @"adwarelaunchdinfo"

// Critical errors
#define kHardDiskFailure @"harddiskfailure"
#define kNoBackups @"nobackup"
#define kLowHardDisk @"lowharddisk"
#define kLowRAM @"lowram"
#define kMemoryPressure @"memorypressure"
#define kOutdatedOS @"outdatedos"
#define kHighCache @"highcache"

#define kMinimumWhitelistSize 1000

@class DiagnosticEvent;
@class XMLBuilder;
@class Launchd;
@class Safari;
@class Adware;

// A singleton to keep track of system information.
@interface Model : NSObject
  {
  NSString * myProblem;
  NSAttributedString * myProblemDescription;
  
  NSMutableDictionary * myStorageDevices;

  NSArray * myLogEntries;

  NSDictionary * myApplications;

  int myPhysicalRAM;

  NSImage * myMachineIcon;

  NSString * myModel;
  NSString * myModelType;
  int myModelMajorVersion;
  int myModelMinorVersion;

  NSString * mySerialCode;

  NSMutableDictionary * myDiagnosticEvents;

  Launchd * myLaunchd;
  Safari * mySafari;
  Adware * myAdware;

  NSMutableSet * myProcesses;

  NSString * myComputerName;
  NSString * myHostName;
  
  NSMutableArray * myTerminatedTasks;

  bool myBackupExists;
  
  bool myIgnoreKnownAppleFailures;
  bool myShowSignatureFailures;
  bool myHideAppleTasks;
  
  bool myOldEtreCheckVersion;
  bool myVerifiedEtreCheckVersion;
  
  bool mySIP;

  NSMutableDictionary * myNotificationSPAMs;

  NSMutableDictionary * myPathsForUUIDs;
  
  XMLBuilder * myXMLBuilder;
  XMLBuilder * myXMLHeader;
  }

// The problem and description (if any).
@property (retain) NSString * problem;
@property (retain) NSAttributedString * problemDescription;

// Keep track of storage devices.
@property (retain) NSMutableDictionary * storageDevices;

// Keep track of gpu errors.
@property (retain) NSNumber * gpuErrors;

// Keep track of log content.
@property (retain) NSArray * logEntries;

// Keep track of applications.
@property (retain) NSDictionary * applications;

// I will need the RAM amount (in GB) for later.
@property (assign) int physicalRAM;

// See if I can get the machine image.
@property (retain) NSImage * machineIcon;

// The model code.
@property (retain) NSString * model;

// The model type.
@property (readonly) NSString * modelType;

// The model major version.
@property (readonly) int modelMajorVersion;

// The model minor version.
@property (readonly) int modelMinorVersion;

// The serial number code for Apple lookups.
@property (retain) NSString * serialCode;

// Diagnostic events.
@property (retain) NSMutableDictionary * diagnosticEvents;

// All launchd data.
@property (readonly) Launchd * launchd;

// All Safari data.
@property (readonly) Safari * safari;

// All adware data.
@property (readonly) Adware * adware;

// All processes.
@property (retain) NSMutableSet * processes;

// Localized host name.
@property (retain) NSString * computerName;

// Host name.
@property (retain) NSString * hostName;

// Did I find any adware?
@property (readonly) bool adwareFound;

// Did I find any unsigned files?
@property (readonly) bool unsignedFound;

// Is clean up required?
@property (assign) bool cleanupRequired;

// Which tasks had to be terminated.
@property (retain) NSMutableArray * terminatedTasks;

// Do I have a Time Machine backup?
@property (assign) bool backupExists;

// Ignore known Apple failures.
@property (assign) bool ignoreKnownAppleFailures;

// Show signature failures.
@property (assign) bool showSignatureFailures;

// Hide Apple tasks.
@property (assign) bool hideAppleTasks;

// Is this version outdated?
@property (assign) bool oldEtreCheckVersion;

// Do I have a verified EtreCheck version?
@property (assign) bool verifiedEtreCheckVersion;

// SIP enabled?
@property (assign, setter=setSIP:) bool sip;

// Notification SPAM.
@property (readonly) NSMutableDictionary * notificationSPAMs;

// Map paths to UUIDs for privacy.
@property (readonly) NSMutableDictionary * pathsForUUIDs;

// XML output.
@property (readonly) XMLBuilder * xml;
@property (readonly) XMLBuilder * header;

// Return the singeton of shared values.
+ (Model *) model;

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name;

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date;

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query;

// Create an open URL for a file.
- (NSAttributedString *) getOpenURLFor: (NSString *) path;

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args;

// Is this a known Apple executable but not a shell script?
- (BOOL) isKnownAppleNonShellExecutable: (NSString *) path;

@end
