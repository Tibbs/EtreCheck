/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "LogCollector.h"
#import "Model.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "DiagnosticEvent.h"
#import "SubProcess.h"
#import "DiagnosticsCollector.h"

// Collect information from log files.
@implementation LogCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"log";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking information from log files", NULL)];

  [self collectLogInformation];
  
  [self collectSystemLog];
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect information from log files.
- (void) collectLogInformation
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPLogsDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    if(!subProcess.standardOutput)
      return;
      
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];

    if(![plist count])
      return;
      
    NSArray * results =
      [[plist objectAtIndex: 0] objectForKey: @"_items"];
      
    if(![results count])
      return;

    for(NSDictionary * result in results)
      [self collectLogResults: result];
    }
  }

// Collect results from a log entry.
- (void) collectLogResults: (NSDictionary *) result
  {
  // Currently the only thing I am looking for are I/O errors like this:
  // kernel_log_description / contents
  // 17 Nov 2014 15:39:31 kernel[0]: disk0s2: I/O error.
  NSString * name = [result objectForKey: @"_name"];
  
  NSString * content = [result objectForKey: @"contents"];
  
  if([name isEqualToString: @"kernel_log_description"])
    [self collectKernelLogContent: content];
  else if([name isEqualToString: @"asl_messages_description"])
    [self collectASLLogContent: content];
  else if([name isEqualToString: @"panic_log_description"])
    [self collectPanicLog: result];
  else if([name isEqualToString: @"ioreg_output_description"])
    [self collectIOReg: content];
    
  // I could do this on Sierra:
  // log show --predicate '(process == "kernel") && (eventMessage endswith ": I/O error.")'
  // but it would take forever.
  }

// Collect results from the kernel log entry.
- (void) collectKernelLogContent: (NSString *) content
  {
  NSArray * lines = [content componentsSeparatedByString: @"\n"];
  
  for(NSString * line in lines)
    if([line hasSuffix: @": I/O error."])
      [self collectIOError: line];
  }

// Collect I/O errors.
// 17 Nov 2014 10:06:15 kernel[0]: disk0s2: I/O error.
- (void) collectIOError: (NSString *) line
  {
  NSRange diskRange = [line rangeOfString: @": disk"];
  
  if(diskRange.location != NSNotFound)
    {
    diskRange.length = ([line length] - 12) - diskRange.location - 2;
    diskRange.location += 2;
    
    if(diskRange.location < [line length])
      if((diskRange.location + diskRange.length) < [line length])
        {
        NSString * disk = [line substringWithRange: diskRange];
        
        if(disk)
          {
          NSNumber * errorCount =
            [[[Model model] diskErrors]
              objectForKey: disk];
            
          if(!errorCount)
            errorCount = [NSNumber numberWithUnsignedInteger: 0];
            
          errorCount =
            [NSNumber
              numberWithUnsignedInteger:
                [errorCount unsignedIntegerValue] + 1];
            
          [[[Model model] diskErrors]
            setObject: errorCount forKey: disk];
          }
        }
    }
  }

// Collect GPU errors.
// 01/01/14 19:59:49,000 kernel[0]: Trying restart GPU ...
// 01/01/14 19:59:50,000 kernel[0]: GPU Hang State = 0x00000000
// 01/01/14 19:59:50,000 kernel[0]: GPU hang:
- (void) collectGPUError: (NSString *) line
  {
  BOOL errorFound = NO;
  
  NSRange tryingRange = [line rangeOfString: @": Trying restart GPU ..."];
  
  if(tryingRange.location != NSNotFound)
    errorFound = YES;
    
  NSRange hangStateRange = [line rangeOfString: @": GPU Hang State"];
  
  if(hangStateRange.location != NSNotFound)
    errorFound = YES;
    
  NSRange hangRange = [line rangeOfString: @": GPU hang:"];

  if(hangRange.location != NSNotFound)
    errorFound = YES;
    
  if(errorFound)
    {
    NSNumber * errorCount =
      [[Model model] gpuErrors];
      
    if(!errorCount)
      errorCount = [NSNumber numberWithUnsignedInteger: 0];
      
    errorCount =
      [NSNumber
        numberWithUnsignedInteger:
          [errorCount unsignedIntegerValue] + 1];
      
    [[Model model] setGpuErrors: errorCount];
    }
  }

