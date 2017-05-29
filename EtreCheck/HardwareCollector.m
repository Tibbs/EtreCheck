/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "HardwareCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Model.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "NSArray+Etresoft.h"
#import "NSDictionary+Etresoft.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "SubProcess.h"

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
  self = [super init];
  
  if(self)
    {
    self.name = @"hardware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
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
      readPropertyList: NSLocalizedString(@"machineattributes", NULL)];
    
  // Don't give up yet. Try the old one too.
  if(!self.properties)
    self.properties =
      [NSDictionary
        readPropertyList:
          NSLocalizedString(@"oldmachineattributes", NULL)];
    
  // This is as good a place as any to collect this.
  NSString * computerName =
    (NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);

  NSString * hostName = (NSString *)SCDynamicStoreCopyLocalHostName(NULL);

  // Load the machine image.
  self.machineIcon = [self findCurrentMachineIcon];

  [[Model model] setComputerName: computerName];
  [[Model model] setHostName: hostName];
  
  if(self.machineIcon != nil)
    [[Model model] setMachineIcon: self.machineIcon];
  
  [computerName release];
  [hostName release];
  }

// Perform the collection.
- (void) collect
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking hardware information", NULL)];

  [self collectBluetooth];
  [self collectSysctl];
  [self collectHardware];
    
  dispatch_semaphore_signal(self.complete);
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
    self.CPUCode = [NSString stringWithFormat: @" (%@)", code];
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
        
        [self.result appendCR];
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

  [[Model model] setSerialCode: [serial substringFromIndex: 8]];

  // Print the human readable machine name, if I can find one.
  [self printHumanReadableMacName: model];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@ - %@: %@\n", NULL),
          name, NSLocalizedString(@"model", NULL), model]];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"    %@ %@ %@%@ CPU: %@-core\n", NULL),
          cpu_count,
          speed,
          cpu_type ? cpu_type : @"",
          self.CPUCode ? self.CPUCode : @"",
          core_count]];
    
  [self printMemory: memory];
  }

// Parse a memory string into an int (in GB).
- (int) parseMemory: (NSString *) memory
  {
  NSScanner * scanner = [NSScanner scannerWithString: memory];

  int physicalMemory;
  
  if(![scanner scanInt: & physicalMemory])
    physicalMemory = 0;

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
      
  NSString * language = NSLocalizedString(@"en", NULL);

  [self.result appendString: @"    "];
  
  [self.result
    appendAttributedString:
      [Utilities
        buildURL:
          [self technicalSpecificationsURL: language]
        title:
          NSLocalizedString(
            @"[Technical Specifications]", NULL)]];

  [self.result appendString: @" - "];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL:
          [self userGuideURL: language]
        title:
          NSLocalizedString(
            @"[User Guide]", NULL)]];
    
  [self.result appendString: @" - "];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL: [self serviceURL]
        title:
          NSLocalizedString(
            @"[Warranty & Service]", NULL)]];

  [self.result appendString: @"\n"];
  }

// Try to get the marketing name directly from Apple.
- (void) askAppleForMarketingName
  {
  NSString * language = NSLocalizedString(@"en", NULL);
  
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

// Find a machine icon.
- (NSImage *) findMachineIcon: (NSString *) code
  {
  NSDictionary * machineInformation = [self.properties objectForKey: code];
      
  // Load the machine image.
  NSString * iconPath =
    [machineInformation objectForKey: @"hardwareImageName"];
  
  // Don't give up.
  if(!iconPath)
    {
    iconPath = NSLocalizedStringFromTable(code, @"machineIcons", NULL);
    
    if(iconPath)
      {
      if(![[NSFileManager defaultManager] fileExistsAtPath: iconPath])
        iconPath = nil;
      }
    }
    
  if(!iconPath)
    return nil;

  return [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
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
    
    // Snow Leopoard doesn't seem to report this.
    if(isUpgradeable)
      upgradeableString =
        upgradeable
          ? NSLocalizedString(@"Upgradeable", NULL)
          : NSLocalizedString(@"Not upgradeable", NULL);
    }
    
  if([[Model model] physicalRAM] < 4)
    {
    [self.result
      appendString:
        [NSString
          stringWithFormat:
            @"    %@ RAM - %@ %@",
            memory,
            NSLocalizedString(@"insufficientram", NULL),
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

  NSString * language = NSLocalizedString(@"en", NULL);

  if(upgradeable)
    {
    [self.result appendString: @" - "];

    [self.result
      appendAttributedString:
        [Utilities
          buildURL: [self memoryUpgradeURL: language]
          title:
            NSLocalizedString(
              @"[Instructions]\n", NULL)]];
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
  for(NSDictionary * bank in banks)
    {
    NSString * name = [bank objectForKey: @"_name"];
    NSString * size = [bank objectForKey: @"dimm_size"];
    NSString * type = [bank objectForKey: @"dimm_type"];
    NSString * speed = [bank objectForKey: @"dimm_speed"];
    NSString * status = [bank objectForKey: @"dimm_status"];
    
    NSString * currentBankID =
      [NSString stringWithFormat: @"        %@", name];
      
    if([size isEqualToString: @"(empty)"])
      size = @"empty";
      
    NSString * empty = NSLocalizedString(@"Empty", NULL);
    
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
      
    [self.result appendString: currentBankID];
    [self.result appendString: @"\n"];
    [self.result appendString: currentBankInfo];
    }
  }

// Print information about bluetooth.
- (void) printBluetoothInformation
  {
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          @"    Bluetooth: %@\n", [self collectBluetoothInformation]]];
  }

// Collect bluetooth information.
- (NSString *) collectBluetoothInformation
  {
  if([self supportsContinuity])
    return NSLocalizedString(@"Good - Handoff/Airdrop2 supported", NULL);
              
  return NSLocalizedString(@"Old - Handoff/Airdrop2 not supported", NULL);
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
                    @"    Wireless: %@",
                    TTTLocalizedPluralString(count, @"interface", nil)]];
          
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

  if([modes length])
    [self.result
      appendString:
        [NSString stringWithFormat: @"%@%@: %@\n", indent, name, modes]];
  else
    [self.result appendString: NSLocalizedString(@"Unknown", NULL)];
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
    
  if(cycleCount && [health length])
    {
    if([health isEqualToString: @"Poor"])
      [self.result
        appendString:
          [NSString
            stringWithFormat:
            NSLocalizedString(
              @"    Battery: Health = %@ - Cycle count = %@\n",
              NULL),
            NSLocalizedString(health, NULL), cycleCount]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    else
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(
                @"    Battery: Health = %@ - Cycle count = %@\n",
                NULL),
              NSLocalizedString(health, NULL), cycleCount]];
      
    if(serialNumberInvalid)
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              NSLocalizedString(
                @"        Battery serial number %@ invalid\n", NULL),
                serialNumber]
        attributes:
          [NSDictionary
            dictionaryWithObjectsAndKeys:
              [NSColor redColor], NSForegroundColorAttributeName, nil]];
    }
  }

@end
