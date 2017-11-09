/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "HardwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "SubProcess.h"
#import "ByteCountFormatter.h"
#import "XMLBuilder.h"
#import "NumberFormatter.h"
#import "LocalizedString.h"
#import "EtreCheckConstants.h"
#import "OSVersion.h"

// Some keys to be returned from machine lookuup.
#define kMachineIcon @"machineicon"
#define kMachineName @"machinename"

// Collect hardware information.
@implementation HardwareCollector

@synthesize properties = myProperties;
@synthesize machineIcon = myMachineIcon;
@synthesize genericDocumentIcon = myGenericDocumentIcon;
@synthesize marketingName = myMarketingName;
@synthesize EnglishMarketingName = myEnglishMarketingName;
@synthesize CPUCode = myCPUCode;
@synthesize supportsHandoff = mySupportsHandoff;
@synthesize supportsInstantHotspot = mySupportsInstantHotspot;
@synthesize supportsLowEnergy = mySupportsLowEnergy;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"hardware"];
  
  if(self != nil)
    {
    // Do this in the constructor so the data is available before
    // collection starts.
    [self loadProperties];    
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  self.genericDocumentIcon = nil;
  self.CPUCode = nil;
  self.EnglishMarketingName = nil;
  self.marketingName = nil;
  self.machineIcon = nil;
  self.properties = nil;
  
  [super dealloc];
  }

// Load machine properties.
- (void) loadProperties
  {
  // First look for a machine attributes file.
  self.properties =
    [NSDictionary
      readPropertyList: ECLocalizedString(@"machineattributes")];
    
  // Don't give up yet. Try the old one too.
  if(!self.properties)
    self.properties =
      [NSDictionary
        readPropertyList:
          ECLocalizedString(@"oldmachineattributes")];
    
  // This is as good a place as any to collect this.
  NSString * computerName =
    (NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);

  NSString * hostName = (NSString *)SCDynamicStoreCopyLocalHostName(NULL);

  // Load the machine image.
  [[Model model] setComputerName: computerName];
  [[Model model] setHostName: hostName];
  
  if(self.machineIcon != nil)
    [[Model model] setMachineIcon: self.machineIcon];
  
  [computerName release];
  [hostName release];
  }

// Perform the collection.
- (void) performCollect
  {
  [self collectBluetooth];
  [self collectSysctl];
  [self collectHardware];
  [self collectNetwork];
  [self collectiCloud];
    
  [self.result appendCR];
  }

// Collect bluetooth information.
- (void) collectBluetooth
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPBluetoothDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos respondsToSelector: @selector(objectAtIndex:)])
        if([infos count])
          for(NSDictionary * info in infos)
            {
            if([info respondsToSelector: @selector(objectForKey:)])
              {
              NSDictionary * localInfo =
                [info objectForKey: @"local_device_title"];
              
              NSString * generalSupportsHandoff =
                [localInfo objectForKey: @"general_supports_handoff"];
              NSString * generalSupportsInstantHotspot =
                [localInfo
                  objectForKey: @"general_supports_instantHotspot"];
              NSString * generalSupportsLowEnergy =
                [localInfo objectForKey: @"general_supports_lowEnergy"];
                
              self.supportsHandoff =
                [generalSupportsHandoff isEqualToString: @"attrib_Yes"];
              self.supportsInstantHotspot =
                [generalSupportsInstantHotspot
                  isEqualToString: @"attrib_Yes"];
              self.supportsLowEnergy =
                [generalSupportsLowEnergy isEqualToString: @"attrib_Yes"];                
              }
            }
      }
    }
    
  [subProcess release];
  }

