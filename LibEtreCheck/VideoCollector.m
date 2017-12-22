/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "VideoCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import "NSString+Etresoft.h"
#import "Model.h"
#import "SubProcess.h"
#import "XMLBuilder.h"
#import "LocalizedString.h"

@implementation VideoCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"video"];
  
  if(self != nil)
    {
    }
    
  return self;
  }

// Collect video information.
- (void) performCollect
  {
  NSString * key = @"SPDisplaysDataType";
  
  NSArray * args =
    @[
      @"-xml",
      key
    ];
  
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
        NSArray * infos = [results objectForKey: @"_items"];
          
        if([NSArray isValid: infos] && (infos.count > 0))
          [self printVideoInformation: infos];
        }
      }
    }
    
  [subProcess release];
  }

// Print video information.
- (void) printVideoInformation: (NSArray *) infos
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  for(NSDictionary * info in infos)
    {
    [self.xml startElement: @"gpu"];
    
    NSString * name = [info objectForKey: @"sppci_model"];
    NSString * bus = [info objectForKey: @"sppci_bus"];
    
    if(![NSString isValid: name])
      name = ECLocalizedString(@"Unknown");
      
    [self.xml addElement: @"name" value: name];
    [self.xml addElement: @"bus" value: bus];
    
    NSString * type = ECLocalizedString(@"Discrete");
    
    if([NSString isValid: bus])
      if([bus isEqualToString: @"spdisplays_builtin"])
        type = ECLocalizedString(@"Integrated");
      
    NSString * vramAmount = [info objectForKey: @"spdisplays_vram"];

    if(![NSString isValid: vramAmount])
      vramAmount = [info objectForKey: @"_spdisplays_vram"];

    NSString * vram = @"";
    
    [self.xml addElement: @"vram" valueWithUnits: vramAmount];
    
    if(vramAmount)
      vram =
        [NSString
          stringWithFormat:
            ECLocalizedString(@"VRAM: %@"),
            [Utilities translateSize: vramAmount]];
      
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@ (%@) %@%@\n",
            name ? name : @"",
            type,
            [vram length] ? @" - " : @"",
            vram]];
      
    NSArray * displays = [info objectForKey: @"spdisplays_ndrvs"];
  
    if([NSArray isValid: displays] && (displays.count > 0))
      {
      [self.xml startElement: @"displays"];
      
      for(NSDictionary * display in displays)
        [self printDisplayInfo: display];
      
      [self.xml endElement: @"displays"];
      }
      
    [self.xml endElement: @"gpu"];
    }
    
  NSNumber * errors = [self.model gpuErrors];
    
  int errorCount = [errors intValue];
  
  if(errorCount)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"GPU failure! - %@\n"),
            ECLocalizedPluralString(errorCount, @"error")]
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
  [self.result appendCR];
  }

// Print information about a display.
- (void) printDisplayInfo: (NSDictionary *) display
  {
  [self.xml startElement: @"display"];
      
  NSString * name = [display objectForKey: @"_name"];
  
  if([NSString isValid: name])
    {
    if([name isEqualToString: @"spdisplays_display_connector"])
      {
      NSString * status = [display objectForKey: @"spdisplays_status"];
      
      if([NSString isValid: status])
        if([status isEqualToString: @"spdisplays_not_connected"])
          return;
      }
    
    if([name isEqualToString: @"spdisplays_display"])
      name = ECLocalizedString(@"Display");
    }
    
  NSString * resolution = [display objectForKey: @"spdisplays_resolution"];

  if([NSString isValid: resolution])
    if([resolution hasPrefix: @"spdisplays_"])
      {
      NSString * pixels = [display objectForKey: @"_spdisplays_pixels"];
      
      if([NSString isValid: pixels])
        resolution = pixels;
      }
    
  if([NSString isValid: name] || [NSString isValid: resolution])
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"        %@ %@\n",
            name ? name : @"Unknown",
            resolution ? resolution : @""]];
      
  [self.xml addElement: @"name" value: name];
  [self.xml addElement: @"resolution" value: resolution];

  [self.xml endElement: @"display"];
  }

@end
