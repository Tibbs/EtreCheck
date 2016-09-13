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
#import "XMLBuilder.h"

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
@synthesize supportsHandoff = mySupportsHandoff;
@synthesize supportsInstantHotspot = mySupportsInstantHotspot;
@synthesize supportsLowEnergy = mySupportsLowEnergy;

// Constructor.
- (id) init
  {
  self = [super initWithName: @"hardware"];
  
  if(self)
    {
    // Do this in the constructor so the data is available before
    // collection starts.
    [self loadProperties];
    
    return self;
    }
    
  return nil;
  }

// Destructor.
- (void) dealloc
  {
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

  [[Model model] setComputerName: computerName];
  [[Model model] setHostName: hostName];
  
  [self.XML addElement: kComputerName value: computerName];
  [self.XML addElement: kHostName value: hostName];
  
  [computerName release];
  [hostName release];
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Checking hardware information", NULL)];

  [self collectBluetooth];
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
              
              NSString * supportsHandoff =
                [localInfo objectForKey: @"general_supports_handoff"];
              NSString * supportsInstantHotspot =
                [localInfo
                  objectForKey: @"general_supports_instantHotspot"];
              NSString * supportsLowEnergy =
                [localInfo objectForKey: @"general_supports_lowEnergy"];
                
              if([supportsHandoff isEqualToString: @"attrib_Yes"])
                self.supportsHandoff = YES;
                
              if([supportsInstantHotspot isEqualToString: @"attrib_Yes"])
                self.supportsInstantHotspot = YES;

              if([supportsLowEnergy isEqualToString: @"attrib_Yes"])
                self.supportsLowEnergy = YES;
               }
            }
      }
    }
    
  [self.XML addElement: kSupportsHandoff boolValue: self.supportsHandoff];
  [self.XML
    addElement: kSupportsInstantHotspot
    boolValue: self.supportsInstantHotspot];
  [self.XML
    addElement: kSupportsLowEnergy boolValue: self.supportsLowEnergy];
  
  [subProcess release];
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
  int physicalRAM = [self parseMemory: memory];

  [[Model model] setModel: model];
  [self.XML addElement: kModel value: model];
  
  // Extract the memory.
  [[Model model]
    setPhysicalRAM: physicalRAM];
  [self.XML addElement: kPhysicalRAM intValue: physicalRAM];

  NSString * serialCode = [serial substringFromIndex: 8];
  
  [[Model model] setSerialCode: serialCode];
  [[Model model] setCoreCount: [core_count intValue]];

  [self.XML addElement: kSerialCode value: serialCode];
  [self.XML addElement: kCPUCount number: cpu_count];
  [self.XML addElement: kCPUSpeed value: speed];
  [self.XML addElement: kCoreCount number: core_count];
  [self.XML addElement: kCPUType value: cpu_type];

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
            @"    %@ %@ %@ CPU: %@-core\n", NULL),
          cpu_count,
          speed,
          cpu_type ? cpu_type : @"",
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
    {
    if(![self.marketingName length])
      self.marketingName = [machineProperties objectForKey: kMachineName];

    [self.XML addElement: kMarketingName value: self.marketingName];

    [[Model model]
      setMachineIcon: [machineProperties objectForKey: kMachineIcon]];
    }

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
  if([[[Model model] model] hasPrefix: @"MacBook"])
    return NSLocalizedString(@"service_notebook", NULL);
  
    return NSLocalizedString(@"service_desktop", NULL);
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
  NSString * upgradeURL = nil;
  NSString * language = NSLocalizedString(@"en", NULL);
  
  if(details)
    {
    NSString * isUpgradeable =
      [details objectForKey: @"is_memory_upgradeable"];
    
    upgradeable = [isUpgradeable boolValue];
    
    [self.XML startElement: kMemoryUpgradeable];
    
    // Snow Leopoard doesn't seem to report this.
    if(isUpgradeable)
      upgradeableString =
        upgradeable
          ? NSLocalizedString(@"Upgradeable", NULL)
          : NSLocalizedString(@"Not upgradeable", NULL);
      
    if(upgradeable)
      {
      upgradeURL = [self memoryUpgradeURL: language];
      
      [self.XML addAttribute: kMemoryUpgradeURL value: upgradeURL];
      }
      
    [self.XML addString: upgradeableString];
    
    [self.XML endElement: kMemoryUpgradeable];
    }
    
  [self.XML addElement: kMemoryAmount value: memory];
  
  if([[Model model] physicalRAM] < 4)
    {
    [self.XML addAttribute: kSeverity value: kCritical];
    [self.XML
      addElement: kExplanation
      value: NSLocalizedString(@"insufficientram", NULL)];
    
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

  if(upgradeable)
    {
    [self.result appendString: @" - "];

    [self.result
      appendAttributedString:
        [Utilities
          buildURL: upgradeURL
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
  NSString * lastBankID = nil;
  int bankCount = 0;
  
  [self.XML startElement: kMemoryBanks];
  
  for(NSDictionary * bank in banks)
    {
    [self.XML startElement: kMemoryBank];
    
    NSString * name = [bank objectForKey: @"_name"];
    NSString * size = [bank objectForKey: @"dimm_size"];
    NSString * type = [bank objectForKey: @"dimm_type"];
    NSString * speed = [bank objectForKey: @"dimm_speed"];
    NSString * status = [bank objectForKey: @"dimm_status"];
    
    [self.XML addElement: name value: kMemoryBankName];
    [self.XML addElement: size value: kMemoryBankSize];
    [self.XML addElement: type value: kMemoryBankType];
    [self.XML addElement: speed value: kMemoryBankSpeed];
    [self.XML addElement: status value: kMemoryBankStatus];
    
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
      
    bool isRAMSlotID = [lastBankID hasPrefix: @"        RAM slot"];
    bool isEmpty = [size isEqualToString: empty];
    
    if(isRAMSlotID && isEmpty && (bank != [banks lastObject]))
      ++bankCount;
    else
      {
      [self.result appendString: currentBankID];
      [self.result
        appendString:
          [NSString
            stringWithFormat:
              @"%@\n",
              bankCount > 0
                ? [NSString stringWithFormat: @" (%d)", bankCount]
                : @""]];
      [self.result appendString: currentBankInfo];
      
      lastBankID = currentBankID;
      }
    }
    
  [self.XML endElement: kMemoryBanks];
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
        [self.XML startElement: kWirelessInterfaces];
        
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
          
        [self.XML endElement: kWirelessInterfaces];
        }
      }
    }
    
  [subProcess release];
  }

