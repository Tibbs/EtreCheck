/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import "AppDelegate.h"
#import "LibEtreCheck/LibEtreCheck.h"
#import <ServiceManagement/ServiceManagement.h>
#import <unistd.h>
#import <CarbonCore/BackupCore.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "SlideshowView.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>
#import "DetailManager.h"
#import "SMARTManager.h"
#import "HelpManager.h"
#import "EtreCheckToolbarItem.h"
#import "CleanupManager.h"
#import "NotificationSPAMCleanupManager.h"
#import "AdwareManager.h"
#import "UpdateManager.h"
#import "CURLRequest.h"
#import "EtreCheckWindow.h"

// Toolbar items.
#define kShareToolbarItemID @"sharetoolbaritem"
#define kHelpToolbarItemID @"helptoolbaritem"
#define kTextSizeToolbarItemID @"textsizetoolbaritem"
#define kDonateTollbarItemID @"donatetoolbaritem"

#define kTextSizeNormal 0
#define kTextSizeLarger 1
#define kTextSizeVeryLarge 2

NSComparisonResult compareViews(id view1, id view2, void * context);

@interface AppDelegate ()

- (void) collectInfo;

@end

@implementation AppDelegate

@synthesize window;
@synthesize closeMenuItem = myCloseMenuItem;
@synthesize logWindow = myLogWindow;
@synthesize progress = myProgress;
@synthesize spinner = mySpinner;
@synthesize dockProgress = myDockProgress;
@synthesize cancelButton = myCancelButton;
@synthesize statusView = myStatusView;
@synthesize logView;
@synthesize displayStatus = myDisplayStatus;
@synthesize log;
@synthesize nextProgressIncrement = myNextProgressIncrement;
@synthesize progressTimer = myProgressTimer;
@synthesize machineIcon = myMachineIcon;
@synthesize applicationIcon = myApplicationIcon;
@synthesize magnifyingGlass = myMagnifyingGlass;
@synthesize magnifyingGlassShade = myMagnifyingGlassShade;
@synthesize finderIcon = myFinderIcon;
@synthesize demonImage = myDemonImage;
@synthesize agentImage = myAgentImage;
@synthesize collectionStatus = myCollectionStatus;
@synthesize reportView = myReportView;
@synthesize animationView = myAnimationView;
@synthesize startPanel = myStartPanel;
@synthesize startPanelAnimationView = myStartPanelAnimationView;
@synthesize introPanel = myIntroPanel;
@synthesize introPanelView = myIntroPanelView;
@synthesize problemIndex = myProblemIndex;
@synthesize chooseAProblemButton = myChooseAProblemButton;
@synthesize chooseAProblemPromptItem = myChooseAProblemPromptItem;
@synthesize beachballItem = myBeachballItem;
@dynamic problemSelected;
@synthesize problemDescription = myProblemDescription;
@synthesize problemDescriptionTextView = myProblemDescriptionTextView;
@synthesize optionsButton = myOptionsButton;
@synthesize optionsVisible = myOptionsVisible;
@synthesize userParametersPanel = myUserParametersPanel;
@synthesize userParametersPanelView = myUserParametersPanelView;
@synthesize clipboardCopyToolbarItemView = myClipboardCopyToolbarItemView;
@synthesize clipboardCopyButton = myClipboardCopyButton;
@synthesize shareToolbarItemView = myShareToolbarItemView;
@synthesize shareButton = myShareButton;
@synthesize helpToolbarItemView = myHelpToolbarItemView;
@synthesize helpButton = myHelpButton;
@synthesize helpButtonImage = myHelpButtonImage;
@synthesize helpButtonInactiveImage = myHelpButtonInactiveImage;
@synthesize textSizeToolbarItemView = myTextSizeToolbarItemView;
@synthesize textSizeButton = myTextSizeButton;
@synthesize textSize = myTextSize;
@synthesize donateToolbarItemView = myDonateToolbarItemView;
@synthesize donateButton = myDonateButton;
@synthesize donateButtonImage = myDonateButtonImage;
@synthesize donateButtonInactiveImage = myDonateButtonInactiveImage;
@synthesize toolbar = myToolbar;
@synthesize detailManager = myDetailManager;
@synthesize smartManager = mySMARTManager;
@synthesize helpManager = myHelpManager;
@synthesize cleanupManager = myCleanupManager;
@synthesize notificationSPAMCleanupManager =
  myNotificationSPAMCleanupManager;
@synthesize adwareManager = myAdwareManager;
@synthesize updateManager = myUpdateManager;
@synthesize reportAvailable = myReportAvailable;
@synthesize reportStartTime = myReportStartTime;
@synthesize TOUPanel = myTOUPanel;
@synthesize TOUView = myTOUView;
@synthesize acceptTOUButton = myAcceptTOUButton;
@synthesize TOSAccepted = myTOSAccepted;
@synthesize donatePanel = myDonatePanel;
@synthesize donateView = myDonateView;
@synthesize donationLookupPanel = myDonationLookupPanel;
@synthesize donationLookupEmail = myDonationLookupEmail;
@synthesize donationVerified = myDonationVerified;
@dynamic currentTextView;
@synthesize copyDisabled= myCopyDisabled;
@synthesize active = myActive;

@dynamic ignoreKnownAppleFailures;
@dynamic showSignatureFailures;
@dynamic hideAppleTasks;
@dynamic canSubmitDonationLookup;

+ (NSSet *) keyPathsForValuesAffectingProblemSelected
  {
  return [NSSet setWithObject: @"problemIndex"];
  }

+ (NSSet *) keyPathsForValuesAffectingCanSubmitDonationLookup
  {
  return [NSSet setWithObjects: @"donationLookupEmail", nil];
  }

- (bool) problemSelected
  {
  return self.problemIndex > 0;
  }

- (bool) ignoreKnownAppleFailures
  {
  return [[Model model] ignoreKnownAppleFailures];
  }

- (void) setIgnoreKnownAppleFailures: (bool) ignoreKnownAppleFailures
  {
  if(ignoreKnownAppleFailures != [[Model model] ignoreKnownAppleFailures])
    {
    [self willChangeValueForKey: @"ignoreKnownAppleFailures"];
    
    [[Model model] setIgnoreKnownAppleFailures: ignoreKnownAppleFailures];
    
    [self didChangeValueForKey: @"ignoreKnownAppleFailures"];
    }
  }

- (bool) showSignatureFailures
  {
  return [[Model model] showSignatureFailures];
  }

- (void) setShowSignatureFailures: (bool) showSignatureFailures
  {
  if(showSignatureFailures != [[Model model] showSignatureFailures])
    {
    [self willChangeValueForKey: @"showSignatureFailures"];
    
    [[Model model] setShowSignatureFailures: showSignatureFailures];
    
    [self didChangeValueForKey: @"showSignatureFailures"];
    }
  }

- (bool) hideAppleTasks
  {
  return [[Model model] hideAppleTasks];
  }

- (void) setHideAppleTasks: (bool) hideAppleTasks
  {
  if(hideAppleTasks != [[Model model] hideAppleTasks])
    {
    self.ignoreKnownAppleFailures = hideAppleTasks;
    
    [self willChangeValueForKey: @"hideAppleTasks"];
    
    [[Model model] setHideAppleTasks: hideAppleTasks];
  
    [self didChangeValueForKey: @"hideAppleTasks"];
    }
  }

- (NSUInteger) textSize
  {
  return myTextSize;
  }

- (void) setTextSize: (NSUInteger) textSize
  {
  if(textSize != myTextSize)
    {
    [self willChangeValueForKey: @"textSize"];
    
    [self changeTextSizeFrom: myTextSize to: textSize];
    
    myTextSize = textSize;
    
    [self didChangeValueForKey: @"textSize"];
    }
  }

