/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "FontsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"
#import "NSString+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSNumber+Etresoft.h"
#import "Model.h"

// Collect font information.
@implementation FontsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"fonts"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Perform the collection.
- (void) performCollect
  {
  NSArray * badFonts = [self collectBadFonts];
  
  if([badFonts count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    for(NSDictionary * font in badFonts)
      {
      NSString * name = [font objectForKey: @"_name"];
      NSString * path = [font objectForKey: @"path"];

      if(![NSString isValid: name])
        continue;
        
      if(![NSString isValid: path])
        continue;
        
      NSString * cleanPath = [self cleanPath: path];
      
      [self.xml startElement: @"font"];
      
      [self.xml addElement: @"name" value: name];
      [self.xml addElement: @"path" value: cleanPath];
      
      [self.xml endElement: @"font"];
      
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(@"    %@: %@\n"), name, cleanPath]];
      }
      
    [self.result appendCR];
    }
  }

// Collect bad fonts.
- (NSArray *) collectBadFonts
  {
  NSString * key = @"SPFontsDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
  NSMutableArray * badFonts = [NSMutableArray array];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess loadDebugOutput: [self.model debugInputPath: key]];      
  [subProcess saveDebugOutput: [self.model debugOutputPath: key]];

  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if([NSArray isValid: plist])
      {
      NSDictionary * results = [plist objectAtIndex: 0];
        
      if([NSDictionary isValid: results])
        {
        NSArray * fonts = [results objectForKey: @"_items"];
          
        if([NSArray isValid: fonts])
          for(NSDictionary * font in fonts)
            if([NSDictionary isValid: font])
              {
              NSString * name = [font objectForKey: @"_name"];
              NSNumber * valid = [font objectForKey: @"valid"];

              if(![NSString isValid: name])
                continue;
                
              if(![NSNumber isValid: valid])
                continue;
                
              if(self.simulating && [name hasPrefix: @"Arial"])
                valid = nil;
              
              if(![valid boolValue])
                [badFonts addObject: font];
              }
        }
      }
    }

  [subProcess release];
  
  return badFonts;
  }

@end
