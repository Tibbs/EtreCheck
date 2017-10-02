/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "DiagnosticsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "DiagnosticEvent.h"
#import "NSArray+Etresoft.h"
#import "Model.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"

// Collect diagnostics information.
@implementation DiagnosticsCollector

@synthesize paths = myPaths;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"diagnostics"];
  
  if(self != nil)
    {
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
- (void) performCollect
  {
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
          ECLocalizedString(
            @"/Library/Logs/DiagnosticReports permissions")];
      }
    
    [self.result appendCR];
    }
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
    
  if(self.simulating)
    [self 
      collectDiagnosticResult: 
        [NSDictionary dictionaryWithObjectsAndKeys:
          @"spdiags_post_value", @"_name", 
          @"spdiags_simulated_value", @"spdiags_result_key", 
          [NSDate date], @"spdiags_last_run_key",
          nil]];
  }

// Collect a single diagnostic result.
- (void) collectDiagnosticResult: (NSDictionary *) result
  {
  if(![result respondsToSelector: @selector(objectForKey:)])
    return;
    
  NSString * name = [result objectForKey: @"_name"];
  
  if([name isEqualToString: @"spdiags_post_value"])
    {
    NSString * details = [result objectForKey: @"spdiags_result_key"];
      
    if(![details isEqualToString: @"spdiags_passed_value"])
      {
      DiagnosticEvent * event = [DiagnosticEvent new];

      NSDate * lastRun =
        [result objectForKey: @"spdiags_last_run_key"];
    
      event.date = lastRun;
    
      event.type = kSelfTestFail;
      event.name = ECLocalizedString(@"Self test - failed");
      event.details = details;
      
      [[[Model model] diagnosticEvents]
        setObject: event forKey: @"selftest"];
      
      [event release];
      }
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
    event.safefile = sanitizedName;
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
      [ECLocalizedString(@"[redacted]")
        stringByAppendingPathExtension: extension]];
  
  if(name)
    *name =
      [Utilities cleanPath: [safeParts componentsJoinedByString: @"_"]];
  }