- (BOOL) canSubmitDonationLookup
  {
  NSString * email =
    [self.donationLookupEmail
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
  return ([email length] > 0);
  }

- (NSTextView *) currentTextView
  {
  if(self.detailManager.visible)
    return self.detailManager.textView;
  else if(self.smartManager.visible)
    return self.smartManager.textView;
    
  return self.logView;
  }

// Destructor.
- (void) dealloc
  {
  self.dockProgress = nil;
  self.displayStatus = nil;
  self.closeMenuItem = nil;
  self.logWindow = nil;
  self.progress = nil;
  self.spinner = nil;
  self.dockProgress = nil;
  self.cancelButton = nil;
  self.statusView = nil;
  self.logView = nil;
  self.displayStatus = nil;
  self.log = nil;
  self.progressTimer = nil;
  self.machineIcon = nil;
  self.applicationIcon = nil;
  self.magnifyingGlass = nil;
  self.magnifyingGlassShade = nil;
  self.finderIcon = nil;
  self.demonImage = nil;
  self.agentImage = nil;
  self.collectionStatus = nil;
  self.reportView = nil;
  self.animationView = nil;
  self.startPanel = nil;
  self.startPanelAnimationView = nil;
  self.introPanel = nil;
  self.introPanelView = nil;
  self.chooseAProblemButton = nil;
  self.chooseAProblemPromptItem = nil;
  self.beachballItem = nil;
  self.problemDescription = nil;
  self.problemDescriptionTextView = nil;
  self.optionsButton = nil;
  self.userParametersPanel = nil;
  self.userParametersPanelView = nil;
  self.clipboardCopyToolbarItemView = nil;
  self.clipboardCopyButton = nil;
  self.shareToolbarItemView = nil;
  self.shareButton = nil;
  self.helpToolbarItemView = nil;
  self.helpButton = nil;
  self.helpButtonImage = nil;
  self.helpButtonInactiveImage = nil;
  self.textSizeToolbarItemView = nil;
  self.textSizeButton = nil;
  self.donateToolbarItemView = nil;
  self.donateButton = nil;
  self.donateButtonImage = nil;
  self.donateButtonInactiveImage = nil;
  self.toolbar = nil;
  self.detailManager = nil;
  self.smartManager = nil;
  self.helpManager = nil;
  self.notificationSPAMCleanupManager = nil;
  self.cleanupManager = nil;
  self.adwareManager = nil;
  self.updateManager = nil;
  self.reportStartTime = nil;
  self.TOUPanel = nil;
  self.TOUView = nil;
  self.acceptTOUButton = nil;
  self.donatePanel = nil;
  self.donateView = nil;
  self.donationLookupPanel = nil;
  self.donationLookupEmail = nil;
  self.window = nil;
  
  [super dealloc];
  }

// Start the application.
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
  {
  self.window.status = kSetup;
  
  [self checkForUpdates];
  
  [self setupStartMessage];

  [self.window.contentView addSubview: self.animationView];
  
  myDisplayStatus = [NSAttributedString new];
  self.log = [[NSMutableAttributedString new] autorelease];

  [self.logView
    setLinkTextAttributes:
      @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),
        NSCursorAttributeName : [NSCursor pointingHandCursor]
      }];
    
  [self.machineIcon updateSubviewsWithTransition: kCATransitionFade];
  [self.machineIcon
    transitionToImage: [[Utilities shared] unknownMachineIcon]];

  [self.applicationIcon updateSubviewsWithTransition: kCATransitionPush];
  [self.applicationIcon
    transitionToImage: [[Utilities shared] genericApplicationIcon]];
        
  [self.magnifyingGlass setHidden: NO];
    
  [self.finderIcon setImage: [[Utilities shared] FinderIcon]];
  [self.demonImage setHidden: NO];
  [self.agentImage setHidden: NO];
  
  //[self.logView setHidden: YES];
  
  [self.animationView
    sortSubviewsUsingFunction: compareViews context: self];
  
  // Set delegate for notification center.
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    setDelegate: self];

  // Handle my own "etrecheck:" URLs.
  NSAppleEventManager * appleEventManager =
    [NSAppleEventManager sharedAppleEventManager];
  
  [appleEventManager
    setEventHandler: self
    andSelector: @selector(handleGetURLEvent:withReplyEvent:)
    forEventClass:kInternetEventClass
    andEventID: kAEGetURL];
  
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [self collectUserParameters];
    });
    
  [self.shareButton sendActionOn: NSLeftMouseDownMask];

  BOOL coreImageFiltersAvailable =
    [NSProgressIndicator
      instancesRespondToSelector: @selector(setLayerUsesCoreImageFilters:)];
    
  if(coreImageFiltersAvailable)
    {
    self.progress.layerUsesCoreImageFilters = YES;
    self.spinner.layerUsesCoreImageFilters = YES;
    }
    
  self.helpButtonImage = [NSImage imageNamed: @"Help"];
  self.helpButtonInactiveImage = [NSImage imageNamed: @"HelpInactive"];

  self.donateButtonImage = [NSImage imageNamed: @"Donate"];
  self.donateButtonInactiveImage = [NSImage imageNamed: @"DonateInactive"];
  
  /* [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(windowDidResignKey:)
    name: NSWindowDidResignKeyNotification
    object: nil];
    
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(windowDidBecomeKey:)
    name: NSWindowDidBecomeKeyNotification
    object: nil]; */

  // Install the custom quit event handler
  [appleEventManager
    setEventHandler: self
    andSelector: @selector(handleQuitEvent:withReplyEvent:)
    forEventClass: kCoreEventClass
    andEventID: kAEQuitApplication];
    
  self.active = YES;
  }

// Handler for the quit apple event
- (void) handleQuitEvent: (NSAppleEventDescriptor *) event
  withReplyEvent: (NSAppleEventDescriptor *) replyEvent
  {
  [self cancel: self];
  }

// The application will terminate.
- (void) applicationWillTerminate: (NSNotification *) notification
  {
  [self autosave];
  self.introPanelView = nil;
  self.userParametersPanelView = nil;
  }

// Autosave the current report.
- (void) autosave
  {
  if(self.reportAvailable && [self.log length])
    {
    NSData * rtfData =
      [self.log
        dataFromRange: NSMakeRange(0, [self.log length])
        documentAttributes:
          @
            {
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
            }
        error: NULL];
      
    if(rtfData)
      {
      NSURL * applicationSupportURL =
        [[NSFileManager defaultManager]
          URLForDirectory: NSApplicationSupportDirectory
          inDomain: NSUserDomainMask
          appropriateForURL: nil
          create: YES
          error: NULL];

      NSURL * reportsDirectory =
        [applicationSupportURL
          URLByAppendingPathComponent: @"EtreCheck/Reports"];
        
      [[NSFileManager defaultManager]
        createDirectoryAtPath: [reportsDirectory path]
        withIntermediateDirectories: YES
        attributes: [NSDictionary dictionary]
        error: NULL];
      
      NSURL * url =
        [reportsDirectory
          URLByAppendingPathComponent:
            [NSString
              stringWithFormat:
                @"EtreCheck %@.rtf", [self currentFilename]]];
      
      [[NSUserDefaults standardUserDefaults]
        setObject: [url path] forKey: @"lastreport"];
        
      [rtfData writeToURL: url atomically: YES];
      
      [[NSDocumentController sharedDocumentController]
        noteNewRecentDocumentURL: url];
      }
    }
  }

// Open a recent report.
- (BOOL) application: (NSApplication *) sender
  openFile: (NSString *) filename
  {
  NSString * extension = [filename pathExtension];
  
  if([extension isEqualToString: @"rtf"])
    {
    NSURL * url = [NSURL fileURLWithPath: filename];
    
    [[NSWorkspace sharedWorkspace] openURL: url];
    
    return YES;
    }
    
  return NO;
  }

// Clear the recents menu.
- (IBAction) clearRecentDocuments: (id) sender
  {
  [[NSDocumentController sharedDocumentController]
    clearRecentDocuments: sender];

  NSURL * applicationSupportURL =
    [[NSFileManager defaultManager]
      URLForDirectory: NSApplicationSupportDirectory
      inDomain: NSUserDomainMask
      appropriateForURL: nil
      create: YES
      error: NULL];

  NSURL * reportsDirectory =
    [applicationSupportURL
      URLByAppendingPathComponent: @"EtreCheck/Reports"];
    
  NSArray * paths =
    [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath: [reportsDirectory path] error: NULL];
  
  NSMutableArray * urls = [NSMutableArray array];
  
  for(NSString * path in paths)
    {
    NSURL * url = [reportsDirectory URLByAppendingPathComponent: path];
    
    [urls addObject: url];
    }
    
  [[NSWorkspace sharedWorkspace]
    recycleURLs: urls
    completionHandler:
      ^(NSDictionary * newURLs, NSError * error)
        {
        }];
  }

// Dim the display on deactivate.
- (void) applicationDidResignActive: (NSNotification *) notification
  {
  self.active = NO;
  
  NSNumber * curScreenNum =
    [self.window.screen.deviceDescription objectForKey: @"NSScreenNumber"];

  if(!CGDisplayUsesOpenGLAcceleration(curScreenNum.unsignedIntValue))
    return;
    
  CIFilter * grayscale = [CIFilter filterWithName: @"CIColorMonochrome"];
  [grayscale setDefaults];
  [grayscale
    setValue:
      [CIColor colorWithRed: 0.3f green: 0.3f blue: 0.3f alpha: 1.0f]
    forKey: @"inputColor"];
    
  CIFilter * gamma = [CIFilter filterWithName: @"CIGammaAdjust"];
  [gamma setDefaults];
  [gamma setValue: [NSNumber numberWithDouble: 0.3] forKey: @"inputPower"];
    
  self.helpButton.image = self.helpButtonInactiveImage;
  self.donateButton.image = self.donateButtonInactiveImage;
  
  [self.collectionStatusLabel
    setTextColor: [NSColor disabledControlTextColor]];
    
  [self.textSizeButton setEnabled: NO];
  
  [self.reportView setContentFilters: @[grayscale, gamma]];
  
  if(self.animationView)
    {
    [self.animationView setContentFilters: @[grayscale, gamma]];

    CIFilter * grayscale =
      [CIFilter filterWithName: @"CIColorMonochrome"];
    [grayscale setDefaults];
    [grayscale
      setValue:
        [CIColor colorWithRed: 0.6f green: 0.6f blue: 0.6f alpha: 1.0f]
      forKey: @"inputColor"];
      
    [self.magnifyingGlassShade setContentFilters: @[grayscale]];
    }
  }