// Collect sysctl information.
- (void) collectSysctl
  {
  NSString * code = nil;
  
  NSArray * args = @[@"machdep.cpu.brand_string"];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/sysctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      if([line hasPrefix: @"machdep.cpu.brand_string:"])
        if([line length] > 26)
          {
          NSString * description = [line substringFromIndex: 26];
          NSArray * parts = [description componentsSeparatedByString: @" "];
          
          NSUInteger count = [parts count];
          
          for(NSUInteger i = 0; i < count; ++i)
            {
            NSString * part = [parts objectAtIndex: i];
            
            if([part isEqualToString: @"CPU"])
              if(i > 0)
                code = [parts objectAtIndex: i - 1];
            }
          }
    }
    
  [subProcess release];
  
  if([code length] > 0)
    self.CPUCode = code;
  }

// Collect hardware information.
- (void) collectHardware
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPHardwareDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        {
        [self.result appendAttributedString: [self buildTitle]];

        for(NSDictionary * info in infos)
          [self printMachineInformation: info];
          
        [self printBluetoothInformation];
        [self printWirelessInformation];
        [self printBatteryInformation];
        }
      }
    }
    
  [subProcess release];
  }

// Print informaiton for the machine.
- (void) printMachineInformation: (NSDictionary *) info
  {
  NSString * name = [info objectForKey: @"machine_name"];
  NSString * model = [info objectForKey: @"machine_model"];
  NSString * cpu_type = [info objectForKey: @"cpu_type"];
  NSNumber * core_count =
    [info objectForKey: @"number_processors"];
  NSString * speed =
    [info objectForKey: @"current_processor_speed"];
  NSNumber * cpu_count = [info objectForKey: @"packages"];
  NSString * memory = [info objectForKey: @"physical_memory"];
  NSString * serial = [info objectForKey: @"serial_number"];

  [[Model model] setModel: model];
  
  // Extract the memory.
  [[Model model]
    setPhysicalRAM: [self parseMemory: memory]];

  if(self.simulating)
    memory = @"2 GB";
    
  [[Model model] setSerialCode: [serial substringFromIndex: 8]];

  // Print the human readable machine name, if I can find one.
  [self printHumanReadableMacName: model];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(@"    %@ - %@: %@\n"),
          name, ECLocalizedString(@"model"), model]];
    
  [self.model addElement: @"name" value: name];
  [self.model addElement: @"model" value: model];
    
  NSString * code = @"";
  
  if([self.CPUCode length] > 0)
    code = [NSString stringWithFormat: @" (%@)", self.CPUCode];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          ECLocalizedString(
            @"    %@ %@ %@%@ CPU: %@-core\n"),
          cpu_count,
          speed,
          cpu_type ? cpu_type : @"",
          code,
          core_count]];
    
  [self.model addElement: @"cpucount" number: cpu_count];
  [self.model addElement: @"speed" valueWithUnits: speed];
  [self.model addElement: @"cpu_type" value: cpu_type];      
  [self.model addElement: @"cpucode" value: self.CPUCode];
  [self.model addElement: @"corecount" number: core_count];

  [self printMemory: memory];
  }

// Parse a memory string into an int (in GB).
- (int) parseMemory: (NSString *) memory
  {
  NSScanner * scanner = [NSScanner scannerWithString: memory];

  int physicalMemory;
  
  if(![scanner scanInt: & physicalMemory])
    physicalMemory = 0;

  if(self.simulating)
    physicalMemory = 2;
    
  return physicalMemory;
  }

// Extract a "marketing name" for a machine from a serial number.
- (void) printHumanReadableMacName: (NSString *) code
  {
  // Try to get the marketing name from Apple.
  [self askAppleForMarketingName];
  
  // Get information on my own.
  NSDictionary * machineProperties = [self lookupMachineProperties: code];
  
  if(machineProperties)
    if(![self.marketingName length])
      self.marketingName = [machineProperties objectForKey: kMachineName];
      
  [self.result
    appendString:
      [NSString
        stringWithFormat: @"    %@ \n", self.marketingName]];
      
  [self.model addElement: @"marketingname" value: self.marketingName];
    
  NSString * language = ECLocalizedString(@"en");

  [self.result appendString: @"    "];
  
  NSString * url = [self technicalSpecificationsURL: language];
  
  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          ECLocalizedString(
            @"[Technical Specifications]")]];

  [self.model
    addElement: @"technicalspecificationsurl"
    url: [NSURL URLWithString: url]];

  [self.result appendString: @" - "];

  url = [self userGuideURL: language];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          ECLocalizedString(
            @"[User Guide]")]];
    
  [self.model 
    addElement: @"userguideurl" url: [NSURL URLWithString: url]];

  [self.result appendString: @" - "];

  url = [self serviceURL];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          ECLocalizedString(
            @"[Warranty & Service]")]];

  [self.model
    addElement: @"warrantyandserviceurl"
    url: [NSURL URLWithString: url]];

  [self.result appendString: @"\n"];
  }