// Collect just the first section for a CPU report header.
- (void) parseFileContents: (NSString *) file
  event: (DiagnosticEvent *) event
  {
  NSData * data = [NSData dataWithContentsOfFile: file];
  
  NSString * contents =
    [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
  
  [DiagnosticsCollector parseDiagnosticData: contents event: event];
  
  [contents release];
  }

// Parse diagnostic data.
+ (void) parseDiagnosticData: (NSString *) contents
  event: (DiagnosticEvent *) event
  {
  if(!event)
    return;
    
  NSArray * lines = [contents componentsSeparatedByString: @"\n"];

  __block NSMutableString * result = [NSMutableString string];
  
  __block NSUInteger lineCount = 0;
  
  __block NSMutableString * path = [NSMutableString string];
  __block NSMutableString * identifier = [NSMutableString string];
  __block NSMutableString * information = [NSMutableString string];
  __block NSMutableSet * extensions = [NSMutableSet set];
  
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
          
        if([line hasPrefix: @"Path:"] && ([path length] == 0))
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
          capturingInformation = YES;
          
        else if([line hasPrefix: @"loaded kexts:"])
          capturingInformation = YES;
        
        else if([line hasPrefix: @"last loaded kext at "])
          {
          NSRange range = [line rangeOfString: @": "];
          
          if(range.location != NSNotFound)
            {
            NSString * extension =
              [line substringFromIndex: range.location + range.length];
          
            if([extension length] > 0)
              if(![extension hasPrefix: @"com.apple."])
                [extensions addObject: extension];
            }
          }
          
        else if([line hasPrefix: @"last unloaded kext at "])
          {
          NSRange range = [line rangeOfString: @": "];
          
          if(range.location != NSNotFound)
            {
            NSString * extension =
              [line substringFromIndex: range.location + range.length];
          
            if([extension length] > 0)
              if(![extension hasPrefix: @"com.apple."])
                [extensions addObject: extension];
            }
          }
          
        else if(capturingInformation)
          {
          NSString * trimmedLine =
            [line stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
          if([trimmedLine length] > 0)
            {
            if(event.type == kPanic)
              {
              if([trimmedLine hasPrefix: @"com.apple."])
                capturingInformation = NO;
              else
                [extensions addObject: trimmedLine];
              }
            else
              [information appendFormat: @"%@\n", trimmedLine];
            }
          else
            capturingInformation = NO;
          
          if(!capturingInformation && stop)
            *stop = YES;
          }
        }];
    
  if(event.type == kPanic)
    {
    event.details = contents;
    event.name = ECLocalizedString(@"Kernel");
    
    [information
      appendFormat:
        @"%@", ECLocalizedString(@"3rd Party Kernel Extensions: ")];
      
    if([extensions count] == 0)
      {
      [information appendString: ECLocalizedString(@"None")];
      [information appendString: @"\n"];
      }
    else
      {
      [information appendString: @"\n"];
      
      for(NSString * extension in extensions)
        [information appendFormat: @"%@\n", extension];
      }
    }
  else if(event.type == kCPU)
    event.details = result;
  else
    event.details = [[Model model] logEntriesAround: event.date];
    
  if([path length])
    {
    event.path = path;
    event.name = [path lastPathComponent];
    
    NSString * bundle = [Utilities getParentBundle: path];
    
    if(![bundle isEqualToString: path])
      event.name = [bundle lastPathComponent];
    }
    
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
    [[NSDate date] dateByAddingTimeInterval: -60 * 60 * 24 * 7];
  
  for(NSString * name in sortedKeys)
    {
    DiagnosticEvent * event = [events objectForKey: name];
    
    BOOL since7Days = [then compare: event.date] == NSOrderedAscending;
  
    switch(event.type)
      {
      case kPanic:
      case kSelfTestFail:
      case kShutdown:
        [self printDiagnosticEvent: event name: name];
        break;
        
      default:
        if(self.simulating || since7Days)
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
  
  [self.model startElement: @"event"];
  
  [self.model addElement: @"date" date: event.date];
  [self.model addElement: @"name" value: event.name];
  [self.model addElement: @"type" value: [self getEventType: event.type]];

  switch(event.type)
    {
    case kSelfTestFail:
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\t%@",
              [Utilities dateAsString: event.date],
              event.name]
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      break;
    
    case kShutdown:
      
      if(event.code < 0)
        [self.result
          appendString:
            [NSString
              stringWithFormat:
                @"    %@\t%@ %@",
                [Utilities dateAsString: event.date],
                [self getEventType: event.type],
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
                @"    %@\t%@ %@",
                [Utilities dateAsString: event.date],
                [self getEventType: event.type],
                event.name]];
      break;

    default:
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"    %@\t%@ %@",
              [Utilities dateAsString: event.date],
              event.name,
              [self getEventType: event.type]]];
      break;
    }
  
  if([event.file length] > 0)
    {
    BOOL fileExists =
      [[NSFileManager defaultManager] fileExistsAtPath: event.file];
    
    if(fileExists)
      {
      NSAttributedString * openURL =
        [[Model model] getOpenURLFor: event.file];

      if(openURL != nil)
        {
        [self.result appendString: @" "];
        [self.result appendAttributedString: openURL];
        [self.model addElement: @"path" value: event.file];
        }
      }
    else
      [self.result
        appendString: ECLocalizedString(@" Missing!")
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    }
    
  if([event.details length])
    {
    [self.model addElement: @"details" valueAsCDATA: event.details];
    
    NSAttributedString * detailsURL =
      [[Model model] getDetailsURLFor: name];

    if(detailsURL != nil)
      {
      [self.result appendString: @" "];
      [self.result appendAttributedString: detailsURL];
      }
    }

  [self.result appendString: @"\n"];
  
  [self.model addElement: @"information" valueAsCDATA: event.information];
  
  if([event.information length] > 0)
    [self.result 
      appendString: [Utilities indent: event.information by: @"        "]];

  hasOutput = YES;
  
  [self.model endElement: @"event"];
  }

// Get an event name.
- (NSString *) getEventType: (EventType) eventType
  {
  switch(eventType)
    {
    case kCrash:
      return ECLocalizedString(@"Crash");
      
    case kCPU:
      return ECLocalizedString(@"High CPU use");

    case kHang:
      return ECLocalizedString(@"Hang");
      
    case kPanic:
      return ECLocalizedString(@"Panic");
      
    case kShutdown:
      return ECLocalizedString(@"Last shutdown cause");
      
    case kSelfTestFail:
      return ECLocalizedString(@"Self test - failed");
      
    default:
      break;
    }
    
  return ECLocalizedString(@"Unknown");
  }

@end