// Un-dim the display on activate.
- (void) applicationWillBecomeActive: (NSNotification *) notification
  {
  self.active = YES;
  
  NSNumber * curScreenNum =
    [self.window.screen.deviceDescription objectForKey: @"NSScreenNumber"];

  if(!CGDisplayUsesOpenGLAcceleration(curScreenNum.unsignedIntValue))
    return;

  self.helpButton.image = self.helpButtonImage;
  self.donateButton.image = self.donateButtonImage;
  
  [self.collectionStatusLabel setTextColor: [NSColor controlTextColor]];

  [self.textSizeButton setEnabled: YES];

  [self.reportView setContentFilters: @[]];

  if(self.animationView)
    {
    [self.animationView setContentFilters: @[]];
    [self.magnifyingGlassShade setContentFilters: @[]];
    
    double progress = [self.progress doubleValue];
    
    if(progress > 1.0)
      {
      [self.progress setDoubleValue: progress - 1.0];
      [self.progress setDoubleValue: progress];
      }
    }
  }

- (void) windowDidResignKey: (NSNotification *) notification
  {
  if(notification.object == self.window)
    [self applicationDidResignActive: notification];
  }

- (void) windowDidBecomeKey: (NSNotification *) notification
  {
  if(notification.object == self.window)
    [self applicationWillBecomeActive: notification];
  }

// Handle an "etrecheck:" URL.
- (void) handleGetURLEvent: (NSAppleEventDescriptor *) event
  withReplyEvent: (NSAppleEventDescriptor *) reply
  {
  // Don't reply to events unless there is a report available.
  if(!self.reportAvailable)
    return;
    
  NSString * urlString =
    [[event paramDescriptorForKeyword: keyDirectObject] stringValue];
  
  NSURL * url = [NSURL URLWithString: urlString];
    
  if([[url scheme] isEqualToString: @"etrecheck"])
    {
    NSString * manager = [url host];
    NSString * relativePath = [[url path] substringFromIndex: 1];
    
    if([manager isEqualToString: @"detail"])
      [self.detailManager showDetail: relativePath];
    else if([manager isEqualToString: @"help"])
      [self.helpManager showDetail: relativePath];
    else if([manager isEqualToString: @"cleanup"])
      {
      if([relativePath isEqualToString: @"orphans"])
        [self.cleanupManager show];
      else if([relativePath hasPrefix: @"notificationspam/"])
        {
        NSString * spammer = [relativePath substringFromIndex: 17];
        
        [self.notificationSPAMCleanupManager show: spammer];
        }
      }
    else if([manager isEqualToString: @"adware"])
      [self.adwareManager show];
    else if([manager isEqualToString: @"unsigned"])
      {
      NSString * file = 
        [[url query] 
          stringByReplacingPercentEscapesUsingEncoding: 
            NSUTF8StringEncoding];
      
      if([relativePath isEqualToString: @"disable"])
        [self.adwareManager disableFile: file];
      else if([relativePath isEqualToString: @"enable"])
        [self.adwareManager enableFile: file];
      }
    else if([manager isEqualToString: @"smart"])
      [self.smartManager showDetail: relativePath];
    else if([manager isEqualToString: @"license"])
      {
      NSString * licensePath =
        [[NSBundle mainBundle] pathForResource: relativePath ofType: NULL];

      NSURL * url = [NSURL fileURLWithPath: licensePath];
    
      [[NSWorkspace sharedWorkspace] openURL: url];
      }
    else if([manager isEqualToString: @"open"])
      {
      relativePath =
        [[[Model model] pathsForUUIDs] objectForKey: relativePath];
      
      if([relativePath length] > 0)
        [[NSWorkspace sharedWorkspace] openFile: relativePath];
      }
    else if([manager isEqualToString: @"enablegatekeeper"])
      [self enableGatekeeper];
    }
  }

// Enable Gatekeeper.
- (void) enableGatekeeper
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText:
      NSLocalizedString(@"Enable Gatekeeper", NULL)];
    
  [alert setAlertStyle: NSWarningAlertStyle];

  [alert
    setInformativeText: NSLocalizedString(@"enablegatekeeper", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];
  [alert addButtonWithTitle: NSLocalizedString(@"Cancel", NULL)];

  NSInteger result = [alert runModal];

  [alert release];

  if(result == NSAlertFirstButtonReturn)
    [Utilities enableGatekeeper];
  }

// Check for a new version.
- (void) checkForUpdates
  {
  GET * request =
    [[GET alloc]
      init:
        [Utilities
          buildSecureURLString:
            @"etrecheck.com/download/ApplicationUpdates.plist"]
      callback:
        ^(CURLRequest * curlRequest, BOOL success)
          {
          dispatch_async(
            dispatch_get_main_queue(),
            ^{
              if(!success)
                [self updateFailed];
              else
                [self handleUpdate: curlRequest.response];
            });
          }];
    
  dispatch_async(
    dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [request send];
        [request release];      
      });
  }

// Handle update data.
- (void) handleUpdate: (NSData *) data
  {
  NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
    
  [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
  
  NSString * appBundleId = [[NSBundle mainBundle] bundleIdentifier];
  
  NSString * appVersion =
    [[[NSBundle mainBundle] infoDictionary]
      objectForKey: @"CFBundleVersion"];

  NSDictionary * info = [NSDictionary readPropertyListData: data];
  
  for(NSString * key in info)
    if([key isEqualToString: @"Application Updates"])
      for(NSDictionary * attributes in [info objectForKey: key])
        {
        NSString * bundleId =
          [attributes objectForKey: @"CFBundleIdentifier"];
        
        if([appBundleId isEqualToString: bundleId])
          {
          NSString * version = 
            [attributes objectForKey: @"CFBundleVersion"];
          
          if([version compare: appVersion] == NSOrderedAscending)
            [self
              presentUpdate:
                [attributes
                  objectForKey: NSLocalizedString(@"changes", NULL)]
              url:
                [NSURL URLWithString: [attributes objectForKey: @"URL"]]];
          else
            [[Model model] setVerifiedEtreCheckVersion: YES];
            
          NSArray * whitelist = [attributes objectForKey: @"whitelist"];
          
          if([whitelist respondsToSelector: @selector(addObject:)])
            [[Model model] appendToWhitelist: whitelist];

          NSArray * whitelistPrefixes =
            [attributes objectForKey: @"whitelist_prefixes"];
          
          if([whitelist respondsToSelector: @selector(addObject:)])
            [[Model model] appendToWhitelistPrefixes: whitelistPrefixes];

          NSArray * blacklist = [attributes objectForKey: @"blacklist"];
          
          if([blacklist respondsToSelector: @selector(addObject:)])
            [[Model model] appendToBlacklist: blacklist];

          NSArray * blacklistSuffix =
            [attributes objectForKey: @"blacklist_suffix"];
          
          if([blacklist respondsToSelector: @selector(addObject:)])
            [[Model model] appendToBlacklistSuffixes: blacklistSuffix];

          NSArray * blacklistMatch =
            [attributes objectForKey: @"blacklist_match"];
          
          if([blacklist respondsToSelector: @selector(addObject:)])
            [[Model model] appendToBlacklistMatches: blacklistMatch];
          }
      }
    
  [numberFormatter release];
  }

// Show the update dialog.
- (void) presentUpdate: (NSString *) changes url: (NSURL *) url
  {
  [[Model model] setOldEtreCheckVersion: YES];
  
  self.updateManager.content = changes;
  self.updateManager.updateURL = url;
  
  [self.updateManager show];
  }

// Show the update failed dialog.
- (void) updateFailed
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Update Failed", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"updatefailed", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Quit", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Continue", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertFirstButtonReturn)
    [[NSApplication sharedApplication] terminate: self];
    
  [alert release];
  }

// Setup the start message.
- (void) setupStartMessage
  {
  self.introPanelView = self.introPanel.contentView;
  self.userParametersPanelView = self.userParametersPanel.contentView;
  
  [self.startPanelAnimationView
    transitionToView: self.introPanel.contentView];

  [self.chooseAProblemPromptItem setEnabled: YES];
  [self.chooseAProblemButton selectItem: self.chooseAProblemPromptItem];
  
  bool is1011 = false;
  
  if(floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10)
    {
    NSProcessInfo * processInfo = [NSProcessInfo processInfo];
    
    NSOperatingSystemVersion version;
    
    version.majorVersion = 10;
    version.minorVersion = 11;
    version.patchVersion = 0;
    
    is1011 = [processInfo isOperatingSystemAtLeastVersion: version];
    }
    
  NSImage * image = nil;
  
  if(is1011)
    image = [NSImage imageNamed: @"BeachballEC"];
  else
    image = [NSImage imageNamed: @"Beachball"];
    
  if(image)
    [self.beachballItem setImage: image];
  }

