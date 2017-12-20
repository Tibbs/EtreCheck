/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import "EtreCheckCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "Adware.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSString+Etresoft.h"
#import "RunningProcess.h"

// Collect information about EtreCheck itself.
@implementation EtreCheckCollector

@synthesize startTime = myStartTime;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"header"];
  
  if(self != nil)
    {
    myStartTime = [NSDate new];
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  [myStartTime release];
  
  [super dealloc];
  }

// Collect information from log files.
- (void) performCollect
  {
  [self collectHeaderInformation];
  
  [self.result appendCR];
  }

// Collect the header information.
- (void) collectHeaderInformation
  {
  // Do something clever to get the app bundle from a framework.
  Class appDelegate = NSClassFromString(@"AppDelegate");
  
  if(appDelegate == nil)
    appDelegate = NSClassFromString(@"EtreCheckAppDelegate");
  
  NSBundle * bundle = [NSBundle bundleForClass: appDelegate];
  
  NSString * version = 
    [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

  NSString * build = 
    [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];

  NSDate * date = [NSDate date];
  
  NSString * currentDate = [Utilities dateAsString: date];
              
  [self.xml addElement: @"version" value: version];
  [self.xml addElement: @"build" value: build];
  [self.xml addElement: @"date" date: date];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n"),
            version,
            build,
            currentDate]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];
    
  [self.result
    appendString: ECLocalizedString(@"downloadetrecheck")
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSString * url = [Utilities buildSecureURLString: @"etrecheck.com"];
  
  [self.result
    appendAttributedString: [Utilities buildURL: url title: url]];
    
  [self.result appendString: @"\n"];
  
  NSString * runtime = [self elapsedTime];
  
  [self.xml 
    addElement: @"runtime" 
    value: runtime 
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"mm:ss", @"units", nil]];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(@"Runtime: %@\n"), runtime]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self printPerformance];
    
  [self.result appendString: @"\n"];
  
  [self printLinkInstructions];
  [self printOptions];
  [self printErrors];
  [self printProblem];
  [self exportContext];
  }