// Try to get the marketing name directly from Apple.
- (void) askAppleForMarketingName
  {
  NSString * language = ECLocalizedString(@"en");
  
  self.marketingName = [self askAppleForMarketingName: language];
  
  if([language isEqualToString: @"en"])
    self.EnglishMarketingName = self.marketingName;
  else
    self.EnglishMarketingName = [self askAppleForMarketingName: @"en"];
  }

// Try to get the marketing name directly from Apple.
- (NSString *) askAppleForMarketingName: (NSString *) language
  {
  return
    [Utilities
      askAppleForMarketingName: [[Model model] serialCode]
      language: language
      type: @"product?"];
  }

// Construct a technical specifications URL.
- (NSString *) technicalSpecificationsURL: (NSString *) language
  {
  return
    [Utilities
      AppleSupportSPQueryURL: [[Model model] serialCode]
      language: language
      type: @"index?page=cpuspec"];
  }

// Construct a user guide URL.
- (NSString *) userGuideURL: (NSString *) language
  {
  return
    [Utilities
      AppleSupportSPQueryURL: [[Model model] serialCode]
      language: language
      type: @"index?page=cpuuserguides"];
  }

// Construct a memory upgrade URL.
- (NSString *) memoryUpgradeURL: (NSString *) language
  {
  return
    [Utilities
      AppleSupportSPQueryURL: [[Model model] serialCode]
      language: language
      type: @"index?page=cpumemory"]; 
  }

// Construct a user guide URL.
- (NSString *) serviceURL
  {
  NSString * localeCode = [Utilities localeCode];
  
  NSString * url =
    @"https://support.apple.com/%@/mac-desktops/repair/service";
  
  if([[[Model model] model] hasPrefix: @"MacBook"])
    url = @"https://support.apple.com/%@/mac-notebooks/repair/service";

  return [NSString stringWithFormat: url, localeCode];
  }

// Try to get information about the machine from system resources.
- (NSDictionary *) lookupMachineProperties: (NSString *) code
  {
  // If I have a machine code, try to look up the built-in attributes.
  if(code)
    if(self.properties)
      {
      NSDictionary * modelInfo = [self.properties objectForKey: code];
      
      // Load the machine image.
      if(self.machineIcon == nil)
        self.machineIcon = [self findCurrentMachineIcon];
      
      // Get machine name.
      NSString * machineName = [self lookupMachineName: modelInfo];
        
      // Fallback.
      if(!machineName)
        machineName = code;
        
      NSMutableDictionary * result = [NSMutableDictionary dictionary];
      
      [result setObject: machineName forKey: kMachineName];
      
      if(self.machineIcon)
        [result setObject: self.machineIcon forKey: kMachineIcon];
        
      return result;
      }
  
  return nil;
  }

// Get the machine name.
- (NSString *) lookupMachineName: (NSDictionary *) machineInformation
  {
  // Now get the machine name.
  NSDictionary * localizedModelInfo =
    [machineInformation objectForKey: @"_LOCALIZABLE_"];
    
  // New machines.
  NSString * machineName =
    [localizedModelInfo objectForKey: @"marketingModel"];

  // Older machines.
  if(!machineName)
    machineName = [localizedModelInfo objectForKey: @"description"];
    
  return machineName;
  }