// Collect the user message.
- (void) collectUserParameters
  {
  self.window.status = kIntroduction;

  [[NSUserDefaults standardUserDefaults]
    removeObjectForKey: @"dontshowusermessage"];

  [[NSApplication sharedApplication]
    beginSheet: self.startPanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }
  
// Show Terms of Use agreement.
- (IBAction) showTOUAgreementCopy: (id) sender
  {
  if(self.copyDisabled)
    [self showCopyDisabled: sender];
  else if(self.TOSAccepted)
    [self copy: sender];
  else
    {
    self.acceptTOUButton.target = self;
    self.acceptTOUButton.action = @selector(copy:);
  
    [self showTOUAgreement: sender];
    }
  }

// Show Terms of Use agreement.
- (IBAction) showTOUAgreementCopyAll: (id) sender
  {
  if(self.copyDisabled)
    [self showCopyDisabled: sender];
  else if(self.TOSAccepted)
    [self copyToClipboard: sender];
  else
    {
    self.acceptTOUButton.target = self;
    self.acceptTOUButton.action = @selector(copyToClipboard:);
  
    [self showTOUAgreement: sender];
    }
  }

// Show Terms of Use agreement.
- (void) showTOUAgreement: (id) sender
  {
  [self.TOUView
    setLinkTextAttributes:
      @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone),
        NSCursorAttributeName : [NSCursor pointingHandCursor]
      }];

  NSData * rtfData =
    [NSData
      dataWithContentsOfFile:
        [[NSBundle mainBundle]
          pathForResource: @"TOU" ofType: @"rtf"]];
  
  NSRange range =
    NSMakeRange(0, [[self.TOUView textStorage] length]);

  [self.TOUView
    replaceCharactersInRange: range withRTF: rtfData];

  [[NSApplication sharedApplication]
    beginSheet: self.TOUPanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }

// Decline the Terms of Use.
- (IBAction) declineTOS: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.TOUPanel];
  }

- (void) didEndSheet: (NSWindow *) sheet
  returnCode: (NSInteger) returnCode contextInfo: (void *) contextInfo
  {
  [sheet orderOut: self];
  }

// Show the donate panel.
- (IBAction) showDonate: (id) sender;
  {
  NSData * rtfData =
    [NSData
      dataWithContentsOfFile:
        [[NSBundle mainBundle]
          pathForResource: @"donate" ofType: @"rtf"]];
  
  NSRange range =
    NSMakeRange(0, [[self.donateView textStorage] length]);

  [self.donateView
    replaceCharactersInRange: range withRTF: rtfData];

  [[NSApplication sharedApplication]
    beginSheet: self.donatePanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }

// Donate another day.
- (IBAction) donateLater: (id) sender;
  {
  [[NSApplication sharedApplication] endSheet: self.donatePanel];

  [[NSUserDefaults standardUserDefaults]
    setObject: @"later" forKey: @"donate"];
  }

// Donate now.
- (IBAction) donate: (id) sender
  {
  NSString * donationKey = [Utilities UUID];
  
  NSString * urlString =
    [NSString
      stringWithFormat:
        NSLocalizedString(@"donateurl", nULL), donationKey];
  
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL URLWithString: [Utilities buildSecureURLString: urlString]]];

  [[NSApplication sharedApplication] endSheet: self.donatePanel];

  [[NSUserDefaults standardUserDefaults]
    setObject: @"yes" forKey: @"donate"];

  [[NSUserDefaults standardUserDefaults]
    setObject: donationKey forKey: @"donationkey"];
  }

// Lookup a donation.
- (IBAction) lookupDonation: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.donatePanel];

  [[NSApplication sharedApplication]
    beginSheet: self.donationLookupPanel
    modalForWindow: self.window
    modalDelegate: self
    didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
    contextInfo: nil];
  }

// Perform an automatic donation lookup.
- (IBAction) automaticDonationLookup: (id) sender
  {
  NSString * email =
    [self.donationLookupEmail
      stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

  if(![email length])
    {
    [self donationNotFound: sender];
    
    return;
    }

  NSString * emailHash = [Utilities MD5: email];
  
  NSMutableString * json = [NSMutableString string];
  
  [json appendFormat: @"{\"emailkey\": \"%@\"}", emailHash];
    
  POST * request =
    [[POST alloc]
      init:
        [Utilities
          buildSecureURLString: @"etrecheck.com/server/lookupdonation.php"]
      callback:
        ^(CURLRequest * curlRequest, BOOL success)
          {
          dispatch_async(
            dispatch_get_main_queue(),
            ^{
              if(success)
                {
                NSString * donationKey = curlRequest.responseString;
                  
                if([donationKey length])
                  {
                  [[NSUserDefaults standardUserDefaults]
                    setObject: donationKey forKey: @"donationkey"];

                  [self donationFound];
                  
                  return;
                  }
                }
              
              [self donationNotFound: sender];
            });
          }];

   dispatch_async(
    dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [request send: json];
        [request release];      
      });
  }

- (void) donationNotFound: (id) sender
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Donation not found", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"donationnotfound", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Close", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Manual", NULL)];

  NSModalResponse result = [alert runModal];
  
  [alert release];
  
  if(result == NSAlertSecondButtonReturn)
    [self manualDonationLookup: sender];
  }

- (void) donationFound
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Donation Found!", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"donationfound", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"Close", NULL)];

  [alert runModal];

  [alert release];
  
  [self cancelDonationLookup: self];
  }

// Lookup a donation via e-mail.
- (IBAction) manualDonationLookup: (id) sender
  {
  NSMutableString * content = [NSMutableString string];
  
  [content
    appendFormat:
      NSLocalizedString(@"Email: %@\n", NULL), self.donationLookupEmail];
  
  [content appendString: @"\n"];
  [content appendString: NSLocalizedString(@"manualdonationlookup", NULL)];
  
  // Try to use an existeing donation key.
  NSString * donationKey =
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"donationkey"];

  if(donationKey == nil)
    donationKey = [Utilities UUID];
  
  [[NSUserDefaults standardUserDefaults]
    setObject: donationKey forKey: @"donationkey"];

  [content appendString: donationKey];
  [content appendString: @"\n"];
  [content appendString: [Utilities MD5: self.donationLookupEmail]];

  [Utilities
    sendEmailTo: @"info@etresoft.com"
    withSubject: NSLocalizedString(@"Please lookup donation", NULL)
    content: content];
    
  [self cancelDonationLookup: sender];
  }

// Cancel a donation lookup.
- (IBAction) cancelDonationLookup: (id) sender
  {
  self.donationLookupEmail = nil;
  
  [[NSApplication sharedApplication] endSheet: self.donationLookupPanel];
  }

// Close the active window.
- (IBAction) closeWindow: (id) sender
  {
  NSWindow * keyWindow = [[NSApplication sharedApplication] keyWindow];
  
  if(keyWindow == self.window)
    [[NSApplication sharedApplication] terminate: sender];
  else
    [keyWindow performClose: sender];
  }

// Start the report.
- (IBAction) start: (id) sender
  {
  self.cancelButton.enabled = YES;
  
  [[NSApplication sharedApplication] endSheet: self.startPanel];
  
  self.reportStartTime = [NSDate date];
  
  [self startProgressTimer];
  
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      [self collectInfo];
    });
    
  self.window.status = kRunning;
  }

// Start the progress timer.
- (void) startProgressTimer
  {
  NSDockTile * docTile = [[NSApplication sharedApplication] dockTile];
  
  NSImageView * docTileImageView = [[NSImageView alloc] init];
  
  // Only thing that works in Snow Leopard.
  NSImage * appIcon = [NSImage imageNamed: @"AppIcon.icns"];
  
  [appIcon setSize: NSMakeSize(1024.0, 1024.0)];
  
  [docTileImageView setImage: appIcon];
    
  [docTile setContentView: docTileImageView];

  [docTileImageView release];
  
  NSProgressIndicator * progressIndicator =
    [[NSProgressIndicator alloc]
      initWithFrame: NSMakeRect(0.0, 0.0, docTile.size.width, 10.0)];
    
  self.dockProgress = progressIndicator;
  
  [progressIndicator release];
  
  [self.dockProgress setStyle: NSProgressIndicatorBarStyle];
  [self.dockProgress setIndeterminate: NO];
  [docTileImageView addSubview: self.dockProgress];

  //[self.dockProgress setBezeled: YES];
  [self.dockProgress setMinValue: 0];
  [self.dockProgress setMaxValue: 100];

  self.progressTimer =
    [NSTimer
      scheduledTimerWithTimeInterval: .3
      target: self
      selector: @selector(fireProgressTimer:)
      userInfo: nil
      repeats: YES];
  }

// Progress timer.
- (void) fireProgressTimer: (NSTimer *) timer
  {
  double current = [self.progress doubleValue];
  
  current = current + 0.5;
    
  if(current > self.nextProgressIncrement)
    return;
    
  [self updateProgress: current];
  
  if(current >= 100)
    [timer invalidate];
  }
  
// Cancel the report.
- (IBAction) cancel: (id) sender
  {
  [[NSApplication sharedApplication] endSheet: self.donationLookupPanel];
  [[NSApplication sharedApplication] endSheet: self.donatePanel];
  [[NSApplication sharedApplication] endSheet: self.TOUPanel];
  [[NSApplication sharedApplication] endSheet: self.startPanel];

  [[NSApplication sharedApplication] terminate: sender];
  }

// Allow the program to close when closing the window.
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:
  (NSApplication *) sender
  {
  return YES;
  }

// Fire it up.
- (void) collectInfo
  {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.progress startAnimation: self];
      [self.spinner startAnimation: self];
    });

  [self setupNotificationHandlers];
  
  Checker * checker = [Checker new];
  
  NSAttributedString * results = [checker check];
  
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self printEtreCheckHeader];
  
      [self.log appendAttributedString: results];
  
      [checker collectOutput];
      
      [self displayOutput];
    });
    
  [checker release];
  
  [pool drain];
  }

