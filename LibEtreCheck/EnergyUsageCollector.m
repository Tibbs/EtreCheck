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
#import "OSVersion.h"
#import "NSDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "NSString+Etresoft.h"
#import "Process.h"

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
  if([[OSVersion shared] major] >= kMavericks)
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
        
      if([NSDictionary isValid: currentProcess])
        {
        if(![NSDictionary isValid: averageProcess])
          [averageProcesses setObject: currentProcess forKey: pid];
          
        else 
          {
          NSNumber * averagePower = [averageProcess objectForKey: @"power"];
          
          if(![NSNumber isValid: averagePower])
            continue;
            
          double totalEnergy = [averagePower doubleValue] * i;
          
          NSNumber * currentPower = [currentProcess objectForKey: @"power"];
          
          if(![NSNumber isValid: currentPower])
            continue;
            
          double averageEnergy = [currentPower doubleValue];
          
          averageEnergy = (totalEnergy + averageEnergy) / (double)(i + 1);
          
          NSNumber * power = 
            [[NSNumber alloc] initWithDouble: averageEnergy];
          
          if(power != nil)
            {
            [averageProcess setObject: power forKey: @"power"];
            
            [power release];
            }
          }
        }
      }
    }
  
  return averageProcesses;
  }

// Record process information.
- (NSDictionary *) collectProcesses
  {
  NSArray * args = @[@"-l", @"2", @"-stats", @"power,pid,command"];
  
  NSMutableDictionary * processes = [NSMutableDictionary dictionary];
  
  bool parsing = false;
  int group = 0;
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  subProcess.usePseudoTerminal = YES;

  NSString * key = @"top_power";
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

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

      if([NSDictionary isValid: process])
        {
        NSString * name = [process objectForKey: @"process"];
        
        if([NSString isValid: name] && [name isEqualToString: @"top"])
          continue;
          
        NSNumber * pid = [process objectForKey: @"pid"];

        if([NSNumber isValid: pid])
          [processes setObject: process forKey: pid];
        }
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
  
  if(![NSNumber isValid: pid])
    return;
    
  NSDictionary * processByPID = [self.processesByPID objectForKey: pid];
  
  if([NSDictionary isValid: processByPID])
    processName = [processByPID objectForKey: @"command"];
    
  if(![NSString isValid: processName])
    processName = [process objectForKey: @"process"];
  
  if(![NSString isValid: processName])
    processName = ECLocalizedString(@"Unknown");
    
  if([processName hasPrefix: @"EtreCheck"])
    return;
    
  NSNumber * powerValue = [process objectForKey: @"power"];
  
  if(![NSNumber isValid: powerValue])
    return;
    
  double power = [powerValue doubleValue];

  NSString * printString = [NSString stringWithFormat: @"%6.2f", power];

  [self.xml startElement: @"process"];
  
  NSString * powerString = 
    [[NSString alloc] initWithFormat: @"%.2f", power];
 
  NSDictionary * attributes =
    [[NSDictionary alloc] initWithObjectsAndKeys: @"number", @"type", nil];
    
  [self.xml 
    addElement: @"amount" value: powerString attributes: attributes];
    
  [attributes release];
  [powerString release];
  
  [self.xml addElement: @"name" value: processName];
  [self.xml addElement: @"PID" number: pid];
  
  [self.xml endElement: @"process"];

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
            
  Process * runningProcess = 
    [self.model.runningProcesses objectForKey: pid];
    
  runningProcess.reported = YES;
  }

@end