// Find a machine icon.
- (NSImage *) findCurrentMachineIcon
  {
  NSImage * icon = [NSImage imageNamed: NSImageNameComputer];
  
  [icon setSize: NSMakeSize(1024, 1024)];

  return icon;
  }

// Print memory, flagging insufficient amounts.
- (void) printMemory: (NSString *) memory
  {
  NSDictionary * details = [self collectMemoryDetails];
  
  bool upgradeable = NO;
  NSString * upgradeableString = @"";
  
  if(details)
    {
    NSString * isUpgradeable =
      [details objectForKey: @"is_memory_upgradeable"];
    
    upgradeable = [isUpgradeable boolValue];
    
    if(self.simulating)
      upgradeable = true;
      
    // Snow Leopoard doesn't seem to report this.
    if(isUpgradeable != nil)
      upgradeableString =
        upgradeable
          ? ECLocalizedString(@"Upgradeable")
          : ECLocalizedString(@"Not upgradeable");
    }
    
  if([[Model model] physicalRAM] < 4)
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@ RAM - %@ %@",
            memory,
            ECLocalizedString(@"insufficientram"),
            upgradeableString]
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  else
    [self.result
      appendString:
        [NSString
          stringWithFormat: @"    %@ RAM %@", memory, upgradeableString]];

  [self.model addElement: @"ram" valueWithUnits: memory];
  
  NSString * language = ECLocalizedString(@"en");

  NSString * url = [self memoryUpgradeURL: language];
  
  [self.model addElement: @"upgradeable" boolValue: upgradeable];
  
  if(upgradeable)
    {
    [self.result appendString: @" - "];

    [self.result
      appendAttributedString:
        [Utilities
          buildURL: url
          title:
            ECLocalizedString(
              @"[Instructions]\n")]];
      
    [self.model
      addElement: @"memoryupgradeinstructionsurl"
      url: [NSURL URLWithString: url]];
    }
  else
    [self.result appendString: @"\n"];
    
  if(details)
    {
    NSArray * banks = [details objectForKey: @"_items"];
    
    if(banks)
      [self printMemoryBanks: banks];
    }
  }

- (NSDictionary *) collectMemoryDetails
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPMemoryDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  [subProcess autorelease];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        return [infos objectAtIndex: 0];
      }
    }
    
  return nil;
  }

// Print memory banks.
- (void) printMemoryBanks: (NSArray *) banks
  {
  [self.model startElement: @"memorybanks"];
  
  for(NSDictionary * bank in banks)
    {
    NSString * name = [bank objectForKey: @"_name"];
    NSString * size = [bank objectForKey: @"dimm_size"];
    NSString * type = [bank objectForKey: @"dimm_type"];
    NSString * speed = [bank objectForKey: @"dimm_speed"];
    NSString * status = [bank objectForKey: @"dimm_status"];
    
    NSString * currentBankID = name;
      
    if([size isEqualToString: @"(empty)"])
      size = @"empty";
      
    NSString * empty = ECLocalizedString(@"Empty");
    
    if([size isEqualToString: @"empty"])
      {
      size = empty;
      type = @"";
      speed = @"";
      status = @"";
      }
      
    NSString * currentBankInfo =
      [NSString
        stringWithFormat:
          @"            %@ %@ %@ %@\n", size, type, speed, status];
      
    [self.result appendString: @"        "];
    [self.result appendString: currentBankID];
    [self.result appendString: @"\n"];
    [self.result appendString: currentBankInfo];
    
    [self.model startElement: @"memorybank"];
    
    [self.model addElement: @"identifier" value: currentBankID];
    [self.model addElement: @"size" valueWithUnits: size];
    [self.model addElement: @"type" value: type];
    [self.model addElement: @"speed" valueWithUnits: speed];
    [self.model addElement: @"status" value: status];

    [self.model endElement: @"memorybank"];
    }

  [self.model endElement: @"memorybanks"];
  }