// Print the EtreCheck header.
- (void) printEtreCheckHeader
  {
  NSBundle * bundle = [NSBundle mainBundle];
  
  NSString * version = 
    [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

  NSString * build = 
    [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];

  NSDate * date = [NSDate date];
  
  NSString * currentDate = [Utilities dateAsString: date];
              
  [[[Model model] header] startElement: @"header"];

  [[[Model model] header] addElement: @"version" value: version];
  [[[Model model] header] addElement: @"build" value: build];
  [[[Model model] header] addElement: @"date" date: date];

  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(
            @"EtreCheck version: %@ (%@)\nReport generated %@\n", NULL),
            version,
            build,
            currentDate]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];
    
  [self.log
    appendString: NSLocalizedString(@"downloadetrecheck", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSString * url = [Utilities buildSecureURLString: @"etrecheck.com"];
  
  [self.log
    appendAttributedString: [Utilities buildURL: url title: url]];
    
  [self.log appendString: @"\n"];
  
  NSString * runtime = [self elapsedTime];
  
  [[[Model model] header] 
    addElement: @"runtime" 
    value: runtime 
    attributes: 
      [NSDictionary dictionaryWithObjectsAndKeys: @"mm:ss", @"units", nil]];

  [self.log
    appendString:
      [NSString
        stringWithFormat:
          NSLocalizedString(@"Runtime: %@\n", NULL), runtime]
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  [self printPerformance];
    
  [self.log appendString: @"\n"];
  
  [self printLinkInstructions];
  [self printOptions];
  [self printErrors];
  [self printProblem];

  [[[Model model] header] endElement: @"header"];
  }

// Print performance.
- (void) printPerformance
  {
  [self.log
    appendString: NSLocalizedString(@"Performance: ", NULL)
    attributes:
      [NSDictionary
       dictionaryWithObjectsAndKeys:
         [[Utilities shared] boldFont], NSFontAttributeName, nil]];

  NSTimeInterval interval = [self elapsedSeconds];
  
  if(interval > (60 * 10))
    {
    NSString * performance = NSLocalizedString(@"poorperformance", NULL);
    
    [[[Model model] header] addElement: @"performance" value: performance];
    
    [self.log
      appendString: performance
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else if(interval > (60 * 5))
    {
    NSString * performance = 
      NSLocalizedString(@"belowaverageperformance", NULL);
    
    [[[Model model] header] addElement: @"performance" value: performance];
    
    [self.log
      appendString: performance
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else if(interval > (60 * 3))
    {
    NSString * performance = 
      NSLocalizedString(@"goodperformance", NULL);
    
    [[[Model model] header] addElement: @"performance" value: performance];
    
    [self.log
      appendString: performance
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
  else
    {
    NSString * performance = 
      NSLocalizedString(@"excellentperformance", NULL);
    
    [[[Model model] header] addElement: @"performance" value: performance];
    
    [self.log
       appendString: performance
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    }
    
  [self.log appendString: @"\n"];
  }

// Print link instructions.
- (void) printLinkInstructions
  {
  [self.log
    appendRTFData:
      [NSData
        dataWithContentsOfFile:
          [[NSBundle mainBundle]
            pathForResource: @"linkhelp" ofType: @"rtf"]]];

  if([[Model model] adwareFound])
    [self.log
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"adwarehelp" ofType: @"rtf"]]];
    
  if([[Model model] unsignedFound])
    [self.log
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"unsignedhelp" ofType: @"rtf"]]];

  if([[Model model] cleanupRequired])
    [self.log
      appendRTFData:
        [NSData
          dataWithContentsOfFile:
            [[NSBundle mainBundle]
              pathForResource: @"cleanuphelp" ofType: @"rtf"]]];

  [self.log appendString: @"\n"];
  }

// Print option settings.
- (void) printOptions
  {
  bool options = NO;
  
  if([[Model model] showSignatureFailures])
    {
    [self.log
      appendString:
        NSLocalizedString(
          @"Show signature failures: Enabled\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![[Model model] ignoreKnownAppleFailures])
    {
    [self.log
      appendString:
        NSLocalizedString(
          @"Ignore expected failures in Apple tasks: Disabled\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(![[Model model] hideAppleTasks])
    {
    [self.log
      appendString:
        NSLocalizedString(
          @"Hide Apple tasks: Disabled\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
      
    options = YES;
    }

  if(options)
    [self.log appendString: @"\n"];
  }

// Print errors during EtreCheck itself.
- (void) printErrors
  {
  NSArray * terminatedTasks = [[Model model] terminatedTasks];
  
  if(terminatedTasks.count > 0)
    {
    [self.log
      appendString:
        NSLocalizedString(
          @"The following internal tasks failed to complete:\n", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];

    for(NSString * task in terminatedTasks)
      {
      [self.log
        appendString: task
        attributes:
          @{
            NSForegroundColorAttributeName : [[Utilities shared] red],
            NSFontAttributeName : [[Utilities shared] boldFont]
          }];
      
      [self.log appendString: @"\n"];
      }

    [self.log appendString: @"\n"];
    }
    
  if([[[Model model] whitelistFiles] count] < kMinimumWhitelistSize)
    {
    [self.log
      appendString:
        NSLocalizedString(@"Failed to read adware signatures!", NULL)
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    [self.log appendString: @"\n\n"];
    }
      
  if([NSLocalizedString(@"downloadetrecheck", NULL) length] == 17)
    {
    NSString * message = @"Failed to load language resources!";
    
    NSLocale * locale = [NSLocale currentLocale];
  
    NSString * language =
      [[locale objectForKey: NSLocaleLanguageCode] lowercaseString];

    if([language isEqualToString: @"fr"])
      message = @"Échec de chargement des ressources linguistiques"; 

    [self.log
      appendString: message
      attributes:
        @{
          NSForegroundColorAttributeName : [[Utilities shared] red],
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    
    [self.log appendString: @"\n\n"];
    }
  }

// Print the problem from the user.
- (void) printProblem
  {
  [self.log
    appendString: NSLocalizedString(@"Problem: ", NULL)
    attributes:
      @{
        NSFontAttributeName : [[Utilities shared] boldFont]
      }];
  
  if(self.problemIndex > 0)
    if(self.problemIndex <= self.chooseAProblemButton.menu.itemArray.count)
      {
      NSMenuItem * selectedItem =
        [self.chooseAProblemButton.menu.itemArray
          objectAtIndex: self.problemIndex];
      
      [[[Model model] header] 
        addElement: @"problem" value: selectedItem.title];

      [self.log appendString: selectedItem.title];
      [self.log appendString: @"\n"];
      }
    
  if(self.problemDescription)
    {
    [[[Model model] header] 
      addElement: @"problemdescription" 
      value: self.problemDescription.string];

    [self.log
      appendString: NSLocalizedString(@"Description:\n", NULL)
      attributes:
        @{
          NSFontAttributeName : [[Utilities shared] boldFont]
        }];
    [self.log appendAttributedString: self.problemDescription];
    [self.log appendString: @"\n"];
    }
    
  [self.log appendString: @"\n"];
  }

// Get the current file name as a string.
- (NSString *) currentFilename
  {
  return
    [Utilities dateAsString: [NSDate date] format: @"yyyy-MM-dd HHmmss"];
  }

// Get the elapsed time as a number of seconds.
- (NSTimeInterval) elapsedSeconds
  {
  NSDate * current = [NSDate date];
  
  return [current timeIntervalSinceDate: self.reportStartTime];
  }

// Get the elapsed time as a string.
- (NSString *) elapsedTime
  {
  NSDate * current = [NSDate date];
  
  NSTimeInterval interval =
    [current timeIntervalSinceDate: self.reportStartTime];

  NSUInteger minutes = (NSUInteger)interval / 60;
  NSUInteger seconds = (NSUInteger)interval - (minutes * 60);
  
  return
    [NSString
      stringWithFormat:
        @"%ld:%02ld", (unsigned long)minutes, (unsigned long)seconds];
  }

// Setup notification handlers.
- (void) setupNotificationHandlers
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(statusUpdated:)
    name: kStatusUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(progressUpdated:)
    name: kProgressUpdate
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(applicationFound:)
    name: kFoundApplication
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showMachineIcon:)
    name: kShowMachineIcon
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showCollectionStatus:)
    name: kCollectionStatus
    object: nil];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(showDemonAgent:)
    name: kShowDemonAgent
    object: nil];
  }

// Handle a status update.
- (void) statusUpdated: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      NSMutableAttributedString * status = [self.displayStatus mutableCopy];
      
      [status
        appendString:
          [NSString stringWithFormat: @"%@\n", [notification object]]];

      self.displayStatus = status;

      [status release];
      
      [[self.statusView animator]
        scrollRangeToVisible:
          NSMakeRange(self.statusView.string.length, 0)];
    });  
  }
  
// Handle a progress update.
- (void) progressUpdated: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      self.nextProgressIncrement = [[notification object] doubleValue];
    });
  }

- (void) updateProgress: (double) amount
  {
  // Try to make Snow Leopard update.
  if((self.nextProgressIncrement - [self.progress doubleValue]) > 1)
    [self.progress setNeedsDisplay: YES];

  // Snow Leopard doesn't like animations with CA layers.
  // Beat it with a rubber hose.
  [self.progress setHidden: YES];
  [self.progress setDoubleValue: amount];
  [self.progress setHidden: NO];
  [self.progress startAnimation: self];
  
  [self.dockProgress setDoubleValue: amount];
  [[[NSApplication sharedApplication] dockTile] display];
  }

// Handle an application found.
- (void) applicationFound: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.applicationIcon transitionToImage: [notification object]];
    });
  }

// Show a machine icon.
- (void) showMachineIcon: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      [self.machineIcon transitionToImage: [notification object]];
    });
  }

