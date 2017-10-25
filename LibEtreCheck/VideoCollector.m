/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "VideoCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
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
  NSArray * args =
    @[
      @"-xml",
      @"SPDisplaysDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos = [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        [self printVideoInformation: infos];
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
    [self.model startElement: @"gpu"];
    
    NSString * name = [info objectForKey: @"sppci_model"];
    NSString * bus = [info objectForKey: @"sppci_bus"];
    
    if(![name length])
      name = ECLocalizedString(@"Unknown");
      
    [self.model addElement: @"name" value: name];
    [self.model addElement: @"bus" value: bus];
    
    NSString * type = ECLocalizedString(@"Discrete");
    
    if([bus isEqualToString: @"spdisplays_builtin"])
      type = ECLocalizedString(@"Integrated");
      
    NSString * vramAmount = [info objectForKey: @"spdisplays_vram"];

    if([vramAmount length] == 0)
      vramAmount = [info objectForKey: @"_spdisplays_vram"];

    NSString * vram = @"";
    
    [self.model addElement: @"vram" valueWithUnits: vramAmount];
    
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
  
    if(displays.count > 0)
      {
      [self.model startElement: @"displays"];
      
      for(NSDictionary * display in displays)
        [self printDisplayInfo: display];
      
      [self.model endElement: @"displays"];
      }
      
    [self.model endElement: @"gpu"];
    }
    
  NSNumber * errors = [[Model model] gpuErrors];
    
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
  [self.model startElement: @"display"];
      
  NSString * name = [display objectForKey: @"_name"];
  
  if([name isEqualToString: @"spdisplays_display_connector"])
    {
    NSString * status = [display objectForKey: @"spdisplays_status"];
    
    if([status isEqualToString: @"spdisplays_not_connected"])
      return;
    }
    
  if([name isEqualToString: @"spdisplays_display"])
    name = ECLocalizedString(@"Display");
    
  NSString * resolution = [display objectForKey: @"spdisplays_resolution"];

  if([resolution hasPrefix: @"spdisplays_"])
    {
    NSString * pixels = [display objectForKey: @"_spdisplays_pixels"];
    
    if(pixels)
      resolution = pixels;
    }
    
  if(name || resolution)
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"        %@ %@\n",
            name ? name : @"Unknown",
            resolution ? resolution : @""]];
      
  [self.model addElement: @"name" value: name];
  [self.model addElement: @"resolution" value: resolution];

  [self.model endElement: @"display"];
  }

@end