// Print information about bluetooth.
- (void) printBluetoothInformation
  {
  NSString * info = [self collectBluetoothInformation];
  
  [self.result
    appendString:
      [NSString 
        stringWithFormat: 
          ECLocalizedString(@"    Handoff/Airdrop2: %@\n"), info]];
  }

// Collect bluetooth information.
- (NSString *) collectBluetoothInformation
  {
  [self.model 
    addElement: @"continuity" boolValue: [self supportsContinuity]];

  if([self supportsContinuity])
    return ECLocalizedString(@"supported");
              
  return ECLocalizedString(@"not supported");
  }

// Is continuity supported?
- (bool) supportsContinuity
  {
  if(self.supportsHandoff)
    return YES;
    
  NSString * model = [[Model model] model];
  
  NSString * specificModel = nil;
  int target = 0;
  int number = 0;
  
  if([model hasPrefix: @"MacBookPro"])
    {
    specificModel = @"MacBookPro";
    target = 9;
    }
  else if([model hasPrefix: @"iMac"])
    {
    specificModel = @"iMac";
    target = 13;
    }
  else if([model hasPrefix: @"MacPro"])
    {
    specificModel = @"MacPro";
    target = 6;
    }
  else if([model hasPrefix: @"MacBookAir"])
    {
    specificModel = @"MacBookAir";
    target = 5;
    }
  else if([model hasPrefix: @"MacBook"])
    {
    specificModel = @"MacBook";
    target = 8;
    }
  else if([model hasPrefix: @"Macmini"])
    {
    specificModel = @"Macmini";
    target = 6;
    }
    
  if(specificModel)
    {
    NSScanner * scanner = [NSScanner scannerWithString: model];
    
    if([scanner scanString: specificModel intoString: NULL])
      if([scanner scanInt: & number])
        if(number >= target)
          self.supportsHandoff = YES;
    }
    
  return self.supportsHandoff;
  }

// Print wireless information.
- (void) printWirelessInformation
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPAirPortDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        {
        for(NSDictionary * info in infos)
          {
          NSArray * interfaces =
            [info objectForKey: @"spairport_airport_interfaces"];
            
          NSUInteger count = [interfaces count];
          
          if(interfaces)
            [self.result
              appendString:
                [NSString
                  stringWithFormat:
                    ECLocalizedString(@"    Wireless: %@"),
                    ECLocalizedPluralString(count, @"interface")]];
          
          for(NSDictionary * interface in interfaces)
            [self
              printWirelessInterface: interface
              indent: count > 1 ? @"        " : @" "];
          }
        }
      }
    }
    
  [subProcess release];
  }

// Print a single wireless interface.
- (void) printWirelessInterface: (NSDictionary *) interface
  indent: (NSString *) indent
  {
  NSString * name = [interface objectForKey: @"_name"];
  NSString * modes = 
    [interface objectForKey: @"spairport_supported_phymodes"];

  if(([name length] > 0) && ([modes length] > 0))
    {
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            ECLocalizedString(@"%@%@: %@\n"), indent, name, modes]];
    
    [self.model startElement: @"wireless"];

    [self.model addElement: @"name" value: name];
    [self.model addElement: @"modes" value: modes];

    [self.model endElement: @"wireless"];
    }
    
  else if([name length] > 0)
    {
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            ECLocalizedString(@"%@%@: %@\n"), 
            indent, 
            name, 
            ECLocalizedString(@"Unknown")]];

    [self.model startElement: @"wireless"];

    [self.model addElement: @"name" value: name];

    [self.model endElement: @"wireless"];
    }
            
  else
    {
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            @"%@%@\n", indent, ECLocalizedString(@"Unknown")]];

    [self.model addElement: @"wireless"];
    }
  }