// Show the coarse collection status.
- (void) showCollectionStatus: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      // Move the spinner to make room for the status.
      NSString * status = [notification object];
      
      NSRect oldRect =
        [self.collectionStatus
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect newRect =
        [status
          boundingRectWithSize: NSMakeSize(1000, 1000)
          options:0
          attributes:
            @{
              NSFontAttributeName: [NSFont labelFontOfSize: 12.0]
            }];

      NSRect frame = [self.spinner frame];
      
      if(oldRect.size.width > 0)
        frame.origin.x -= 24;
      
      frame.origin.x -= oldRect.size.width / 2;
      frame.origin.x += newRect.size.width / 2;
      frame.origin.x += 24;
      
      // Snow Leopard doesn't like progress indicators with CA layers.
      // Beat it with a rubber hose.
      [self.spinner setHidden: YES];
      [self.spinner setFrame: frame];
      [self.spinner setHidden: NO];
      
      self.collectionStatus = [notification object];
    });
  }

// Show the demon and agent animation.
- (void) showDemonAgent: (NSNotification *) notification
  {
  dispatch_async(
    dispatch_get_main_queue(),
    ^{
      NSRect demonStartFrame = [self.demonImage frame];
      NSRect demonEndFrame = demonStartFrame;
      
      demonEndFrame.origin.x -= 45;

      NSRect agentStartFrame = [self.agentImage frame];
      NSRect agentEndFrame = agentStartFrame;
      
      agentEndFrame.origin.x += 45;

      [self animateDemon: demonEndFrame];
      [self animateDemon: demonStartFrame agent: agentEndFrame];
      [self animateAgent: agentStartFrame];
    });
  }

// Show the demon.
- (void) animateDemon: (NSRect) demonEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonEndFrame];
      
      [NSAnimationContext endGrouping];
    });
  }

// Hide the demon and show the agent.
- (void) animateDemon: (NSRect) demonStartFrame agent: (NSRect) agentEndFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.demonImage animator] setFrame: demonStartFrame];
      [[self.agentImage animator] setFrame: agentEndFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Hide the agent.
- (void) animateAgent: (NSRect) agentStartFrame
  {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(21 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      [NSAnimationContext beginGrouping];
      
      [[NSAnimationContext currentContext] setDuration: 0.5];
      
      [[self.agentImage animator] setFrame: agentStartFrame];

      [NSAnimationContext endGrouping];
    });
  }

// Show the output pane.
- (void) displayOutput
  {
  [self.progressTimer invalidate];
  
  [self.dockProgress removeFromSuperview];
  [[[NSApplication sharedApplication] dockTile] display];

  self.window.status = kReportTransition;

  NSData * rtfData =
    [self.log
      RTFFromRange: NSMakeRange(0, [self.log length])
      documentAttributes: @{}];
  
  NSRange range =
    NSMakeRange(0, [[self.logView textStorage] length]);

  [self.logView
    replaceCharactersInRange: range withRTF: rtfData];
    
  // Adjust the size of the content frame to prevent horizontal scrolling.
  NSRect contentFrame = [self.logView frame];
    
  contentFrame.size.width -= 20;
  
  [self.logView setFrame: contentFrame];
  
  [self transitionToReportView];
  [self updateRunCount];
  }

// Transition to the report view.
- (void) transitionToReportView
  {
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(didScroll:)
    name: NSViewBoundsDidChangeNotification
    object: [[self.logView enclosingScrollView] contentView]];
  
  [[[self.logView enclosingScrollView] contentView]
    setPostsBoundsChangedNotifications: YES];

  //[self.window makeFirstResponder: self.logView];
  
  NSRect frame = [self.window frame];
  
  if(frame.size.height < 512)
    {
    frame.size.height += (kHeightOffset * 2);
    frame.origin.y -= kHeightOffset;
    }
    
  double duration = [window animationResizeTime: frame];
  
  [NSAnimationContext beginGrouping];
  
  self.toolbar.visible = YES;

  if(self.active)
    {
    self.helpButton.image = self.helpButtonImage;
    self.donateButton.image = self.donateButtonImage;
    }
  else
    {
    self.helpButton.image = self.helpButtonInactiveImage;
    self.donateButton.image = self.donateButtonInactiveImage;
    }
    
  self.reportAvailable = YES;
  [self.toolbar validateVisibleItems];
  
  [[NSAnimationContext currentContext] setDuration: duration];
  
  [self.window.contentView addSubview: self.reportView];
  
  [[self.animationView animator] removeFromSuperview];
  
  self.animationView = nil;
  
  [NSAnimationContext endGrouping];

  [window setFrame: frame display: YES animate: YES];

  [[self.logView enclosingScrollView] setHasVerticalScroller: YES];
  [self.window setShowsResizeIndicator: YES];
  [self.window
    setStyleMask: [self.window styleMask] | NSResizableWindowMask];
  
  [self notify];

  [self.logView
    scrollRangeToVisible: NSMakeRange([self.log length] - 2, 1)];
  [self.logView scrollRangeToVisible: NSMakeRange(0, 1)];
  
  self.window.status = kReport;

  // Beg for money.
  [self checkForDonation];
  
  NSDictionary * environment = [[NSProcessInfo processInfo] environment];

  if([[environment objectForKey: @"ETRECHECK_SIMULATE"] boolValue])
    {
    NSString * path = 
      [[@"~/Desktop/EtreCheck4" stringByExpandingTildeInPath] 
        stringByAppendingPathComponent: @"test.etrecheck"];
  
    [[[[Model model] xml] XML] 
      writeToFile: path 
      atomically: YES 
      encoding: NSUTF8StringEncoding 
      error: NULL];
    }
  }

// Update the run count.
- (void) updateRunCount
  {
  NSNumber * count =
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"reportcount"];
    
  int runCount = 1;
  
  if([count respondsToSelector: @selector(intValue)])
    runCount = [count intValue] + 1;
    
  [[NSUserDefaults standardUserDefaults]
    setObject: [NSNumber numberWithInt: runCount] forKey: @"reportcount"];
  }

// Ask for a donation under certain circumstances.
- (void) checkForDonation
  {
  NSString * donationKey =
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"donationkey"];
   
  [self verifyDonationKey: donationKey];
  }

- (void) verifyDonationKey: (NSString *) donationKey
  {
  if([donationKey length] == 0)
    self.donationVerified = NO;
    
  NSMutableString * json = [NSMutableString string];
  
  [json appendFormat: @"{\"donationkey\": \"%@\"}", donationKey];
    
  POST * request =
    [[POST alloc]
      init:
        [Utilities
          buildSecureURLString: @"etrecheck.com/server/verifydonation.php"]
      callback:
        ^(CURLRequest * curlRequest, BOOL success)
          {
          dispatch_async(
            dispatch_get_main_queue(),
            ^{
              if(success)
                self.donationVerified =
                  [curlRequest.responseString isEqualToString: @"OK"];
              else
                self.donationVerified = NO;
              
              if(!self.donationVerified)
                [self askForDonation];
            });
          }];

  dispatch_async(
    dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^{
        [request send: json];
        [request release];
      });
  }

// Ask for a donation under certain circumstances.
- (void) askForDonation
  {
  NSNumber * count =
    [[NSUserDefaults standardUserDefaults]
      objectForKey: @"reportcount"];
    
  int runCount = 1;
  
  if([count respondsToSelector: @selector(intValue)])
    runCount = [count intValue];
  
  NSUInteger justCheckingIndex =
    (self.chooseAProblemButton.menu.itemArray.count - 1);
    
  bool ask = NO;
  
  if(self.problemIndex == justCheckingIndex)
    ask = YES;
    
  if(runCount > 5)
    ask = YES;
    
  if(ask)
    [self showDonate: self];
  }

// Handle a scroll change in the report view.
- (void) didScroll: (NSNotification *) notification
  {
  [self.smartManager closeDetail: self];
  [self.detailManager closeDetail: self];
  [self.helpManager closeDetail: self];
  }

// Notify the user that the report is done.
- (void) notify
  {
  if(![NSUserNotificationCenter class])
    return;
    
  // Notify the user.
  NSUserNotification * notification = [[NSUserNotification alloc] init];
    
  notification.title = NSLocalizedString(@"EtreCheck", NULL);
  notification.informativeText =
    NSLocalizedString(@"Report complete", NULL);
  
  // TODO: Do something clever with sound and notifications.
  notification.soundName = NSUserNotificationDefaultSoundName;
  
  [[NSUserNotificationCenter defaultUserNotificationCenter]
    deliverNotification: notification];
    
  [notification release];
  }

// Display web site when the user clicks on a notification.
- (void) userNotificationCenter: (NSUserNotificationCenter *) center
  didActivateNotification: (NSUserNotification *) notification
  {
  if([self.window isMiniaturized])
    [self.window deminiaturize: self];
    
  [self.window makeKeyAndOrderFront: self];
  }

