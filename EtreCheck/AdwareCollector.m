/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014-2017. All rights reserved.
 **********************************************************************/

#import "AdwareCollector.h"
#import "Model.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "Utilities.h"
#import "TTTLocalizedPluralString.h"
#import "LaunchdCollector.h"

#define kWhitelistKey @"whitelist"
#define kWhitelistPrefixKey @"whitelist_prefix"
#define kAdwareExtensionsKey @"adwareextensions"
#define kBlacklistKey @"blacklist"
#define kBlacklistSuffixKey @"blacklist_suffix"
#define kBlacklistMatchKey @"blacklist_match"

// Collect information about adware.
@implementation AdwareCollector

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    self.name = @"adware";
    self.title = NSLocalizedStringFromTable(self.name, @"Collectors", NULL);
    
    [self loadSignatures];
    }
    
  return self;
  }

// Perform the collection.
- (void) collect
  {
  [self updateStatus: NSLocalizedString(@"Checking for adware", NULL)];

  [self printAdware];
  
  dispatch_semaphore_signal(self.complete);
  }

// Load signatures from an obfuscated list of signatures.
- (void) loadSignatures
  {
  NSString * signaturePath =
    [[NSBundle mainBundle] pathForResource: @"adware" ofType: @"plist"];
    
  NSData * partialData = [NSData dataWithContentsOfFile: signaturePath];
  
  if(partialData)
    {
    NSMutableData * plistGzipData = [NSMutableData data];
    
    char buf[] = { 0x1F, 0x8B, 0x08 };
    
    [plistGzipData appendBytes: buf length: 3];
    [plistGzipData appendData: partialData];
    
    NSString * tempDir = [Utilities createTemporaryDirectory];
    
    NSString * tempFile =
      [tempDir stringByAppendingPathComponent: @"out.bin"];
    
    [plistGzipData writeToFile: tempFile atomically: YES];
    
    NSData * plistData = [Utilities ungzip: plistGzipData];
    
    [[NSFileManager defaultManager] removeItemAtPath: tempDir error: NULL];
    
    NSDictionary * plist = [Utilities readPropertyListData: plistData];
  
    if(plist)
      {
      [self
        addSignatures: [plist objectForKey: kWhitelistKey]
          forKey: kWhitelistKey];
      
      [self
        addSignatures: [plist objectForKey: kWhitelistPrefixKey]
          forKey: kWhitelistPrefixKey];

      [self
        addSignatures: [plist objectForKey: kAdwareExtensionsKey]
          forKey: kAdwareExtensionsKey];
      
      [self
        addSignatures: [plist objectForKey: @"blacklist"]
        forKey: kBlacklistKey];

      [self
        addSignatures: [plist objectForKey: @"blacklist_suffix"]
        forKey: kBlacklistSuffixKey];

      [self
        addSignatures: [plist objectForKey: @"blacklist_match"]
        forKey: kBlacklistMatchKey];
      }
    }
  }

// Add signatures that match a given key.
- (void) addSignatures: (NSArray *) signatures forKey: (NSString *) key
  {
  if(signatures)
    {
    if([key isEqualToString: kWhitelistKey])
      [[Model model] appendToWhitelist: signatures];

    else if([key isEqualToString: kWhitelistPrefixKey])
      [[Model model] appendToWhitelistPrefixes: signatures];

    if([key isEqualToString: kAdwareExtensionsKey])
      [[Model model] setAdwareExtensions: signatures];
      
    else if([key isEqualToString: kBlacklistKey])
      [[Model model] appendToBlacklist: signatures];
      
    else if([key isEqualToString: kBlacklistSuffixKey])
      [[Model model] appendToBlacklistSuffixes: signatures];

    else if([key isEqualToString: kBlacklistMatchKey])
      [[Model model] appendToBlacklistMatches: signatures];
    }
  }

// Expand adware signatures.
- (NSArray *) expandSignatures: (NSArray *) signatures
  {
  NSMutableArray * expandedSignatures = [NSMutableArray array];
  
  for(NSString * signature in signatures)
    [expandedSignatures
      addObject: [signature stringByExpandingTildeInPath]];
    
  return expandedSignatures;
  }

// Identify adware files.
- (NSArray *) identifyAdwareFiles: (NSArray *) files
  {
  NSMutableArray * adwareFiles = [NSMutableArray array];
  
  for(NSString * file in files)
    {
    NSString * fullPath = [file stringByExpandingTildeInPath];
    
    bool exists =
      [[NSFileManager defaultManager] fileExistsAtPath: fullPath];
      
    if(exists)
      [adwareFiles addObject: fullPath];
    }
    
  return adwareFiles;
  }

// Print any adware found.
- (void) printAdware
  {
  if([[Model model] possibleAdwareFound])
    {
    NSMutableArray * possibleAdwareFiles = [NSMutableArray array];
    
    // Add the known adware.
    for(NSString * adwareFile in [[Model model] adwareFiles])
      {
      NSDictionary * possibleAdware =
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            adwareFile, @"key",
            @"adwarefile", @"type",
            @"", @"executable",
            nil];
        
      [possibleAdwareFiles addObject: possibleAdware];
      }
      
    // Add the possible adware.
    for(NSString * unknownFile in [[Model model] unknownLaunchdFiles])
      {
      NSDictionary * info =
        [[[Model model] unknownLaunchdFiles] objectForKey: unknownFile];
      
      NSString * signature = [info objectForKey: kSignature];
      
      // This will go into clean up instead.
      if([signature isEqualToString: kExecutableMissing])
        continue;
        
      NSString * executable =
        [Utilities formatExecutable: [info objectForKey: kCommand]];
      
      if(!executable)
        executable = @"";
        
      NSDictionary * possibleAdware =
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            unknownFile, @"key",
            @"unknownfile", @"type",
            executable, @"executable",
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
          NSString * type = [obj objectForKey: @"type"];
          NSString * executable = [obj objectForKey: @"executable"];
          
          NSString * extra =
            ([executable length] > 0)
              ? [NSString stringWithFormat: @"\n    \t%@", executable]
              : @"";
            
          ++adwareCount;
          [self.result appendString: @"    "];
          [self.result
            appendString: NSLocalizedString(type, NULL)
            attributes:
              @{
                NSFontAttributeName : [[Utilities shared] boldFont],
                NSForegroundColorAttributeName : [[Utilities shared] red],
              }];
          [self.result
            appendString: [Utilities prettyPath: name]
            attributes:
              @{
                NSFontAttributeName : [[Utilities shared] boldFont],
                NSForegroundColorAttributeName : [[Utilities shared] red],
              }];
            
          if([extra length])
            [self.result
              appendString: extra
              attributes:
                @{
                  NSFontAttributeName : [[Utilities shared] boldFont],
                  NSForegroundColorAttributeName : [[Utilities shared] red],
                }];
            
          [self.result appendString: @"\n"];
          }];
      
    NSString * message =
      TTTLocalizedPluralString(adwareCount, @"adware file", NULL);

    [self.result appendString: @"    "];
    [self.result
      appendString: message
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont],
          NSForegroundColorAttributeName : [[Utilities shared] red],
        }];
    
    NSAttributedString * removeLink = [self generateRemoveAdwareLink];

    if(removeLink)
      {
      [self.result appendAttributedString: removeLink];
      [self.result appendString: @"\n"];
      }
    
    [self.result appendCR];
    }
  }

@end