// Print battery information.
- (void) printBatteryInformation
  {
  NSArray * args =
    @[
      @"-xml",
      @"SPPowerDataType"
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/sbin/system_profiler" arguments: args])
    {
    NSArray * plist =
      [NSArray readPropertyListData: subProcess.standardOutput];
  
    if(plist && [plist count])
      {
      NSArray * infos =
        [[plist objectAtIndex: 0] objectForKey: @"_items"];
        
      if([infos count])
        [self printBatteryInformation: infos];
      }
    }
    
  [subProcess release];
  }

// Print battery information.
- (void) printBatteryInformation: (NSArray *) infos
  {
  NSNumber * cycleCount = nil;
  NSString * health = nil;
  NSString * serialNumber = @"";
  BOOL serialNumberInvalid = NO;
  
  for(NSDictionary * info in infos)
    {
    NSDictionary * healthInfo =
      [info objectForKey: @"sppower_battery_health_info"];
      
    if(healthInfo)
      {
      cycleCount =
        [healthInfo objectForKey: @"sppower_battery_cycle_count"];
      health = [healthInfo objectForKey: @"sppower_battery_health"];
      }

    NSDictionary * modelInfo =
      [info objectForKey: @"sppower_battery_model_info"];
      
    if(modelInfo)
      {
      serialNumber =
        [modelInfo objectForKey: @"sppower_battery_serial_number"];
      
      if([serialNumber isEqualToString: @"0123456789ABC"])
      //if([serialNumber isEqualToString: @"D865033Y2CXF9CPAW"])
        serialNumberInvalid = YES;
      }
    }
    
  if(self.simulating)
    health = @"Poor";
    
  if(cycleCount && [health length])
    {
    BOOL flagged = NO;
    
    if([health isEqualToString: @"Poor"])
      flagged = YES;
      
    if([health isEqualToString: @"Check Battery"])
      flagged = YES;
      
    if(flagged)
      [self.result
        appendString:
          [NSString
            stringWithFormat:
            ECLocalizedString(
              @"    Battery: Health = %@ - Cycle count = %@\n"),
            ECLocalizedStringFromTable(health, @"System"), cycleCount]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(
                @"    Battery: Health = %@ - Cycle count = %@\n"),
              ECLocalizedStringFromTable(health, @"System"), 
              cycleCount]];
      
    [self.model addElement: @"batteryhealth" value: health];
    
    [self.model addElement: @"batterycyclecount" number: cycleCount];
    
    [self.model 
      addElement: @"batterypercent" 
      intValue: cycleCount.intValue * 100 / [self getLifetimeCycles]];
      
    //[self.model addElement: @"batteryserialnumber" value: serialNumber];
    
    if(serialNumberInvalid)
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              ECLocalizedString(
                @"        Battery serial number %@ invalid\n"),
                serialNumber]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  }

// Get the number of lifetime batter cycles for this machine.
- (int) getLifetimeCycles
  {
  int cycles = 1000;
  
  NSString * model = [[Model model] model];
  
  NSArray * parts = [model componentsSeparatedByString: @","];
  
  if(parts.count == 2)
    {
    NSString * majorString = [parts firstObject];
    
    if([model hasPrefix: @"MacBookPro"])
      majorString = [majorString substringFromIndex: 10];
    else if([model hasPrefix: @"MacBookAir"])
      majorString = [majorString substringFromIndex: 10];
    else if([model hasPrefix: @"MacBook"])
      majorString = [majorString substringFromIndex: 7];

    int major = 
      [[[NumberFormatter sharedNumberFormatter] 
        convertFromString: majorString] 
          intValue];

    if([model hasPrefix: @"MacBookPro"])
      {
      if([model isEqualToString: @"MacBookPro5,1"])
        {
        BOOL oldModel = 
          [self.EnglishMarketingName 
            isEqualToString: @"MacBook Pro (15-inch Late 2008)"];
        
        if(oldModel)
          cycles = 500;
        }
      else if(major < 5)
        cycles = 300;
      }
    else if([model hasPrefix: @"MacBookAir"])
      {
      if([model isEqualToString: @"MacBookAir2,1"])
        {
        BOOL newModel = 
          [self.EnglishMarketingName 
            isEqualToString: @"MacBook Air (Mid 2009)"];
        
        if(newModel)
          cycles = 500;
        else
          cycles = 300;
        }
      else if(major < 2)
        cycles = 300;
      }
    else if([model hasPrefix: @"MacBook"])
      {
      if([model isEqualToString: @"MacBook5,1"])
        cycles = 500;
      else if(major < 6)
        cycles = 300;
      }
    }
    
  return cycles;
  }
  
