/***********************************************************************
 ** Etresoft, Inc.
 ** John Daniel
 ** Copyright (c) 2016-2017. All rights reserved.
 **********************************************************************/

#import "EtreCheckCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "Model.h"
#import "XMLBuilder.h"

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
  Class appDelegate = [NSClassFromString(@"AppDelegate") new];
  
  if(appDelegate == nil)
    appDelegate = [NSClassFromString(@"EtreCheckAppDelegate") new];
  
  NSBundle * bundle = [NSBundle bundleForClass: appDelegate];
  
  NSString * version = 
    [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

  NSString * build = 
    [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];

  NSDate * date = [NSDate date];
  
  NSString * currentDate = [Utilities dateAsString: date];
              
  [self.model addElement: @"version" value: version];
  [self.model addElement: @"build" value: build];
  [self.model addElement: @"date" date: date];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n", NULL),
            version,
            build,
            currentDate]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];
    
  [self.result
    appendString: NSLocalizedString(@"downloadetrecheck", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSString * url = [Utilities buildSecureURLString: @"etrecheck.com"];
  
  [self.result
    appendAttributedString: [Utilities buildURL: url title: url]];
    
  [self.result appendString: @"\n"];
  
  NSString * runtime = [self elapsedTime];
  
  [self.model 
    addElement: @"runtime" 
    value: runtime 
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"mm:ss", @"units", nil]];

  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Runtime: %@\n", NULL), runtime]
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
  }

// Print performance.
- (void) printPerformance
  {
  [self.result
    appendString: NSLocalizedString(@"Performance: ", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSTimeInterval interval = [self elapsedSeconds];
  
  if(interval > (60 * 10))
    {
    NSString * performance = NSLocalizedString(@"poorperformance", NULL);
    
    [self.model addElement: @"performance" value: performance];
    
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
      NSLocalizedString(@"belowaverageperformance", NULL);
    
    [self.model addElement: @"performance" value: performance];
    
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
      NSLocalizedString(@"goodperformance", NULL);
    
    [self.model addElement: @"performance" value: performance];
    
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
      NSLocalizedString(@"excellentperformance", NULL);
    
    [self.model addElement: @"performance" value: performance];
    
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

  if([[Model model] adwareFound])
    [self.result
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"adwarehelp" ofType: @"rtf"]]];
    
  if([[Model model] unsignedFound])
    [self.result
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"unsignedhelp" ofType: @"rtf"]]];

  if([[Model model] cleanupRequired])
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
  
  if([[Model model] showSignatureFailures])
    {
    [self.result
      appendString:
        NSLocalizedString(
          @"Show signature failures: Enabled\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![[Model model] ignoreKnownAppleFailures])
    {
    [self.result
      appendString:
        NSLocalizedString(
          @"Ignore expected failures in Apple tasks: Disabled\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![[Model model] hideAppleTasks])
    {
    [self.result
      appendString:
        NSLocalizedString(
          @"Hide Apple tasks: Disabled\n", NULL)
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
  NSArray * terminatedTasks = [[Model model] terminatedTasks];
  
  if(terminatedTasks.count > 0)
    {
    [self.result
      appendString:
        NSLocalizedString(
          @"The following internal tasks failed to complete:\n", NULL)
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
    
  if([[[Model model] whitelistFiles] count] < kMinimumWhitelistSize)
    {
    [self.result
      appendString:
        NSLocalizedString(@"Failed to read adware signatures!", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    [self.result appendString: @"\n\n"];
    }
      
  if([NSLocalizedString(@"downloadetrecheck", NULL) length] == 17)
    {
    NSString * message = @"Failed to load language resources!";
    
    NSLocale * locale = [NSLocale currentLocale];
  
    NSString * language =
      [[locale objectForKey: NSLocaleLanguageCode] lowercaseString];

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

// Print the problem from the user.
- (void) printProblem
  {
  [self.result
    appendString: NSLocalizedString(@"Problem: ", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  
  [self.model addElement: @"problem" value: [[Model model] problem]];

  [self.result appendString: [[Model model] problem]];
  [self.result appendString: @"\n"];
    
  NSAttributedString * problemDescription = 
    [[Model model] problemDescription];
  
  if(problemDescription.string.length > 0)
    {
    [self.model
      addElement: @"problemdescription" value: problemDescription.string];

    [self.result
      appendString: NSLocalizedString(@"Description:\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    [self.result appendAttributedString: problemDescription];
    [self.result appendString: @"\n"];
    }
    
  [self.result appendString: @"\n"];
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