// Print performance.
- (void) printPerformance
  {
  [self.result
    appendString: ECLocalizedString(@"Performance: ")
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSTimeInterval interval = [self elapsedSeconds];
  
  if(interval > (60 * 10))
    {
    NSString * performance = ECLocalizedString(@"poorperformance");
    
    [self.xml addElement: @"performance" value: performance];
    
    [self.result
      appendString: performance
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else if(interval > (60 * 5))
    {
    NSString * performance = 
      ECLocalizedString(@"belowaverageperformance");
    
    [self.xml addElement: @"performance" value: performance];
    
    [self.result
      appendString: performance
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else if(interval > (60 * 3))
    {
    NSString * performance = 
      ECLocalizedString(@"goodperformance");
    
    [self.xml addElement: @"performance" value: performance];
    
    [self.result
      appendString: performance
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else
    {
    NSString * performance = 
      ECLocalizedString(@"excellentperformance");
    
    [self.xml addElement: @"performance" value: performance];
    
    [self.result
      appendString: performance
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
    
  [self.result appendString: @"\n"];
  }

// Print link instructions.
- (void) printLinkInstructions
  {
  [self.result
    appendRTFData:
      [NSData
        dataWithContentsOfFile:
          [[NSBundle mainBundle]
            pathForResource: @"linkhelp" ofType: @"rtf"]]];

  if([self.model adwareFound])
    [self.result
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"adwarehelp" ofType: @"rtf"]]];
    
  if([self.model unsignedFound])
    [self.result
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"unsignedhelp" ofType: @"rtf"]]];

  if([self.model cleanupRequired])
    [self.result
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"cleanuphelp" ofType: @"rtf"]]];

  [self.result appendString: @"\n"];
  }

// Print option settings.
- (void) printOptions
  {
  bool options = NO;
  
  if([self.model showSignatureFailures])
    {
    [self.result
      appendString:
        ECLocalizedString(
          @"Show signature failures: Enabled\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![self.model ignoreKnownAppleFailures])
    {
    [self.result
      appendString:
        ECLocalizedString(
          @"Ignore expected failures in Apple tasks: Disabled\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![self.model hideAppleTasks])
    {
    [self.result
      appendString:
        ECLocalizedString(
          @"Hide Apple tasks: Disabled\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(options)
    [self.result appendString: @"\n"];
  }

// Print errors during EtreCheck itself.
- (void) printErrors
  {
  NSArray * terminatedTasks = [self.model terminatedTasks];
  
  if(terminatedTasks.count > 0)
    {
    [self.result
      appendString:
        ECLocalizedString(
          @"The following internal tasks failed to complete:\n")
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];

    for(NSString * task in terminatedTasks)
      {
      [self.result
        appendString: task
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      [self.result appendString: @"\n"];
      }

    [self.result appendString: @"\n"];
    }
    
  Adware * adware = [self.model adware];
  
  if([[adware whitelistFiles] count] < kMinimumWhitelistSize)
    {
    [self.result
      appendString:
        ECLocalizedString(@"Failed to read adware signatures!")
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    [self.result appendString: @"\n\n"];
    }
      
  if([ECLocalizedString(@"downloadetrecheck") length] == 17)
    {
    NSString * message = @"Failed to load language resources!";
    
    NSLocale * locale = [NSLocale currentLocale];
  
    NSString * languageCode = [locale objectForKey: NSLocaleLanguageCode];
    
    if([NSString isValid: languageCode])
      {
      NSString * language = [languageCode lowercaseString];

      if([language isEqualToString: @"fr"])
        message = @"Échec de chargement des ressources linguistiques"; 

      [self.result
        appendString: message
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      [self.result appendString: @"\n\n"];
      }
    }
  }

// Print the problem from the user.
- (void) printProblem
  {
  [self.result
    appendString: ECLocalizedString(@"Problem: ")
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  
  [self.xml addElement: @"problem" value: [self.model problem]];

  [self.result appendString: [self.model problem]];
  [self.result appendString: @"\n"];
    
  NSAttributedString * problemDescription = 
    [self.model problemDescription];
  
  if(problemDescription.string.length > 0)
    {
    [self.xml
      addElement: @"problemdescription" value: problemDescription.string];

    [self.result
      appendString: ECLocalizedString(@"Description:\n")
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    [self.result appendAttributedString: problemDescription];
    [self.result appendString: @"\n"];
    }
  }

// Export the context.
- (void) exportContext
  {
  [self.xml startElement: @"context"];
  
  for(NSNumber * pid in self.model.runningProcesses)
    {
    RunningProcess * runningProcess = 
      [self.model.runningProcesses objectForKey: pid];
      
    if(runningProcess.reported)
      {
      if(runningProcess.path == nil)
        continue;
        
      [self.xml startElement: @"process"];
      
      [self.xml addElement: @"PID" intValue: runningProcess.PID];
      [self.xml addElement: @"path" value: runningProcess.path];
      
      if(runningProcess.PID == 0)
        runningProcess.apple = YES;
        
      if([runningProcess.path hasPrefix: @"/System/"])
        runningProcess.apple = YES;
      
      if(!runningProcess.apple)
        {
        BOOL isWebKit = 
          [runningProcess.path 
            hasPrefix: @"/System/Library/Frameworks/WebKit.framework/"];
            
        NSString * bundlePath = 
          isWebKit
            ? @"/Applications/Safari.app"
            : [Utilities getParentBundle: runningProcess.path];
          
        NSImage * icon = 
          [[NSWorkspace sharedWorkspace] iconForFile: bundlePath];
            
        [icon setSize: NSMakeSize(32.0, 32.0)];
        
        NSData * data = [self iconToData: icon];
        
        if(data.length > 800)
          [self.xml addElement: @"icon" type: @"image/png" data: data];
        }
        
      NSString * source = @"?";
      
      if(!runningProcess.apple)
        {
        // Now try to get the author.
        BOOL isXcode = 
          [runningProcess.path 
            isEqualToString: 
              @"/Applications/Xcode.app/Contents/MacOS/Xcode"];
              
        if(isXcode)
          runningProcess.apple = YES;
            
        if(!runningProcess.apple)
          {
          NSString * signature = 
            [Utilities checkAppleExecutable: runningProcess.path];
        
          if([signature isEqualToString: kSignatureApple])
            runningProcess.apple = YES;
          }
        }
        
      if(runningProcess.apple)  
        source = @"Apple";
      else
        source = [Utilities queryDeveloper: runningProcess.path];
        
      [self.xml addElement: @"apple" boolValue: runningProcess.apple];
      [self.xml addElement: @"source" value: source];

      [self.xml endElement: @"process"];      
      }
    }
    
  // Go ahead and add kernel_task here.
  [self.xml startElement: @"process"];
  
  [self.xml addElement: @"PID" intValue: 0];
  [self.xml addElement: @"apple" boolValue: YES];
  [self.xml addElement: @"source" value: @"Apple"];
  
  [self.xml endElement: @"process"];

  [self.xml endElement: @"context"];
  
  NSImage * machineIcon = [NSImage imageNamed: NSImageNameComputer];
  
  [machineIcon setSize: NSMakeSize(512.0, 512.0)];
  
  NSData * data = [self iconToData: machineIcon];
  
  // Add the machine icon too.
  [self.xml addElement: @"machineicon" type: @"image/png" data: data];
  }
  
// Convert an icon to a PNG data representation.
- (NSData *) iconToData: (NSImage *) icon
  {
  NSBitmapImageRep * bitmap = 
    [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes: NULL
      pixelsWide: (int)icon.size.width
      pixelsHigh: (int)icon.size.height
      bitsPerSample: 8
      samplesPerPixel: 4
      hasAlpha: YES
      isPlanar: NO
      colorSpaceName: NSDeviceRGBColorSpace
      bytesPerRow: 0
      bitsPerPixel: 0];

  [NSGraphicsContext saveGraphicsState];
  
  [NSGraphicsContext 
    setCurrentContext:
      [NSGraphicsContext graphicsContextWithBitmapImageRep: bitmap]];    

  [icon 
    drawAtPoint: NSMakePoint(0, 0)
    fromRect: NSZeroRect
    operation: NSCompositeSourceOver
    fraction: 1.0];

  [NSGraphicsContext restoreGraphicsState];
  
  NSData * data = 
    [bitmap 
      representationUsingType: NSPNGFileType 
      properties: @{NSImageCompressionFactor: @1.0}];

  [bitmap release];
  
  return data;
  }
  
// Get the elapsed time as a number of seconds.
- (NSTimeInterval) elapsedSeconds
  {
  NSDate * current = [NSDate date];
  
  return [current timeIntervalSinceDate: self.startTime];
  }

// Get the elapsed time as a string.
- (NSString *) elapsedTime
  {
  NSDate * current = [NSDate date];
  
  NSTimeInterval interval =
    [current timeIntervalSinceDate: self.startTime];

  NSUInteger minutes = (NSUInteger)interval / 60;
  NSUInteger seconds = (NSUInteger)interval - (minutes * 60);
  
  return
    [NSString
      stringWithFormat:
        @"%ld:%02ld", (unsigned long)minutes, (unsigned long)seconds];
  }
  
@end