// Copy the report to the clipboard.
- (IBAction) copy: (id) sender
  {
  self.TOSAccepted = YES;
  
  [[NSApplication sharedApplication] endSheet: self.TOUPanel];
  
  [self.currentTextView copy: sender];
  }

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender
  {
  self.TOSAccepted = YES;
  
  [[NSApplication sharedApplication] endSheet: self.TOUPanel];

  NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
 
  [pasteboard clearContents];
 
  NSError * error = nil;
  
  NSData * rtfData =
    [self.log
      dataFromRange: NSMakeRange(0, [self.log length])
      documentAttributes:
        @
          {
          NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
          }
      error: & error];

  [pasteboard setData: rtfData forType: NSPasteboardTypeRTF];
  
  /* Nope. This drops the red colour.
  
  NSData * htmlData =
    [self.log
      dataFromRange: NSMakeRange(0, [self.log length])
      documentAttributes:
        @
          {
          NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType
          }
      error: & error];

  [pasteboard setData: htmlData forType: NSPasteboardTypeHTML]; */
  
  /* Poison pill
  
  [self.logView
    writePDFInsideRect: self.logView.bounds toPasteboard: pasteboard]; */
  }
  
// Show a custom about panel.
- (IBAction) showAbout: (id) sender
  {
  [[NSApplication sharedApplication]
    orderFrontStandardAboutPanelWithOptions: @{@"Version" : @""}];
  }

// Show the preferences panel.
- (IBAction) showPreferences: (id) sender
  {
  }

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL:
      [NSURL
        URLWithString:
          [Utilities buildSecureURLString: @"www.etresoft.com"]]];
  }

// Go to the Etresoft web support site.
- (IBAction) gotoEtresoftSupport: (id) sender
  {
  [[NSWorkspace sharedWorkspace]
    openURL: [NSURL URLWithString: @"mailto:support@etresoft.com"]];
  }

// Display help.
- (IBAction) showHelp: (id) sender
  {
  NSURL * url =
    [[NSBundle mainBundle]
      URLForResource: @"index"
      withExtension: @"html"
      subdirectory: @"Help"];

  [[NSWorkspace sharedWorkspace] openURL: url];
  }

// Display FAQ.
- (IBAction) showFAQ: (id) sender
  {
  NSURL * url =
    [[NSBundle mainBundle]
      URLForResource: @"faq"
      withExtension: @"html"
      subdirectory: @"Help"];

  [[NSWorkspace sharedWorkspace] openURL: url];
  }

// Show the log window.
- (IBAction) showLog: (id) sender
  {
  [self.logWindow makeKeyAndOrderFront: sender];
  }

// Shwo the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender
  {
  [self.window makeKeyAndOrderFront: sender];
  }

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert
    setMessageText: NSLocalizedString(@"Confirm cancellation", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert
    setInformativeText:
      NSLocalizedString(
        @"Are you sure you want to cancel this EtreCheck report?", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"No, continue", NULL)];

  [alert addButtonWithTitle: NSLocalizedString(@"Yes, cancel", NULL)];

  NSInteger result = [alert runModal];

  if(result == NSAlertSecondButtonReturn)
    [self cancel: sender];
    
  [alert release];
  }

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender
  {
  NSSavePanel * savePanel = [NSSavePanel savePanel];
  
  [savePanel setAllowedFileTypes: @[@"rtf"]];
  
  NSInteger result = [savePanel runModal];
  
  if(result == NSFileHandlingPanelOKButton)
    {
    NSError * error = nil;
    
    NSData * rtfData =
      [self.log
        dataFromRange: NSMakeRange(0, [self.log length])
        documentAttributes:
          @
            {
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
            }
        error: & error];
      
    if(rtfData)
      [rtfData writeToURL: [savePanel URL] atomically: YES];
    }
  }

// Print the report. This needs to be a selector for AppDelegate so that
// the delegate can disable the toolbar item via validateToolbarItem.
- (IBAction) printReport: (id) sender
  {
  [self.logView print: sender];
  }

// Toggle the options view.
- (IBAction) toggleOptions: (id) sender
  {
  if(self.optionsVisible)
    {
    [self.startPanelAnimationView
      updateSubviewsWithTransition: kCATransitionPush
      subType: kCATransitionFromRight];

    [self.startPanelAnimationView
      transitionToView: self.introPanel.contentView];
    [self.startPanelAnimationView setNeedsDisplay: YES];
    
    self.optionsButton.title = NSLocalizedString(@"Options", NULL);
    
    self.optionsVisible = NO;
    }
  else
    {
    [self.startPanelAnimationView
      updateSubviewsWithTransition: kCATransitionPush
      subType: kCATransitionFromLeft];
    
    [self.startPanelAnimationView
      transitionToView: self.userParametersPanel.contentView];
    [self.startPanelAnimationView setNeedsDisplay: YES];

    self.optionsButton.title = NSLocalizedString(@"Back", NULL);

    self.optionsVisible = YES;
    }
  }

// Set focus to the problem description when a problem is selected.
- (IBAction) problemSelected: (id) sender
  {
  NSButton * button = sender;
  
  [button.window makeFirstResponder: self.problemDescriptionTextView];
  }

// Set text size to normal.
- (void) changeTextSizeFrom: (NSUInteger) from to: (NSUInteger) to
  {
  double scale = 1.0;
  
  switch(from)
    {
    case kTextSizeNormal:
      switch(to)
        {
        case kTextSizeLarger:
          scale = 1.5;
          break;
        case kTextSizeVeryLarge:
          scale = 2.0;
          break;
        }
      break;
    case kTextSizeLarger:
      switch(to)
        {
        case kTextSizeNormal:
          scale = 1.0/1.5;
          break;
        case kTextSizeVeryLarge:
          scale = 2.0/1.5;
          break;
        }
      break;
    case kTextSizeVeryLarge:
      switch(to)
        {
        case kTextSizeNormal:
          scale = 0.5;
          break;
        case kTextSizeLarger:
          scale = 1.5/2.0;
          break;
        }
      break;
    }
    
  NSSize size = NSMakeSize((CGFloat)scale, (CGFloat)scale);

  NSRect frame = [self.window frame];

  CGFloat newWidth = frame.size.width * (CGFloat)scale;
  CGFloat horizontalOffset = (frame.size.width - newWidth)/(CGFloat)2.0;

  frame.origin.x += horizontalOffset;
  frame.size.width = newWidth;

  [window setFrame: frame display: YES animate: YES];

  [self.logView scaleUnitSquareToSize: size];
  [self.logView setNeedsDisplay: YES];
  }

// Authorize EtreCheck options and disable copy/paste, if necessary.
- (IBAction) authorizeOptions: (id) sender
  {
  // Maybe the poor user has changed his or her mind due to these terrible
  // consequences. 
  if(self.copyDisabled)
    {
    if([self ignoreKnownAppleFailures])
      if(![self showSignatureFailures])
        if([self hideAppleTasks])
          {
          self.copyDisabled = NO;
          
          return;
          }
    }
    
  if(!self.copyDisabled)
    {
    NSAlert * alert = [[NSAlert alloc] init];

    [alert setMessageText: NSLocalizedString(@"Please confirm", NULL)];
      
    [alert setAlertStyle: NSInformationalAlertStyle];

    [alert setInformativeText: NSLocalizedString(@"authorizeoptions", NULL)];

    // This is the rightmost, first, default button.
    [alert addButtonWithTitle: NSLocalizedString(@"Cancel", NULL)];

    [alert addButtonWithTitle: NSLocalizedString(@"Confirm", NULL)];

    NSModalResponse result = [alert runModal];
    
    [alert release];
    
    if(result == NSAlertSecondButtonReturn)
      self.copyDisabled = YES;
    else
      {
      [self setIgnoreKnownAppleFailures: YES];
      [self setShowSignatureFailures: NO];
      [self setHideAppleTasks: YES];
      }
    }
  }

// Tell the user that copy and paste has been disabled.
- (void) showCopyDisabled: (id) sender
  {
  NSAlert * alert = [[NSAlert alloc] init];

  [alert setMessageText: NSLocalizedString(@"Clipboard disabled", NULL)];
    
  [alert setAlertStyle: NSInformationalAlertStyle];

  [alert setInformativeText: NSLocalizedString(@"copydisabled", NULL)];

  // This is the rightmost, first, default button.
  [alert addButtonWithTitle: NSLocalizedString(@"OK", NULL)];

  [alert runModal];
  
  [alert release];
  }

#pragma mark - NSToolbarDelegate conformance

- (void) toolbarWillAddItem: (NSNotification *) notification
  {
  NSToolbarItem * addedItem =
    [[notification userInfo] objectForKey: @"item"];
    
  if([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier])
    {
    [addedItem setToolTip: NSLocalizedString(@"Print Report", NULL)];
    [addedItem setTarget: self];
    [addedItem setAction: @selector(printReport:)];
    }
  }

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  willBeInsertedIntoToolbar: (BOOL) flag
  {
  if([itemIdentifier isEqualToString: kShareToolbarItemID])
    return
      [self
        createShareToolbar: toolbar itemForItemIdentifier: itemIdentifier];

  else if([itemIdentifier isEqualToString: kHelpToolbarItemID])
    return
      [self
        createHelpToolbar: toolbar itemForItemIdentifier: itemIdentifier];

  else if([itemIdentifier isEqualToString: kTextSizeToolbarItemID])
    return
      [self
        createTextSizeToolbar: toolbar
        itemForItemIdentifier: itemIdentifier];

  else if([itemIdentifier isEqualToString: kDonateTollbarItemID])
    return
      [self
        createDonateToolbar: toolbar itemForItemIdentifier: itemIdentifier];
    
  return nil;
  }