// Collect network information.
- (void) collectNetwork
  {
  NSArray * args =
    @[
      @"--proxy",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  NSMutableArray * proxies = [NSMutableArray new];
  
  if([subProcess execute: @"/usr/sbin/scutil" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
          
      NSRange range = [trimmedLine rangeOfString: @"Enable : 1"];
      
      if(range.location != NSNotFound)
        {
        NSString * proxy = [trimmedLine substringToIndex: range.location];
        
        if([proxy length] > 0)
          {
          [self.result
            appendString:
              [NSString
                stringWithFormat:
                  ECLocalizedString(@"    Proxy: %@\n"), proxy]];
          
          [proxies addObject: proxy];
          }
        }
      }
    }
    
  if(self.simulating)
    [proxies addObject: @"Simulated proxy"];
    
  if(proxies.count > 0)
    {
    [self.model startElement: @"proxies"];
    
    for(NSString * proxy in proxies)
      [self.model addElement: @"proxy" value: proxy];
      
    [self.model endElement: @"proxies"];
    }
    
  [proxies release];
    
  [subProcess release];
  }

// Collect iCloud information.
- (void) collectiCloud
  {
  int version = [[OSVersion shared] major];

  if(version < kElCapitan)
    return;
    
  int count = 0;
    
  NSString * pendingFileCount = nil;
  NSMutableDictionary * pendingFiles = [NSMutableDictionary new];
  
  NSArray * args =
    @[
      @"status",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/brctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    NSString * currentDirectory = nil;
    NSString * currentFile = nil;
    NSString * action = nil;
    NSString * progress = nil;
    
    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
      if([trimmedLine hasPrefix: @"Under "])
        currentDirectory = [trimmedLine substringFromIndex: 6];
        
      else if([trimmedLine hasPrefix: @"r:"])
        {
        if(currentDirectory.length > 0)
          {
          currentFile = [self readFileName: trimmedLine];
          ++count;

          NSMutableDictionary * directory = 
            [pendingFiles objectForKey: currentDirectory];
          
          if(directory == nil)
            {
            directory = [NSMutableDictionary new];
            [pendingFiles setObject: directory forKey: currentDirectory];
            [directory release];
            }          
            
          NSMutableDictionary * file = [NSMutableDictionary new];
          
          [file setObject: currentFile forKey: @"name"];
          
          [directory setObject: file forKey: currentFile];
          
          [file release];
          }
        }
        
      else if([trimmedLine hasPrefix: @"> upload{"])
        action = @"uploading";

      else if([trimmedLine hasPrefix: @"> downloader{"])
        action = @"downloading";
      
      if(action.length > 0)
        if((currentDirectory.length > 0) && (currentFile.length > 0))
          {
          progress = [self readProgress: action line: trimmedLine];
          
          NSMutableDictionary * directory = 
            [pendingFiles objectForKey: currentDirectory];
            
          NSMutableDictionary * file = 
            [directory objectForKey: currentFile];
            
          NSString * name = [file objectForKey: @"name"];
          
          if(name.length > 0)
            {
            [file setObject: action forKey: @"action"];
            [file setObject: progress forKey: @"percentage"];
            }
            
          currentDirectory = nil;
          currentFile = nil;
          action = nil;
          }
      }
      
    if(count > 0)
      pendingFileCount = ECLocalizedPluralString(count, @"pending file");
    }
    
  [subProcess release];

  long long bytes = 0;
    
  NSString * iCloudFree = nil;
  
  if(version >= kSierra)
    {
    args =
      @[
        @"quota",
      ];
    
    subProcess = [[SubProcess alloc] init];
    
    if([subProcess execute: @"/usr/bin/brctl" arguments: args])
      {
      NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
      
      for(NSString * line in lines)
        {
        NSScanner * scanner = [NSScanner scannerWithString: line];
        
        if([scanner scanLongLong: & bytes])
          {
          ByteCountFormatter * formatter = [ByteCountFormatter new];
          
          // Apple uses 1024 for this one.
          formatter.k1000 = 1024.0;
          
          iCloudFree = [formatter stringFromByteCount: bytes];
            
          [formatter release];
          }
        }
      }
      
    [subProcess release];
    }
    
  if([iCloudFree length] > 0)
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            ECLocalizedString(@"    iCloud Quota: %@ available"),
            iCloudFree]];
      
    [self.model addElement: @"icloudfree" valueWithUnits: iCloudFree];
    
    if(bytes < 1024 * 1024 * 256)
      [self.result
        appendString: ECLocalizedString(@" (Low!)")
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
    [self.result appendString: @"\n"];
    }
    
  if(self.simulating)
    {
    count = 34;
    pendingFileCount = @"34 simulated pending files";
    }
    
  if(pendingFileCount.length > 0)
    {
    [self.result
      appendString: ECLocalizedString(@"    iCloud Status: ")];
      
    if(count >= 10)
      [self.result
        appendString: pendingFileCount
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result appendString: pendingFileCount];
      
    [self.result appendString: @"\n"];
    }
    
  if(pendingFiles.count > 0)
    {
    [self.model startElement: @"icloudpendingfiles"];
    
    for(NSString * directoryName in pendingFiles)
      {
      NSDictionary * directory = [pendingFiles objectForKey: directoryName];
      
      if(directory.count > 0)
        {
        [self.model startElement: @"directory"];
        
        [self.model addElement: @"name" value: directoryName];
        
        for(NSString * fileName in directory)
          {
          NSDictionary * file = [directory objectForKey: fileName];
          
          NSString * action = [file objectForKey: @"action"];
          NSString * percentage = [file objectForKey: @"percentage"];

          [self.model startElement: @"file"];

          [self.model addElement: @"name" value: fileName];
          [self.model addElement: @"action" value: action];
          [self.model addElement: @"percentage" value: percentage];
          
          [self.model endElement: @"file"];
          }
          
        [self.model endElement: @"directory"];
        }
      }
      
    [self.model endElement: @"icloudpendingfiles"];
    }
    
  [pendingFiles release];
  }

