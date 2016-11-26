/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "FontsCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "SubProcess.h"
#import "XMLBuilder.h"

// Collect font information.
@implementation FontsCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"fonts"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self updateStatus: NSLocalizedString(@"Checking fonts", NULL)];

  NSArray * badFonts = [self collectBadFonts];
  
  if([badFonts count])
    {
    [self.result appendAttributedString: [self buildTitle]];
    
    for(NSDictionary * font in badFonts)
      {
      NSString * name = [font objectForKey: @"_name"];
      NSString * path = [font objectForKey: @"path"];
      NSNumber * valid = [font objectForKey: @"valid"];

      if(![valid boolValue])
        {
        [self.XML startElement: @"badfont"];
        
        [self.XML addElement: @"name" value: name];
        [self.XML
          addElement: @"path" value: [Utilities cleanPath: path]];

        [self.XML endElement: @"badfont"];
        
        [self.result
          appendString:
            [NSString
              stringWithFormat:
                NSLocalizedString(
                  @"    %@: %@\n", NULL),
                name,
                [Utilities cleanPath: path]]];
        }
      }
      
    [self.result appendCR];
    }
  }

// Collect bad fonts.
- (NSArray *) collectBadFonts
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPFontsDataType"
    ];
  
  NSMutableArray * badFonts = [NSMutableArray array];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * fonts =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([fonts count])
        for(NSDictionary * font in fonts)
          {
          NSNumber * valid = [font objectForKey: @"valid"];
 
          if(![valid boolValue])
            [badFonts addObject: font];
          }
      }
    }

  [subProcess release];
  
  return badFonts;
  }

@end
