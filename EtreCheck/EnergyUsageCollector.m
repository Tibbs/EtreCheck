/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "EnergyUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "SubProcess.h"
#import "Utilities.h"
#import "Model.h"

// Collect information about energy usage.
@implementation EnergyUsageCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"energy";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  int version = [[Model model] majorOSVersion];

  if(version >= kMavericks)
    {
    [self
      updateStatus:
        NSLocalizedString(@"Sampling processes for energy", NULL)];

    // Collect the average energy usage usage for all processes (5 times).
    NSMutableDictionary * avgEnergy = [self collectAverageEnergy];
    
    // Purge anything that EtreCheck is doing.
    [avgEnergy removeObjectForKey: @"EtreCheck"];
    [avgEnergy removeObjectForKey: @"top"];
    [avgEnergy removeObjectForKey: @"system_profiler"];
    
    // Sort the result by average value.
    NSArray * processesEnergy =
      [self sortProcesses: avgEnergy by: @"power"];
    
    // Print the top processes.
    [self printTopProcesses: processesEnergy];
    }
    
  dispatch_semaphore_signal(self.complete);
  }

// Collect the average energy usage of all processes.
- (NSMutableDictionary *) collectAverageEnergy
  {
  NSMutableDictionary * averageProcesses = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * currentProcesses = [self collectProcesses];
    
    for(NSString * command in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: command];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: command];
        
      if(!averageProcess)
        [averageProcesses setObject: currentProcess forKey: command];
        
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
  NSArray * args = @[@"-l", @"2", @"-stats", @"command,power"];
  
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
      if([line hasPrefix: @"COMMAND"] && !parsing)
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

      NSString * command = [process objectForKey: @"process"];
      
      if((process != nil) && ([command length] > 0))
        [processes setObject: process forKey: command];
      }
    }
    
  [subProcess release];
  
  return processes;
  }

// Parse a line from the top command.
- (NSDictionary *) parseTop: (NSString *) line
  {
  NSScanner * scanner = [NSScanner scannerWithString: line];
  
  NSString * process = NULL;
  
  BOOL success =
    [scanner
      scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
      intoString: & process];
    
  if(!success)
    return nil;
    
  double power;
  
  [scanner scanDouble: & power];

  return
    [NSMutableDictionary
      dictionaryWithObjectsAndKeys:
        process, @"process",
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
  double power = [[process objectForKey: @"power"] doubleValue];

  NSString * printString =
    [NSString
      stringWithFormat:
        @"%6.2f", power];

  if(power > 100.0)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@\t%@\n",
            printString,
            [process objectForKey: @"process"]]
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
            [process objectForKey: @"process"]]];
  }

@end