// Read a file name from an iCloud status line.
- (NSString *) readFileName: (NSString *) line
  {
  NSRange range = [line rangeOfString: @" sz:"];
  
  if(range.location != NSNotFound)
    {
    NSString * data = [line substringFromIndex: range.location + 8];
    
    NSRange nRange = [data rangeOfString: @" n:\""];
    NSRange sigRange = [data rangeOfString: @" sig:"];
    
    if((nRange.location != NSNotFound) && (sigRange.location != NSNotFound))
      if((sigRange.location - 2) > (nRange.location + 4))
        {
        NSRange nameRange = 
            NSMakeRange(
              nRange.location + 4, 
              sigRange.location - 1 - nRange.location - 4);
              
        return [data substringWithRange: nameRange];
        }
    }
      
  return nil;
  }
  
// Read a progress from an iCloud status line.
- (NSString *) readProgress: (NSString *) action line: (NSString *) line
  {
  NSString * percentage = nil;
    
  NSString * match = [[NSString alloc] initWithFormat: @" %@:", action];
  
  NSRange range = [line rangeOfString: match];
  
  if(range.location != NSNotFound)
    {
    NSScanner * scanner = 
      [[NSScanner alloc] 
        initWithString: 
          [line substringFromIndex: range.location + match.length]];
    
    [scanner scanUpToString: @"%" intoString: & percentage];
      
    [scanner release];
    }
    
  [match release];
  
  return percentage;
  }
  
@end