// Print a single wireless interface.
- (void) printWirelessInterface: (NSDictionary *) interface
  indent: (NSString *) indent
  {
  [self.XML startElement: kWirelessInterface];
          
  NSString * name = [interface objectForKey: @"_name"];
  NSString * modes =
    [interface objectForKey: @"spairport_supported_phymodes"];

  [self.XML addElement: kWirelessInterfaceName value: name];
  
  if([modes length])
    {
    [self.XML addElement: kWirelessInterfaceModes value: modes];
    [self.result
      appendString:
        [NSString stringWithFormat: @"%@%@: %@\n", indent, name, modes]];
    }
  else
    [self.result appendString: NSLocalizedString(@"Unknown", NULL)];

  [self.XML endElement: kWirelessInterface];
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
  
  [self.XML startElement: kBatteryInformation];
  
  for(NSDictionary * info in infos)
    {
    [self.XML startElement: kBattery];
    
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

    NSDictionary * healthInfo =
      [info objectForKey: @"sppower_battery_health_info"];
      
    BOOL needsReplacing = NO;
    
    if(healthInfo)
      {
      cycleCount =
        [healthInfo objectForKey: @"sppower_battery_cycle_count"];
      health = [healthInfo objectForKey: @"sppower_battery_health"];
      
      if([health isEqualToString: @"Poor"])
        needsReplacing = YES;

      [self.XML addElement: kBatteryCycleCount number: cycleCount];
      [self.XML addElement: kBatteryHealth value: health];
      }
      
    if(serialNumberInvalid || needsReplacing)
      {
      [self.XML addAttribute: kSeverity value: kWarning];
      
      if(needsReplacing)
        [self.XML addAttribute: kExplanation value: @"needs replacing"];
      else
        [self.XML
          addAttribute: kExplanation value: @"invalid serial number"];
      }
      
    [self.XML endElement: kBattery];
    }
    
  if(cycleCount && [health length])
    {
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
    
  [self.XML endElement: kBatteryInformation];
  }

@end
