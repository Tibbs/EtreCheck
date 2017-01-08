/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "DiagnosticsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "DiagnosticEvent.h"
#import "NSArray+Etresoft.h"
#import "Model.h"
#import "SubProcess.h"

// Collect diagnostics information.
@implementation DiagnosticsCollector

@synthesize paths = myPaths;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"diagnostics";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
      
    myPaths = [NSMutableSet new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.paths = nil;
  
  [super dealloc];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking diagnostics information", NULL)];

  [self collectDiagnostics];
  [self collectCrashReporter];
  [self collectDiagnosticReportCrashes];
  [self collectUserDiagnosticReportCrashes];
  [self collectDiagnosticReportHangs];
  [self collectUserDiagnosticReportHangs];
  [self collectPanics];
  [self collectCPU];
  
  if([[[Model model] diagnosticEvents] count] || insufficientPermissions)
    {
    [self printDiagnostics];
    
    if(insufficientPermissions)
      {
      if(!hasOutput)
        [self.result appendAttributedString: [self buildTitle]];
      
      [self.result appendString: @"\n"];
      [self.result
        appendString:
          NSLocalizedString(
            @"/Library/Logs/DiagnosticReports permissions", NULL)];
      }
    
    [self.result appendCR];
    }
  
  dispatch_semaphore_signal(self.complete);
  }

// Collect diagnostics.
- (void) collectDiagnostics
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPDiagnosticsDataType"
    ];
  
  //result =
  //  [NSData dataWithContentsOfFile:
  //    @"/tmp/SPDiagnosticsDataType.xml" options: 0 error: NULL];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    if(![subProcess.standardOutput length])
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
      [self collectDiagnosticResult: result];
    }
  }

// Collect a single diagnostic result.
- (void) collectDiagnosticResult: (NSDictionary *) result
  {
  if(![result respondsToSelector: @selector(objectForKey:)])
    return;
    
  NSString * name = [result objectForKey: @"_name"];
  
  if([name isEqualToString: @"spdiags_post_value"])
    {
    NSDate * lastRun =
      [result objectForKey: @"spdiags_last_run_key"];
    
    DiagnosticEvent * event = [DiagnosticEvent new];

    event.date = lastRun;
    
    NSString * details = [result objectForKey: @"spdiags_result_key"];
      
    if([details isEqualToString: @"spdiags_passed_value"])
      {
      event.type = kSelfTestPass;
      event.name = NSLocalizedString(@"Self test - passed", NULL);
      }
    else
      {
      event.type = kSelfTestFail;
      event.name = NSLocalizedString(@"Self test - failed", NULL);
      event.details = details;
      }
      
    [[[Model model] diagnosticEvents] setObject: event forKey: @"selftest"];
    
    [event release];
    }
  }

// Collect files in /Library/Logs/CrashReporter.
- (void) collectCrashReporter
  {
  [self
    collectDiagnosticDataFrom: @"/Library/Logs/CrashReporter"
    type: @"crash"];
  }

// Collect files in /Library/Logs/DiagnosticReports.
- (void) collectDiagnosticReportCrashes
  {
  [self
    collectDiagnosticDataFrom: @"/Library/Logs/DiagnosticReports"
    type: @"crash"];
  }

// Collect files in ~/Library/Logs/DiagnosticReports.
- (void) collectUserDiagnosticReportCrashes
  {
  NSString * diagnosticReportsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Logs/DiagnosticReports"];

  [self
    collectDiagnosticDataFrom: diagnosticReportsDir
    type: @"crash"];
  }

// Collect hang files in /Library/Logs/DiagnosticReports.
- (void) collectDiagnosticReportHangs
  {
  [self
    collectDiagnosticDataFrom: @"/Library/Logs/DiagnosticReports"
    type: @"hang"];
  }

// Collect hang files in ~/Library/Logs/DiagnosticReports.
- (void) collectUserDiagnosticReportHangs
  {
  NSString * diagnosticReportsDir =
    [NSHomeDirectory()
      stringByAppendingPathComponent: @"Library/Logs/DiagnosticReports"];

  [self
    collectDiagnosticDataFrom: diagnosticReportsDir
    type: @"hang"];
  }

// Collect panic files in ~/Library/Logs/DiagnosticReports.
- (void) collectPanics
  {
  [self
    collectDiagnosticDataFrom: @"/Library/Logs/DiagnosticReports"
    type: @"panic"];
  }

// Collect CPU usage reports.
- (void) collectCPU
  {
  [self
    collectDiagnosticDataFrom: @"/Library/Logs/DiagnosticReports"
    type: @"cpu_resource.diag"];
  }

// Collect diagnostic data.
- (void) collectDiagnosticDataFrom: (NSString *) path
  type: (NSString *) type
  {
  NSArray * args =
    @[
      path,
      @"-iname",
      [@"*." stringByAppendingString: type]
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/bin/find" arguments: args])
    {
    if(![subProcess.standardOutput length])
      if([subProcess.standardError length])
        {
        NSString * error =
          [[NSString alloc]
            initWithData:
              subProcess.standardError encoding: NSUTF8StringEncoding];
          
        NSString * permissionsError =
          @"find: /Library/Logs/DiagnosticReports: Permission denied";

        if([error hasPrefix: permissionsError])
          insufficientPermissions = YES;
          
        [error release];
        
        return;
        }
      
    // Parse diagnostic reports.
    NSArray * files = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * file in files)
      [self createEventFromFile: file];
    }
  }

