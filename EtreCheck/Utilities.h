/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#define kStatusUpdate @"statusupdate"
#define kProgressUpdate @"progressupdate"
#define kCurrentProgress @"currentprogress"
#define kNextProgress @"nextprogress"
#define kFoundApplication @"foundapplication"
#define kShowMachineIcon @"showmachineicon"
#define kCollectionStatus @"collectionstatus"
#define kShowDemonAgent @"showdemonagent"

#define kNotSigned @"signaturemissing"
#define kSignatureApple @"signatureapple"
#define kSignatureValid @"signaturevalid"
#define kSignatureNotValid @"signaturenotvalid"
#define kExecutableMissing @"executablemissing"
#define kSignatureSkipped @"signatureskipped"
#define kShell @"signatureshell"
#define kCodesignFailed @"codesignfailed"
#define kAppleSignatureIndicator @"applesignatureindicator"
#define kValidSignatureIndicator @"validsignatureindicator"
#define kShellScriptIndicator @"shellscriptindicator"

// Assorted utilities.
@interface Utilities : NSObject
  {
  NSFont * myBoldFont;
  NSFont * myItalicFont;
  NSFont * myBoldItalicFont;
  NSFont * myNormalFont;
  NSFont * myLargerFont;
  NSFont * myVeryLargeFont;
  
  NSColor * myGreen;
  NSColor * myBlue;
  NSColor * myRed;
  NSColor * myGray;
  
  NSImage * myUnknownMachineIcon;
  NSImage * myMachineNotFoundIcon;
  NSImage * myGenericApplicationIcon;
  NSImage * myEtreCheckIcon;
  NSImage * myFinderIcon;
  
  NSBundle * myEnglishBundle;
  
  NSMutableDictionary * mySignatureCache;
  
  NSMutableDictionary * myDateFormatters;
  }

// Make some handy shared values available to all collectors.
@property (readonly) NSFont * boldFont;
@property (readonly) NSFont * italicFont;
@property (readonly) NSFont * boldItalicFont;
@property (readonly) NSFont * normalFont;
@property (readonly) NSFont * largerFont;
@property (readonly) NSFont * veryLargeFont;

@property (readonly) NSColor * green;
@property (readonly) NSColor * blue;
@property (readonly) NSColor * red;
@property (readonly) NSColor * gray;

@property (readonly) NSImage * unknownMachineIcon;
@property (readonly) NSImage * machineNotFoundIcon;
@property (readonly) NSImage * genericApplicationIcon;
@property (readonly) NSImage * EtreCheckIcon;
@property (readonly) NSImage * FinderIcon;

@property (readonly) NSBundle * EnglishBundle;

@property (readonly) NSMutableDictionary * signatureCache;
@property (readonly) NSMutableDictionary * dateFormatters;

// Return the singeton of shared utilities.
+ (Utilities *) shared;

// Format text into an array of trimmed lines separated by newlines.
+ (NSArray *) formatLines: (NSData *) data;

// Read a property list to an array.
+ (id) readPropertyList: (NSString *) path;
+ (id) readPropertyListData: (NSData *) data;

// Redact any user names in a path.
+ (NSString *) cleanPath: (NSString *) path;

// Format an exectuable array for printing, redacting any user names in
// the path.
+ (NSString *) formatExecutable: (NSArray *) parts;

// Make a path more presentable.
+ (NSString *) prettyPath: (NSString *) path;

// Uncompress some data.
+ (NSData *) ungzip: (NSData *) gzipData;

// Build a secure URL string.
+ (NSString *) buildSecureURLString: (NSString *) url;

// Build a URL.
+ (NSAttributedString *) buildURL: (NSString *) url
  title: (NSString *) title;

// Look for attributes from a file that might depend on the PATH.
+ (NSDictionary *) lookForFileAttributes: (NSString *) path;

// Compare versions.
+ (NSComparisonResult) compareVersion: (NSString *) version1
  withVersion: (NSString *) version2;

// Scan a string from top output.
+ (double) scanTopMemory: (NSScanner *) scanner;

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSString *) serialCode
  language: (NSString *) language type: (NSString *) type;

// Try to get the marketing name directly from Apple.
+ (NSString *) askAppleForMarketingName: (NSURL *) url;

// Construct an Apple support query URL.
+ (NSString *) AppleSupportSPQueryURL: (NSString *) serialCode
  language: (NSString *) language
  type: (NSString *) type;

// Check the signature of an Apple executable.
+ (NSString *) checkAppleExecutable: (NSString *) path;

// Check the signature of an executable.
+ (NSString *) checkExecutable: (NSString *) path;

// Get the developer of an executable.
+ (NSString *) queryDeveloper: (NSString *) path;

// Create a temporary directory.
+ (NSString *) createTemporaryDirectory;

// Query the status of a launchd task.
+ (NSString *) launchdTaskStatus: (NSString *) label;

// Query the status of a process.
+ (NSString *) ps: (NSNumber *) pid;

// Uninstall launchd tasks.
+ (void) uninstallLaunchdTasks: (NSArray *) tasks;

// Delete files.
+ (void) deleteFiles: (NSArray *) files;

// Restart the machine.
+ (BOOL) restart;

// Turn on Gatekeeper.
+ (void) enableGatekeeper;

// Resolve a deep app path to the wrapper path.
+ (NSString *) resolveBundlePath: (NSString *) path;

// Make a path that is suitable for a URL by appending a / for a directory.
+ (NSString *) makeURLPath: (NSString *) path;

// Return a date string.
+ (NSString *) dateAsString: (NSDate *) date;

// Return a date string in a format.
+ (NSString *) dateAsString: (NSDate *) date format: (NSString *) format;

// Return an install date with consisten text and format.
+ (NSString *) installDateAsString: (NSDate *) date;

// Return a string as a date.
+ (NSDate *) stringAsDate: (NSString *) dateString;

// Return a date string in a format.
+ (NSDate *) stringAsDate: (NSString *) dateString
  format: (NSString *) format;

// Try to find the modification date for a path. This will be the most
// recent creation or modification date for any file in the hierarchy.
+ (NSDate *) modificationDate: (NSString *) path;

// Send an e-mail.
+ (void) sendEmailTo: (NSString *) toAddress
  withSubject: (NSString *) subject
  content: (NSString *) bodyText;

// Generate an MD5 hash.
+ (NSString *) MD5: (NSString *) string;

// Generate a UUID.
+ (NSString *) UUID;

// Find files inside an /etc/mach_init* directory.
+ (NSArray *) checkMachInit: (NSString *) path;

// Translate a size.
+ (NSString *) translateSize: (NSString *) size;

// Extract the most significant name from a bundle file name.
+ (NSString *) bundleName: (NSString *) file;

// Get the current locale/language code for use in a URL.
+ (NSString *) localeCode;

// Get the CRC of an NSData.
+ (NSString *) crcData: (NSData *) data;

// Get the CRC of a file.
+ (NSString *) crcFile: (NSString *) path;

// Get parent bundle of a path.
+ (NSString *) getParentBundle: (NSString *) path;

@end
