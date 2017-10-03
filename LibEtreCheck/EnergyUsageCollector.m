/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "EnergyUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "Model.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"

// Collect information about energy usage.
@implementation EnergyUsageCollector

@synthesize processesByPID = myProcessesByPID;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"energy"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myProcessesByPID release];
  
  [super dealloc];
  }

// Perform the collection.
- (void) performCollect
  {
  int version = [[Model model] majorOSVersion];

  if(version >= kMavericks)
    {
    // Collect the average energy usage usage for all processes (5 times).
    NSMutableDictionary * avgEnergy = [self collectAverageEnergy];
    
    // Purge anything that EtreCheck is doing.
    [avgEnergy removeObjectForKey: @"EtreCheck"];
    [avgEnergy removeObjectForKey: @"top"];
    [avgEnergy removeObjectForKey: @"system_profiler"];
    
    self.processesByPID = [super collectProcesses];
    
    // Sort the result by average value.
    NSArray * processesEnergy =
      [self sortProcesses: avgEnergy by: @"power"];
    
    // Print the top processes.
    [self printTopProcesses: processesEnergy];
    }
  }

// Collect the average energy usage of all processes.
- (NSMutableDictionary *) collectAverageEnergy
  {
  NSMutableDictionary * averageProcesses = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * currentProcesses = [self collectProcesses];
    
    for(NSString * pid in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: pid];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: pid];
        
      if(!averageProcess)
        [averageProcesses setObject: currentProcess forKey: pid];
        
      else if(currentProcess && averageProcess)
        {
        double totalEnergy =
          [[averageProcess objectForKey: @"power"] doubleValue] * i;
        
        double averageEnergy =
          [[currentProcess objectForKey: @"power"] doubleValue];
        
        averageEnergy = (totalEnergy + averageEnergy) / (double)(i + 1);
        
        [averageProcess
          setObject: [NSNumber numberWithDouble: averageEnergy]
          forKey: @"power"];
        }
      }
    }
  
  return averageProcesses;
  }

// Record process information.
- (NSDictionary *) collectProcesses
  {
  NSArray * args = @[@"-l", @"2", @"-stats", @"power,pid,command"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.usePseudoTerminal = YES;

  NSMutableDictionary * processes = [NSMutableDictionary dictionary];
  
  bool parsing = false;
  int group = 0;
  
  if([subProcess execute: @"/usr/bin/top" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      if([line hasPrefix: @"POWER"] && !parsing)
        {
        parsing = true;
        
        continue;
        }
        
      if(!parsing)
        continue;
        
      if([line hasPrefix: @"Processes:"])
        {
        parsing = false;
        ++group;
        
        continue;
        }
        
      if(group < 1)
        continue;
      
      NSDictionary * process = [self parseTop: line];

      NSString * pid = [process objectForKey: @"pid"];
      NSString * name = [process objectForKey: @"process"];
      
      if([name isEqualToString: @"top"])
        continue;
        
      if((process != nil) && (pid != nil))
        [processes setObject: process forKey: pid];
      }
    }
    
  [subProcess release];
  
  return processes;
  }

// Parse a line from the top command.
- (NSDictionary *) parseTop: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  double power;
  
  if(![scanner scanDouble: & power])
    return nil;

  long long pid;
  
  if(![scanner scanLongLong: & pid])
    return nil;

  [scanner
    scanCharactersFromSet:
      [NSCharacterSet whitespaceCharacterSet] intoString: NULL];
    
  NSString * process = NULL;
  
  if(![scanner scanUpToString: @"\n" intoString: & process])
    return nil;
    
  if([process length] == 0)
    process = ECLocalizedString(@"Unknown");

  return
    [NSMutableDictionary
      dictionaryWithObjectsAndKeys:
        process, @"process",
        [NSNumber numberWithLongLong: pid], @"pid",
        [NSNumber numberWithDouble: power], @"power",
        nil];
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  NSUInteger count = 0;
  
  for(NSDictionary * process in processes)
    {
    [self printTopProcess: process];
    
    ++count;
          
    if(count >= 5)
      break;
    }

  [self.result appendCR];
  }

// Print a top process.
- (void) printTopProcess: (NSDictionary *) process
  {
  // Cross-reference the process ID to get a decent process name using
  // "ps" results that are better than names from "top".
  NSString * processName = nil;
  
  NSNumber * pid = [process objectForKey: @"pid"];
  
  NSDictionary * processByPID = [self.processesByPID objectForKey: pid];
  
  if(processByPID != nil)
    processName = [processByPID objectForKey: @"command"];
    
  if(processName == nil)
    processName = [process objectForKey: @"process"];
  
  if([processName length] == 0)
    processName = ECLocalizedString(@"Unknown");
    
  if([processName hasPrefix: @"EtreCheck"])
    return;
    
  double power = [[process objectForKey: @"power"] doubleValue];

  NSString * printString =
    [NSString
      stringWithFormat:
        @"%6.2f", power];

   [self.model startElement: @"process"];
  
  [self.model 
    addElement: @"amount" 
    value: [NSString stringWithFormat: @"%.2f", power]
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"number", @"type", nil]];
    
  [self.model addElement: @"name" value: processName];
  
  [self.model endElement: @"process"];

  if(power > 100.0)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@\t%@\n",
            printString,
            processName]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@\t%@\n",
            printString,
            processName]];
  }

@end