- (NSToolbarItem *) createShareToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  EtreCheckToolbarItem * item =
    [[[EtreCheckToolbarItem alloc]
      initWithItemIdentifier: itemIdentifier] autorelease];
  
  if([NSSharingServicePicker class])
    {
    [item setLabel: NSLocalizedString(@"Share Report", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Share Report", nil)];
    [item setView: self.shareToolbarItemView];
    item.control = self.shareButton;
    }
  else
    {
    [item setLabel: NSLocalizedString(@"Copy Report", nil)];
    [item setPaletteLabel: NSLocalizedString(@"Copy Report", nil)];
    [item setView: self.clipboardCopyToolbarItemView];
    item.control = self.clipboardCopyButton;
    }
    
  [item setTarget: self];
  [item setAction: nil];
  item.appDelegate = self;
  
  return item;
  }

- (NSToolbarItem *) createHelpToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  EtreCheckToolbarItem * item =
    [[[EtreCheckToolbarItem alloc]
      initWithItemIdentifier: itemIdentifier] autorelease];
  
  [item setLabel: NSLocalizedString(@"Help", nil)];
  [item setPaletteLabel: NSLocalizedString(@"Help", nil)];
  [item setTarget: self];
  [item setAction: nil];
  [item setView: self.helpToolbarItemView];
  item.control = self.helpButton;
  item.appDelegate = self;
  
  return item;
  }

- (NSToolbarItem *) createTextSizeToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  EtreCheckToolbarItem * item =
    [[[EtreCheckToolbarItem alloc]
      initWithItemIdentifier: itemIdentifier] autorelease];
  
  [item setLabel: NSLocalizedString(@"Text Size", nil)];
  [item setPaletteLabel: NSLocalizedString(@"Text Size", nil)];
  [item setTarget: self];
  [item setAction: nil];
  [item setView: self.textSizeToolbarItemView];
  item.control = self.textSizeButton;
  item.appDelegate = self;
  
  return item;
  }

- (NSToolbarItem *) createDonateToolbar: (NSToolbar *) toolbar
  itemForItemIdentifier: (NSString *) itemIdentifier
  {
  // Create the NSToolbarItem and setup its attributes.
  EtreCheckToolbarItem * item =
    [[[EtreCheckToolbarItem alloc]
      initWithItemIdentifier: itemIdentifier] autorelease];
  
  [item setLabel: NSLocalizedString(@"Donate", nil)];
  [item setPaletteLabel: NSLocalizedString(@"Donate", nil)];
  [item setTarget: self];
  [item setAction: nil];
  [item setView: self.donateToolbarItemView];
  item.control = self.donateButton;
  item.appDelegate = self;
  
  return item;
  }

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
  {
  BOOL isMavericksOrLater =
    [[NSProcessInfo processInfo]
      respondsToSelector: @selector(operatingSystemVersion)];
  
  if(!isMavericksOrLater)
    return
      @[
        kShareToolbarItemID,
        kHelpToolbarItemID,
        NSToolbarFlexibleSpaceItemIdentifier,
        kDonateTollbarItemID,
        NSToolbarPrintItemIdentifier
      ];

  return
    @[
      kShareToolbarItemID,
      kHelpToolbarItemID,
      kTextSizeToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      kDonateTollbarItemID,
      NSToolbarPrintItemIdentifier
    ];
    
  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "default" list of items.
  }

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
  {
  BOOL isMavericksOrLater =
    [[NSProcessInfo processInfo]
      respondsToSelector: @selector(operatingSystemVersion)];
  
  if(!isMavericksOrLater)
    return
      @[
        kShareToolbarItemID,
        kHelpToolbarItemID,
        NSToolbarFlexibleSpaceItemIdentifier,
        kDonateTollbarItemID,
        NSToolbarPrintItemIdentifier
      ];

  return
    @[
      kShareToolbarItemID,
      kHelpToolbarItemID,
      kTextSizeToolbarItemID,
      NSToolbarFlexibleSpaceItemIdentifier,
      kDonateTollbarItemID,
      NSToolbarPrintItemIdentifier
    ];

  // Since the toolbar is defined from Interface Builder, an additional
  // separator and customize toolbar items will be automatically added to
  // the "allowed" list of items.
  }

// Validate toolbar items.
- (BOOL) validateToolbarItem: (NSToolbarItem *) theItem
  {
  return self.reportAvailable;
  }

#pragma mark - Sharing

// Share the EtreCheck report.
- (IBAction) shareReport: (id) sender
  {
  NSSharingServicePicker * sharingServicePicker =
    [[NSSharingServicePicker alloc]
      initWithItems:
        [NSArray arrayWithObjects: self.log, nil]];
    
  sharingServicePicker.delegate = self;
  
  [sharingServicePicker
    showRelativeToRect: NSZeroRect
    ofView: sender
    preferredEdge: NSMinYEdge];
    
  [sharingServicePicker release];
  }

#pragma mark - NSSharingServicePickerDelegate conformance

- (id <NSSharingServiceDelegate>)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  delegateForSharingService: (NSSharingService *) sharingService
  {
  return self;
  }

- (void) sharingServicePicker:
  (NSSharingServicePicker *) sharingServicePicker
  didChooseSharingService: (NSSharingService *) service
  {
  [service setDelegate: self];
  }

- (NSArray *)
  sharingServicePicker: (NSSharingServicePicker *) sharingServicePicker
  sharingServicesForItems: (NSArray *) items
  proposedSharingServices: (NSArray *) proposedServices
  {
   NSMutableArray * sharingServices = [NSMutableArray array];
   
   NSSharingService * customService =
     [[[NSSharingService alloc]
       initWithTitle: NSLocalizedString(@"Copy Report", NULL)
       image: [NSImage imageNamed: @"Copy"]
       alternateImage: nil
       handler:
         ^{
          [self doCustomServiceWithItems: items];
          }] autorelease];
    
  [sharingServices addObject: customService];
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeEmail]];
  [sharingServices
    addObject:
      [NSSharingService
        sharingServiceNamed: NSSharingServiceNameComposeMessage]];
  
  return sharingServices;
  }

- (void) doCustomServiceWithItems: (NSArray *) items
  {
  [self showTOUAgreementCopyAll: self];
  }

#pragma mark - NSSharingServiceDelegate conformance

// Define the window that gets dimmed out during sharing.
- (NSWindow *) sharingService: (NSSharingService *) sharingService
  sourceWindowForShareItems: (NSArray *)items
  sharingContentScope: (NSSharingContentScope *) sharingContentScope
  {
  return self.window;
  }

- (NSRect) sharingService: (NSSharingService *) sharingService
  sourceFrameOnScreenForShareItem: (id<NSPasteboardWriting>) item
  {
  NSRect frame = [self.logView bounds];
  
  frame = [self.logView convertRect: frame toView: nil];
  
  return [[self.logView window] convertRectToScreen: frame];
  
  return frame;
  }

- (NSImage *) sharingService: (NSSharingService *) sharingService
  transitionImageForShareItem: (id <NSPasteboardWriting>) item
  contentRect: (NSRect *) contentRect
  {
  NSRect rect = [self.logView bounds];
  
  NSBitmapImageRep * imageRep =
    [self.logView bitmapImageRepForCachingDisplayInRect: rect];
  [self.logView cacheDisplayInRect: rect toBitmapImageRep: imageRep];

  NSImage * image = [[NSImage alloc] initWithSize: rect.size];
  [image addRepresentation: imageRep];
   
  return [image autorelease];
  }

#pragma mark - Menu item validation.

- (BOOL) validateUserInterfaceItem:
  (id<NSValidatedUserInterfaceItem>) anItem
  {
  if(anItem == self.chooseAProblemPromptItem)
    return NO;
  else if(anItem == self.closeMenuItem)
    {
    NSWindow * keyWindow = [[NSApplication sharedApplication] keyWindow];
  
    if(keyWindow == self.startPanel)
      return NO;
    }

  return YES;
  }

// Dummy menu item action for auto-disable.
- (IBAction) dummyAction: (id) sender
  {
  }

#pragma mark - NSMenuDelegate conformance

- (void) menuDidClose: (NSMenu *) menu
  {
  if(!self.problemSelected)
    {
    [self.chooseAProblemPromptItem setEnabled: YES];
    [self.chooseAProblemButton selectItem: self.chooseAProblemPromptItem];
    }
  }

#pragma mark - Control EtreCheck behaviour

@end

NSComparisonResult compareViews(id view1, id view2, void * context)
  {
  AppDelegate * self = (AppDelegate *)context;
  
  if(view1 == self.applicationIcon)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlass && view2 == self.applicationIcon)
    return NSOrderedDescending;
    
  if(view1 == self.magnifyingGlass)
    return NSOrderedAscending;
    
  if(view1 == self.magnifyingGlassShade)
    return NSOrderedAscending;

  return NSOrderedSame;
  }

