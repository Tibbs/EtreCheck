/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

// Major OS versions.
#define kSnowLeopard  10
#define kLion         11
#define kMountainLion 12
#define kMavericks    13
#define kYosemite     14
#define kElCapitan    15

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

// A singleton to keep track of system information.
@interface Model : NSObject
  {
  int myMajorOSVersion;
  int myMinorOSVersion;
  NSMutableDictionary * myVolumes;
  NSMutableDictionary * myCoreStorageVolumes;
  NSMutableDictionary * myDiskErrors;
  NSNumber * myGPUErrors;
  NSArray * myLogEntries;
  NSDictionary * myApplications;
  int myPhysicalRAM;
  NSImage * myMachineIcon;
  NSString * myModel;
  NSString * mySerialCode;
  int myCoreCount;
  NSMutableDictionary * myDiagnosticEvents;
  NSMutableDictionary * myLaunchdFiles;
  NSMutableSet * myProcesses;
  NSString * myComputerName;
  NSString * myHostName;
  bool myAdwareFound;
  NSMutableDictionary * myAdwareFiles;
  NSMutableDictionary * myPotentialAdwareTrioFiles;
  NSArray * myAdwareExtensions;
  NSMutableSet * myWhitelistFiles;
  NSMutableSet * myWhitelistPrefixes;
  NSMutableSet * myBlacklistFiles;
  NSMutableSet * myBlacklistSuffixes;
  NSMutableSet * myBlacklistMatches;
  bool myUnknownFilesFound;
  NSMutableArray * myTerminatedTasks;
  NSMutableSet * mySeriousProblems;
  bool myBackupExists;
  
  bool myIgnoreKnownAppleFailures;
  bool myShowSignatureFailures;
  bool myHideAppleTasks;
  bool myOldEtreCheckVersion;
  bool myVerifiedEtreCheckVersion;
  NSDictionary * myAppleSoftware;
  NSDictionary * myAppleLaunchd;
  NSDictionary * myAppleLaunchdByLabel;
  NSMutableArray * myUnknownFiles;
  bool mySIP;
  bool mySandboxed;
  }

// Keep track of the OS version.
@property (assign) int majorOSVersion;
@property (assign) int minorOSVersion;

// Keep track of system volumes.
@property (retain) NSMutableDictionary * volumes;

// Keep track of CoreStorage volumes.
@property (retain) NSMutableDictionary * coreStorageVolumes;

// Keep track of disk errors.
@property (retain) NSMutableDictionary * diskErrors;

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

// The serial number code for Apple lookups.
@property (retain) NSString * serialCode;

// The nubmer of cores.
@property (assign) int coreCount;

// Diagnostic events.
@property (retain) NSMutableDictionary * diagnosticEvents;

// All launchd files, whether loaded or not.
@property (retain) NSMutableDictionary * launchdFiles;

// All processes.
@property (retain) NSMutableSet * processes;

// Localized host name.
@property (retain) NSString * computerName;

// Host name.
@property (retain) NSString * hostName;

// Did I find any adware?
@property (assign) bool adwareFound;

// Adware files, whether launchd-based or not.
@property (readonly) NSMutableDictionary * adwareFiles;

// Adware launchd files.
@property (readonly) NSDictionary * adwareLaunchdFiles;

// Potential adware files.
@property (retain) NSMutableDictionary * potentialAdwareTrioFiles;

// Adware extensions.
@property (retain) NSArray * adwareExtensions;

// Whitelist files.
@property (readonly) NSMutableSet * whitelistFiles;

// Whitelist prefixes.
@property (readonly) NSMutableSet * whitelistPrefixes;

// Blacklist files.
@property (readonly) NSMutableSet * blacklistFiles;

// Blacklist suffixes.
@property (readonly) NSMutableSet * blacklistSuffixes;

// Blacklist matches.
@property (readonly) NSMutableSet * blacklistMatches;

// Did I find any unknown files?
@property (assign) bool unknownFilesFound;

// Unknown launchd files.
@property (readonly) NSDictionary * unknownLaunchdFiles;

// Unknown files.
@property (readonly) NSMutableArray * unknownFiles;

// Which tasks had to be terminated.
@property (retain) NSMutableArray * terminatedTasks;

// What serious problems were found?
@property (retain) NSMutableSet * seriousProblems;

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

// Apple software.
@property (retain) NSDictionary * appleSoftware;

// Apple launchd files.
@property (retain) NSDictionary * appleLaunchd;

// Apple launchd files by label.
@property (retain) NSDictionary * appleLaunchdByLabel;

// SIP enabled?
@property (assign, setter=setSIP:) bool sip;

// Am I running in the sandbox?
@property (assign) bool sandboxed;

// Return the singeton of shared values.
+ (Model *) model;

// Return true if there are log entries for a process.
- (bool) hasLogEntries: (NSString *) name;

// Collect log entires matching a date.
- (NSString *) logEntriesAround: (NSDate *) date;

// Create a details URL for a query string.
- (NSAttributedString *) getDetailsURLFor: (NSString *) query;

// Is this file an adware file?
- (bool) checkForAdware: (NSString *) path;

// Is this file an adware extension?
- (bool) isAdwareExtension: (NSString *) name path: (NSString *) path;

// Add files to the whitelist.
- (void) appendToWhitelist: (NSArray *) names;

// Add files to the whitelist prefixes.
- (void) appendToWhitelistPrefixes: (NSArray *) names;

// Add files to the blacklist.
- (void) appendToBlacklist: (NSArray *) names;

// Set the blacklist suffixes.
- (void) appendToBlacklistSuffixes: (NSArray *) names;

// Set the blacklist matches.
- (void) appendToBlacklistMatches: (NSArray *) names;

// Is this file known?
- (bool) isKnownFile: (NSString *) name path: (NSString *) path;

// Is this file in the whitelist?
- (bool) isWhitelistFile: (NSString *) name;

// What kind of adware is this?
- (NSString *) adwareType: (NSString *) path;

// Handle a task that takes too long to complete.
- (void) taskTerminated: (NSString *) program arguments: (NSArray *) args;

// Get the expected Apple signature for an executable.
- (NSString *) expectedAppleSignature: (NSString *) path;

// Is this a known Apple executable?
- (BOOL) isKnownAppleExecutable: (NSString *) path;

// Is this a known Apple executable but not a shell script?
- (BOOL) isKnownAppleNonShellExecutable: (NSString *) path;

@end