// Create a new diagnostic event for a file.
- (void) createEventFromFile: (NSString *) file
  {
  NSString * typeString = [file pathExtension];
  
  EventType type = kUnknown;
  
  if([typeString isEqualToString: @"crash"])
    type = kCrash;
  else if([typeString isEqualToString: @"hang"])
    type = kHang;
  else if([typeString isEqualToString: @"panic"])
    type = kPanic;
  else if([typeString isEqualToString: @"diag"])
    type = kCPU;

  NSDate * date = nil;
  NSString * sanitizedName = nil;
  
  [self parseFileName: file date: & date name: & sanitizedName];
  
  if((type != kUnknown) && date)
    {
    DiagnosticEvent * event = [DiagnosticEvent new];
    
    event.name = sanitizedName;
    event.date = date;
    event.type = type;
    event.file = file;
    
    // Parse the file contents.
    [self parseFileContents: file event: event];
    
    [[[Model model] diagnosticEvents] setObject: event forKey: event.name];
    
    [event release];
    }
  }

// Parse a file name and extract the date and sanitized name.
- (void) parseFileName: (NSString *) file
  date: (NSDate **) date
  name: (NSString **) name
  {
  NSString * extension = [file pathExtension];
  NSString * base = [file stringByDeletingPathExtension];
  
  // Special case for cpu_resource.diag
  if([file hasSuffix: @".cpu_resource.diag"])
    {
    base = [base stringByDeletingPathExtension];
    extension = @"cpu_resource.diag";
    }
  
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

// Collect just the first section for a CPU report header.
- (void) parseFileContents: (NSString *) file
  event: (DiagnosticEvent *) event
  {
  if(!event)
    return;
    
  NSString * contents =
    [NSString
      stringWithContentsOfFile: file
      encoding: NSUTF8StringEncoding
      error: NULL];
  
  NSArray * lines = [contents componentsSeparatedByString: @"\n"];

  __block NSMutableString * result = [NSMutableString string];
  
  __block NSUInteger lineCount = 0;
  
  __block NSMutableString * path = [NSMutableString string];
  __block NSMutableString * identifier = [NSMutableString string];
  __block NSMutableString * information = [NSMutableString string];
  
  __block BOOL capturingInformation = NO;
  
  [lines
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
        {
        NSString * line = (NSString *)obj;
        
        if(lineCount++ < 20)
          {
          [result appendString: line];
          [result appendString: @"\n"];
          }
          
        if([line hasPrefix: @"Path:"])
          [path
            appendString:
              [[line substringFromIndex: 5]
                stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        else if([line hasPrefix: @"Identifier:"])
          [identifier
            appendString:
              [[line substringFromIndex: 11]
                stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        else if([line hasPrefix: @"Application Specific Information:"])
          {
          capturingInformation = YES;
          
          [information appendFormat: @"        %@\n", line];
          }
        else if(capturingInformation)
          {
          NSString * trimmedLine =
            [line stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
          if([trimmedLine length] > 0)
            [information appendFormat: @"        %@\n", trimmedLine];
          else
            {
            capturingInformation = NO;
            
            *stop = YES;
            }
          }
        }];
    
  if(event.type == kPanic)
    event.details = contents;
  else if(event.type == kCPU)
    event.details = result;
  else
    event.details = [[Model model] logEntriesAround: event.date];
    
  if([path length])
    event.path = path;
  
  if([path length] && [identifier length])
    if(![[path lastPathComponent] isEqualToString: identifier])
      event.identifier = identifier;
    
  if([information length])
    event.information = information;
  }

// Print crash logs.
- (void) printDiagnostics
  {
  NSMutableDictionary * events = [[Model model] diagnosticEvents];
    
  NSArray * sortedKeys =
    [events
      keysSortedByValueUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
        {
        DiagnosticEvent * event1 = (DiagnosticEvent *)obj1;
        DiagnosticEvent * event2 = (DiagnosticEvent *)obj2;
        
        return [event2.date compare: event1.date];
        }];
    
  NSDate * then =
    [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 3];
  
  for(NSString * name in sortedKeys)
    {
    DiagnosticEvent * event = [events objectForKey: name];
    
    switch(event.type)
      {
      case kPanic:
      case kSelfTestFail:
        [self printDiagnosticEvent: event name: name];
        break;
        
      default:
        if([then compare: event.date] == NSOrderedAscending)
          [self printDiagnosticEvent: event name: name];
      }
    }
  }

// Print a single diagnostic event.
- (void) printDiagnosticEvent: (DiagnosticEvent *) event
  name: (NSString *) name
  {
  if(!hasOutput)
    [self.result appendAttributedString: [self buildTitle]];
  
  if(event.type == kSelfTestFail)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@     - %@",
            [Utilities
              dateAsString: event.date format: @"MMM d, yyyy, hh:mm:ss a"],
            event.name]
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@    %@",
            [Utilities
              dateAsString: event.date format: @"MMM d, yyyy, hh:mm:ss a"],
            event.name]];
  
  if([event.details length])
    {
    NSAttributedString * detailsURL =
      [[Model model] getDetailsURLFor: name];

    if(detailsURL)
      {
      [self.result appendString: @" "];
      [self.result appendAttributedString: detailsURL];
      }
    }

  [self.result appendString: @"\n"];
  
  if([event.path length] && ![self.paths containsObject: event.path])
    {
    [self.paths addObject: event.path];
    
    [self.result appendString: @"        "];
    
    if([event.identifier length])
      [self.result appendString: event.identifier];
      
    if([event.path length])
      {
      if([event.identifier length])
        [self.result appendString: @" - "];
      
      [self.result appendString: [Utilities cleanPath: event.path]];
      }
      
    [self.result appendString: @"\n"];
    }
    
  if([event.information length] > 0)
    [self.result appendString: event.information];

  hasOutput = YES;
  }

@end
