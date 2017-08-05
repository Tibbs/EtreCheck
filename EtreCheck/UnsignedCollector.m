/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "UnsignedCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"
#import "XMLBuilder.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kAdwareExtensionsKey @"adwareextensions"
#define kBlacklistKey @"blacklist"
#define kBlacklistSuffixKey @"blacklist_suffix"
#define kBlacklistMatchKey @"blacklist_match"

// Collect information about unsigned files.
@implementation UnsignedCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"unsigned"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Print any adware found.
- (void) performCollect
  {
  if([[Model model] unsignedFound])
    {
    NSMutableArray * possibleAdwareFiles = [NSMutableArray array];
    
    // Add the possible adware.
    for(NSString * unknownFile in [[Model model] unknownLaunchdFiles])
      {
      NSDictionary * info =
        [[[Model model] unknownLaunchdFiles] objectForKey: unknownFile];
      
      NSString * signature = [info objectForKey: kSignature];
      NSString * status = [info objectForKey: kStatus];
      
      // This will go into clean up instead.
      if([signature isEqualToString: kExecutableMissing])
        continue;
        
      NSString * executable =
        [Utilities formatExecutable: [info objectForKey: kCommand]];
      
      if(!executable)
        executable = @"";
      
      // Try to guess if this is adware.
      NSString * type = @"unknownfile";
      
      if([[info objectForKey: kProbableAdware] boolValue])
        type = @"probableadware";
        
      NSDictionary * possibleAdware =
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            unknownFile, @"key",
            type, @"type",
            executable, @"executable",
            status, @"status",
            nil];
        
      [possibleAdwareFiles addObject: possibleAdware];
      }

    // Add more possible adware.
    for(NSString * unknownFile in [[Model model] unknownFiles])
      {
      NSDictionary * possibleAdware =
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            unknownFile, @"key",
            @"unknownfile", @"type",
            @"", @"executable",
            nil];
        
      [possibleAdwareFiles addObject: possibleAdware];
      }
      
    NSArray * sortedAdwareFiles =
      [possibleAdwareFiles
        sortedArrayUsingComparator:
          ^NSComparisonResult(id obj1, id obj2)
            {
            NSString * key1 = [obj1 objectForKey: @"key"];
            NSString * key2 = [obj2 objectForKey: @"key"];

            return [key1 compare: key2];
            }];


    if([sortedAdwareFiles count] == 0)
      return;
      
    [self.result appendAttributedString: [self buildTitle]];
    
    __block int adwareCount = 0;
    
    [sortedAdwareFiles
      enumerateObjectsUsingBlock:
        ^(id obj, NSUInteger idx, BOOL * stop)
          {
          NSString * name = [obj objectForKey: @"key"];
          NSString * executable = [obj objectForKey: @"executable"];
          NSString * status = [obj objectForKey: @"status"];
          
          NSString * extra =
            ([executable length] > 0)
              ? [NSString stringWithFormat: @"\n    \t%@", executable]
              : @"";
            
          ++adwareCount;
          [self.result appendString: @"    "];
              
          NSString * prettyPath = [Utilities prettyPath: name];
          
          NSString * prefix = [Utilities bundleName: name];
          
          BOOL likelyLegitimate = 
            [[[Model model] legitimateStrings] containsObject: prefix];

          NSDictionary * attributes =
            likelyLegitimate
              ? [NSDictionary dictionary]
              : @{
                  NSFontAttributeName : [[Utilities shared] boldFont],
                  NSForegroundColorAttributeName : [[Utilities shared] red],
                };
                
          [self.result appendString: prettyPath attributes: attributes];
              
          if([status isEqualToString: kStatusLoaded])
            {
            NSAttributedString * disableLink = 
              [self generateDisableLink: name];

            if(disableLink)
              [self.result appendAttributedString: disableLink];
            }
            
          if([status isEqualToString: kStatusNotLoaded])
            {
            NSAttributedString * enableLink = 
              [self generateEnableLink: name];

            if(enableLink)
              [self.result appendAttributedString: enableLink];
            }
            
          if([extra length])
            [self.result appendString: extra attributes: attributes];
            
          [self.result appendString: @"\n"];
          
          [self.model startElement: @"unsigned"];
          
          [self.model addElement: @"path" value: prettyPath];
          [self.model addElement: @"executable" value: executable];
         
          [self.model endElement: @"unsigned"];
          }];
      
    NSString * message =
      TTTLocalizedPluralString(adwareCount, @"unsigned file", NULL);

    [self.result appendString: @"    "];
    [self.result appendString: message];  
      
    [self.result appendCR];
    [self.result appendCR];
    }
  }

// Generate a "disable" link.
- (NSAttributedString *) generateDisableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/disable?%@", encodedPath];

  [urlString
    appendString: NSLocalizedString(@"[Disable]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

// Generate an "enable" link.
- (NSAttributedString *) generateEnableLink: (NSString *) path
  {
  NSMutableAttributedString * urlString =
    [[NSMutableAttributedString alloc] initWithString: @""];
    
  [urlString appendString: @" "];
  
  NSString * encodedPath = 
    [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString * url = 
    [NSString 
      stringWithFormat: @"etrecheck://unsigned/enable?%@", encodedPath];
  
  [urlString
    appendString: NSLocalizedString(@"[Enable]", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont],
        NSLinkAttributeName : url
      }];
    
  return [urlString autorelease];
  }

@end