// Collect results from the asl log entry.
- (void) collectASLLogContent: (NSString *) content
  {
  NSArray * lines = [content componentsSeparatedByString: @"\n"];
  
  NSMutableArray * events = [NSMutableArray array];
  
  __block DiagnosticEvent * event = nil;
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        NSString * line = (NSString *)obj;
        
        if([line length] >= 24)
          {
          NSDate * logDate =
            [Utilities
              stringAsDate: [line substringToIndex: 24]
              format: @"MMM d, yyyy, hh:mm:ss a"];
        
          if(logDate)
            {
            event = [DiagnosticEvent new];
            
            event.type = kASLLog;
            event.date = logDate;
            event.details = [Utilities cleanPath: line];
            
            [events addObject: event];
            
            return;
            }
          }
          
        if(event.details)
          event.details =
            [NSString stringWithFormat: @"%@\n", event.details];
        }];
    
    
  [[Model model] setLogEntries: events];
  }

// Collect results from the panic log entry.
- (void) collectPanicLog: (NSDictionary *) info
  {
  NSString * file = [info objectForKey: @"source"];
  
  if([file length] == 0)
    return;
    
  NSString * sanitizedName = nil;
  
  NSDate * date = [info objectForKey: @"lastModified"];
  
  if(date == nil)
    return;
    
  [self parseFileName: file date: & date name: & sanitizedName];
  
  NSString * contents = [info objectForKey: @"contents"];
  
  DiagnosticEvent * event = [DiagnosticEvent new];
  
  event.name = NSLocalizedString(@"Kernel", NULL);
  event.date = date;
  event.type = kPanic;
  event.file = file;
  event.details = contents;
  
  [DiagnosticsCollector parseDiagnosticData: contents event: event];

  [[[Model model] diagnosticEvents] setObject: event forKey: event.name];
  
  [event release];
  }

// Parse a file name and extract the date and sanitized name.
- (void) parseFileName: (NSString *) file
  date: (NSDate **) date
  name: (NSString **) name
  {
  NSString * extension = [file pathExtension];
  NSString * base = [file stringByDeletingPathExtension];
  
  // First the 2nd portion of the file name that contains the date.
  NSArray * parts = [base componentsSeparatedByString: @"_"];

  NSUInteger count = [parts count];
  
  if(count > 1)
    if(date)
      *date =
        [Utilities
          stringAsDate: [parts objectAtIndex: count - 2]
          format: @"yyyy-MM-dd-HHmmss"];

  // Now construct a safe file name.
  NSMutableArray * safeParts = [NSMutableArray arrayWithArray: parts];
  
  [safeParts removeLastObject];
  [safeParts
    addObject:
      [NSLocalizedString(@"[redacted]", NULL)
        stringByAppendingPathExtension: extension]];
  
  if(name)
    *name =
      [Utilities cleanPath: [safeParts componentsJoinedByString: @"_"]];
  }

// Collect the system log, if accessible.
- (void) collectSystemLog
  {
  NSString * content =
    [NSString
      stringWithContentsOfFile: @"/var/log/system.log"
      encoding: NSUTF8StringEncoding
      error: NULL];
    
  if(content)
    [self collectSystemLogContent: content];
  }

