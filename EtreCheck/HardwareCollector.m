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
#import "ByteCountFormatter.h"
#import "CollectorModel.h"
#import "NumberFormatter.h"

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
  [[Model model] setComputerName: computerName];
  [[Model model] setHostName: hostName];
  
  [self.model setString: computerName forKey: @"computername"];
  [self.model setString: hostName forKey: @"hostname"];
  
  if(self.machineIcon != nil)
    [[Model model] setMachineIcon: self.machineIcon];
  
  [self.model setObject: self.machineIcon forKey: @"machineicon"];
  
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
  [self collectNetwork];
  [self collectiCloud];
    
  [self.result appendCR];
  
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
                
              [self.model
                setBoolean: self.supportsHandoff
                forKey: @"supportshandoff"];

              [self.model
                setBoolean: self.supportsInstantHotspot
                forKey: @"supportinstanthotspot"];

              [self.model
                setBoolean: self.supportsLowEnergy
                forKey: @"supportlowenergy"];
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
    {
    self.CPUCode = [NSString stringWithFormat: @" (%@)", code];
    
    [self.model setString: self.CPUCode forKey: @"cpucode"];
    }
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

  [[Model model] setSerialCode: [serial substringFromIndex: 8]];

  // Print the human readable machine name, if I can find one.
  [self printHumanReadableMacName: model];
    
  [self.result
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"    %@ - %@: %@\n", NULL),
          name, NSLocalizedString(@"model", NULL), model]];
    
  [self.model setString: name forKey: @"name"];
  [self.model setString: model forKey: @"model"];
    
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
    
  [self.model setNumber: cpu_count forKey: @"cpucount"];
  [self.model setString: speed forKey: @"speed"];
  [self.model setString: cpu_type forKey: @"cpu_type"];
  [self.model setNumber: core_count forKey: @"corecount"];

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
      
  [self.model setString: self.marketingName forKey: @"marketingname"];
    
  NSString * language = NSLocalizedString(@"en", NULL);

  [self.result appendString: @"    "];
  
  NSString * url = [self technicalSpecificationsURL: language];
  
  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          NSLocalizedString(
            @"[Technical Specifications]", NULL)]];

  [self.model
    setURL: [NSURL URLWithString: url]
    forKey: @"technicalspecificationsurl"];

  [self.result appendString: @" - "];

  url = [self userGuideURL: language];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          NSLocalizedString(
            @"[User Guide]", NULL)]];
    
  [self.model setURL: [NSURL URLWithString: url] forKey: @"userguideurl"];

  [self.result appendString: @" - "];

  url = [self serviceURL];

  [self.result
    appendAttributedString:
      [Utilities
        buildURL: url
        title:
          NSLocalizedString(
            @"[Warranty & Service]", NULL)]];

  [self.model
    setURL: [NSURL URLWithString: url] forKey: @"warrantyandserviceurl"];

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

  [self.model
    setLongLong: [memory longLongValue] * 1024 * 1024 * 1024
    forKey: @"ram"];
  
  NSString * language = NSLocalizedString(@"en", NULL);

  NSString * url = [self memoryUpgradeURL: language];
  
  [self.model setBoolean: upgradeable forKey: @"upgradeable"];
  
  if(upgradeable)
    {
    [self.result appendString: @" - "];

    [self.result
      appendAttributedString:
        [Utilities
          buildURL: url
          title:
            NSLocalizedString(
              @"[Instructions]\n", NULL)]];
      
    [self.model
      setURL: [NSURL URLWithString: url]
      forKey: @"memoryupgradeinstructionsurl"];
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
    
    NSString * key =
      [@"memorybanks" stringByAppendingPathComponent: currentBankID];
    
    [self.model
      setString: size
      forKey: [key stringByAppendingPathComponent: @"size"]];

    [self.model
      setString: type
      forKey: [key stringByAppendingPathComponent: @"type"]];

    [self.model
      setString: speed
      forKey: [key stringByAppendingPathComponent: @"speed"]];

    [self.model
      setString: status
      forKey: [key stringByAppendingPathComponent: @"status"]];
    }
  }

// Print information about bluetooth.
- (void) printBluetoothInformation
  {
  NSString * info = [self collectBluetoothInformation];
  
  [self.result
    appendString:
      [NSString 
        stringWithFormat: 
          NSLocalizedString(@"    Bluetooth: %@\n", NULL), info]];
  
  [self.model setString: info forKey: @"bluetooth"];
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
                    NSLocalizedString(@"    Wireless: %@", NULL),
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

  if(([name length] > 0) && ([modes length] > 0))
    {
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            NSLocalizedString(@"%@%@: %@\n", NULL), indent, name, modes]];
    
    [self.model
      setString: modes
      forKey: [NSString stringWithFormat: @"wireless/%@", name]];
    }
    
  else if([name length] > 0)
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            NSLocalizedString(@"%@%@: %@\n", NULL), 
            indent, 
            name, 
            NSLocalizedString(@"Unknown", NULL)]];
            
  else
    [self.result
      appendString:
        [NSString 
          stringWithFormat: 
            @"%@%@\n", indent, NSLocalizedString(@"Unknown", NULL)]];
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
      
    [self.model setString: health forKey: @"batteryhealth"];
    [self.model setNumber: cycleCount forKey: @"batterycyclecount"];
    [self.model setString: serialNumber forKey: @"batteryserialnumber"];
    
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

// Collect network information.
- (void) collectNetwork
  {
  NSArray * args =
    @[
      @"--proxy",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
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
                  NSLocalizedString(@"    Proxy: %@\n", NULL), proxy]];
          
          [self.model
            setBoolean: YES
            forKey: [NSString stringWithFormat: @"proxies/%@", proxy]];
          }
        }
      }
    }
    
  [subProcess release];
  }

// Collect iCloud information.
- (void) collectiCloud
  {
  int version = [[Model model] majorOSVersion];

  if(version < kElCapitan)
    return;
    
  int count = 0;
    
  NSString * pendingFiles = nil;
  
  NSArray * args =
    @[
      @"status",
    ];
  
  SubProcess * subProcess = [[SubProcess alloc] init];
  
  if([subProcess execute: @"/usr/bin/brctl" arguments: args])
    {
    NSArray * lines = [Utilities formatLines: subProcess.standardOutput];
    
    for(NSString * line in lines)
      {
      NSString * trimmedLine =
        [line
          stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
      if([trimmedLine hasPrefix: @"r:"])
        {
        NSRange range = [trimmedLine rangeOfString: @" doc bt:"];
        
        if(range.location != NSNotFound)
          ++count;
        }
      }
      
    if(count > 0)
      pendingFiles = TTTLocalizedPluralString(count, @"pending file", nil);
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
            NSLocalizedString(@"    iCloud Quota: %@ available", NULL),
            iCloudFree]];
      
    [self.model setLongLong: bytes forKey: @"icloudquota"];
    
    if(bytes < 1024 * 1024 * 256)
      [self.result
        appendString: NSLocalizedString(@" (Low!)", NULL)
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
    [self.result appendString: @"\n"];
    }
    
  if([pendingFiles length] > 0)
    {
    [self.result
      appendString: NSLocalizedString(@"    iCloud Status: ", NULL)];
      
    [self.model setInteger: count forKey: @"icloudpendingfiles"];
    
    if(count >= 10)
      [self.result
        appendString: pendingFiles
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
    else
      [self.result appendString: pendingFiles];
      
    [self.result appendString: @"\n"];
    }
  }

@end