// Collect results from the system log content.
- (void) collectSystemLogContent: (NSString *) content
  {
  NSArray * lines = [content componentsSeparatedByString: @"\n"];
  
  NSMutableArray * events = [NSMutableArray array];
  
  __block DiagnosticEvent * event = nil;
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        NSString * line = (NSString *)obj;
        
        if([line length] >= 15)
          {
          NSDate * logDate =
            [Utilities
              stringAsDate: [line substringToIndex: 15]
              format: @"MMM d HH:mm:ss"];
        
          if(logDate)
            {
            event = [DiagnosticEvent new];
            
            event.type = kSystemLog;
            event.date = logDate;
            event.details = [Utilities cleanPath: line];
            
            [events addObject: event];
            
            return;
            }
          }
          
        if(event.details)
          event.details =
            [NSString stringWithFormat: @"%@\n", event.details];
        }];
    
    
  [[Model model] setLogEntries: events];
  }

// Collect results from the ioreg_output_description log entry.
- (void) collectIOReg: (NSString *) content
  {
  NSArray * lines = [content componentsSeparatedByString: @"\n"];
  
  for(NSString * line in lines)
    {
    NSRange range = [line rangeOfString: @"ShutdownCause"];
    
    if(range.location != NSNotFound)
      {
      NSString * shutdownCauseString =
        [line substringFromIndex: range.location + range.length];
      
      NSScanner * scanner =
        [NSScanner scannerWithString: shutdownCauseString];
      
      [scanner
        setCharactersToBeSkipped:
          [NSCharacterSet characterSetWithCharactersInString: @" =\""]];
        
      int shutdownCause = 0;
      
      if([scanner scanInt: & shutdownCause])
        [self parseShutdownCode: shutdownCause];
      }
    }
  }

// Parse a shutdown code.
- (void) parseShutdownCode: (int) shutdownCause
  {
  NSString * shutdownString = NSLocalizedString(@"Unknown", NULL);
  
  switch(shutdownCause)
    {
    case 5:
      shutdownString = NSLocalizedString(@"Normal", NULL);
      return;
      
    case 3:
      shutdownString = NSLocalizedString(@"Hard shutdown", NULL);
      break;
      
    case 0:
      shutdownString = NSLocalizedString(@"Power loss", NULL);
      break;
      
    case -3:
    case -86:
      shutdownString = NSLocalizedString(@"Overheating", NULL);
      break;
      
    case -60:
      shutdownString = NSLocalizedString(@"Corrupt filesystem", NULL);
      break;
    
    case -61:
    case -62:
      shutdownString = NSLocalizedString(@"System unresponsive", NULL);
      break;
    
    case -71:
      shutdownString = NSLocalizedString(@"RAM overheating", NULL);
      break;
    
    case -74:
      shutdownString = NSLocalizedString(@"Battery overheating", NULL);
      break;
    
    case -75:
    case -78:
      shutdownString = NSLocalizedString(@"Power supply failure", NULL);
      break;
    
    case -79:
    case -103:
      shutdownString = NSLocalizedString(@"Battery failure", NULL);
      break;
    
    case -95:
      shutdownString = NSLocalizedString(@"CPU overheating", NULL);
      break;
    
    case -100:
      shutdownString = NSLocalizedString(@"Power supply overheating", NULL);
      break;
    }
    
  NSDate * date = [self getShutdownTime];
  
  DiagnosticEvent * event = [DiagnosticEvent new];
  
  event.code = shutdownCause;
  event.date = date;
  event.type = kShutdown;
  event.name =
    [NSString stringWithFormat: @"%d - %@", shutdownCause, shutdownString];
  
  [[[Model model] diagnosticEvents] setObject: event forKey: event.name];
  
  [event release];
  }

// Get the shutdown time.
- (NSDate *) getShutdownTime
  {
  NSArray * args = @[@"kern.boottime"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/sysctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      if([line hasPrefix: @"kern.boottime: { sec = "])
        {
        NSString * secondsString = [line substringFromIndex: 23];
        
        NSScanner * scanner = [NSScanner scannerWithString: secondsString];
      
        long long boottime = 0;
      
        if([scanner scanLongLong: & boottime])
          {
          NSDate * date = [NSDate dateWithTimeIntervalSince1970: boottime];
          
          return date;
          }
        }
    }
    
  return nil;
  }

@end
