/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2012-2014. All rights reserved.
 **********************************************************************/

#import <Cocoa/Cocoa.h>

@class SlideshowView;
@class DetailManager;
@class SMARTManager;
@class HelpManager;
@class CleanupManager;
@class NotificationSPAMCleanupManager;
@class AdwareManager;
@class UpdateManager;
@class EtreCheckWindow;

@interface AppDelegate : NSObject
  <NSApplicationDelegate,
  NSUserNotificationCenterDelegate,
  NSToolbarDelegate,
  NSSharingServiceDelegate,
  NSSharingServicePickerDelegate,
  NSUserInterfaceValidations>
  {
  EtreCheckWindow * window;
  NSMenuItem * myCloseMenuItem;
  NSWindow * myLogWindow;
  NSView * myAnimationView;
  NSView * myReportView;
  NSProgressIndicator * myProgress;
  NSProgressIndicator * mySpinner;
  NSProgressIndicator * myDockProgress;
  NSButton * myCancelButton;
  NSTextView * myStatusView;
  NSTextView * logView;
  NSAttributedString * myDisplayStatus;
  NSMutableAttributedString * log;
  double myNextProgressIncrement;
  NSTimer * myProgressTimer;
  SlideshowView * myMachineIcon;
  SlideshowView * myApplicationIcon;
  NSImageView * myMagnifyingGlass;
  NSImageView * myMagnifyingGlassShade;
  NSImageView * myFinderIcon;
  NSImageView * myDemonImage;
  NSImageView * myAgentImage;
  NSString * myCollectionStatus;
  NSTextField * myCollectionStatusLabel;
  NSWindow * myStartPanel;
  SlideshowView * myStartPanelAnimationView;
  NSWindow * myIntroPanel;
  NSView * myIntroPanelView;
  NSUInteger myProblemIndex;
  NSPopUpButton * myChooseAProblemButton;
  NSMenuItem * myChooseAProblemPromptItem;
  NSMenuItem * myBeachballItem;
  NSAttributedString * myProblemDescription;
  NSTextView * myProblemDescriptionTextView;
  NSButton * myOptionsButton;
  BOOL myOptionsVisible;
  NSWindow * myUserParametersPanel;
  NSView * myUserParametersPanelView;
  
  NSView * myClipboardCopyToolbarItemView;
  NSButton * myClipboardCopyButton;
  NSView * myShareToolbarItemView;
  NSButton * myShareButton;
  NSView * myHelpToolbarItemView;
  NSButton * myHelpButton;
  NSImage * myHelpButtonImage;
  NSImage * myHelpButtonInactiveImage;
  NSView * myTextSizeToolbarItemView;
  NSButton * myTextSizeButton;
  NSUInteger myTextSize;
  NSView * myDonateToolbarItemView;
  NSButton * myDonateButton;
  NSImage * myDonateButtonImage;
  NSImage * myDonateButtonInactiveImage;
  NSToolbar * myToolbar;

  NSMutableDictionary * launchdStatus;
  NSMutableSet * appleLaunchd;
  
  DetailManager * myDetailManager;
  SMARTManager * mySMARTManager;
  HelpManager * myHelpManager;
  CleanupManager * myCleanupManager;
  NotificationSPAMCleanupManager * myNotificationSPAMCleanupManager;
  AdwareManager * myAdwareManager;
  UpdateManager * myUpdateManager;
  
  BOOL myReportAvailable;
  NSDate * myReportStartTime;
  
  NSWindow * myTOUPanel;
  NSTextView * myTOUView;
  NSButton * myAcceptTOUButton;
  BOOL myTOSAccepted;

  NSWindow * myDonatePanel;
  NSTextView * myDonateView;
  NSWindow * myDonationLookupPanel;
  NSString * myDonationLookupEmail;
  BOOL myDonationVerified;
  
  BOOL myCopyDisabled;
  BOOL myActive;
  }
  
@property (retain) IBOutlet EtreCheckWindow * window;
@property (retain) IBOutlet NSMenuItem * closeMenuItem;
@property (retain) IBOutlet NSWindow * logWindow;
@property (retain) IBOutlet NSView * animationView;
@property (retain) IBOutlet NSView * reportView;
@property (retain) IBOutlet NSProgressIndicator * progress;
@property (retain) IBOutlet NSProgressIndicator * spinner;
@property (retain) IBOutlet NSProgressIndicator * dockProgress;
@property (retain) IBOutlet NSButton * cancelButton;
@property (retain) IBOutlet NSTextView * statusView;
@property (retain) IBOutlet NSTextView * logView;
@property (retain) NSAttributedString * displayStatus;
@property (retain) NSMutableAttributedString * log;
@property (assign) double nextProgressIncrement;
@property (retain) NSTimer * progressTimer;
@property (retain) IBOutlet SlideshowView * machineIcon;
@property (retain) IBOutlet SlideshowView * applicationIcon;
@property (retain) IBOutlet NSImageView * magnifyingGlass;
@property (retain) IBOutlet NSImageView * magnifyingGlassShade;
@property (retain) IBOutlet NSImageView * finderIcon;
@property (retain) IBOutlet NSImageView * demonImage;
@property (retain) IBOutlet NSImageView * agentImage;
@property (retain) NSString * collectionStatus;
@property (retain) IBOutlet NSTextField * collectionStatusLabel;
@property (retain) IBOutlet NSWindow * startPanel;
@property (retain) IBOutlet SlideshowView * startPanelAnimationView;
@property (retain) IBOutlet NSWindow * introPanel;
@property (retain) IBOutlet NSView * introPanelView;
@property (assign) NSUInteger problemIndex;
@property (retain) IBOutlet NSPopUpButton * chooseAProblemButton;
@property (retain) IBOutlet NSMenuItem * chooseAProblemPromptItem;
@property (retain) IBOutlet NSMenuItem * beachballItem;
@property (readonly) bool problemSelected;
@property (retain) NSAttributedString * problemDescription;
@property (retain) IBOutlet NSTextView * problemDescriptionTextView;
@property (retain) IBOutlet NSButton * optionsButton;
@property (assign) BOOL optionsVisible;
@property (retain) IBOutlet NSWindow * userParametersPanel;
@property (retain) IBOutlet NSView * userParametersPanelView;
@property (retain) IBOutlet NSView * shareToolbarItemView;
@property (retain) IBOutlet NSButton * shareButton;
@property (retain) IBOutlet NSView * clipboardCopyToolbarItemView;
@property (retain) IBOutlet NSButton * clipboardCopyButton;
@property (retain) IBOutlet NSView * helpToolbarItemView;
@property (retain) IBOutlet NSButton * helpButton;
@property (retain) IBOutlet NSImage * helpButtonImage;
@property (retain) IBOutlet NSImage * helpButtonInactiveImage;
@property (retain) IBOutlet NSView * textSizeToolbarItemView;
@property (retain) IBOutlet NSButton * textSizeButton;
@property (assign) NSUInteger textSize;
@property (retain) IBOutlet NSView * donateToolbarItemView;
@property (retain) IBOutlet NSButton * donateButton;
@property (retain) IBOutlet NSImage * donateButtonImage;
@property (retain) IBOutlet NSImage * donateButtonInactiveImage;
@property (retain) IBOutlet NSToolbar * toolbar;
@property (retain) IBOutlet DetailManager * detailManager;
@property (retain) IBOutlet SMARTManager * smartManager;
@property (retain) IBOutlet HelpManager * helpManager;
@property (retain) IBOutlet CleanupManager * cleanupManager;
@property (retain) IBOutlet
  NotificationSPAMCleanupManager * notificationSPAMCleanupManager;
@property (retain) IBOutlet AdwareManager * adwareManager;
@property (retain) IBOutlet UpdateManager * updateManager;
@property (assign) BOOL reportAvailable;
@property (retain) NSDate * reportStartTime;
@property (retain) IBOutlet NSWindow * TOUPanel;
@property (retain) IBOutlet NSTextView * TOUView;
@property (retain) IBOutlet NSButton * acceptTOUButton;
@property (assign) BOOL TOSAccepted;
@property (retain) IBOutlet NSWindow * donatePanel;
@property (retain) IBOutlet NSTextView * donateView;
@property (retain) IBOutlet NSWindow * donationLookupPanel;
@property (retain) NSString * donationLookupEmail;
@property (readonly) BOOL canSubmitDonationLookup;
@property (assign) BOOL donationVerified;
@property (readonly) NSTextView * currentTextView;
@property (assign) BOOL copyDisabled;
@property (assign) BOOL active;

// Ignore known Apple failures.
@property (assign) bool ignoreKnownAppleFailures;

// Show signature failures.
@property (assign) bool showSignatureFailures;

// Hide Apple tasks.
@property (assign) bool hideAppleTasks;

// Start the report.
- (IBAction) start: (id) sender;

// Cancel the report.
- (IBAction) cancel: (id) sender;

// Copy the report to the clipboard.
- (IBAction) copyToClipboard: (id) sender;

// Show a custom about panel.
- (IBAction) showAbout: (id) sender;

// Go to the Etresoft web site.
- (IBAction) gotoEtresoft: (id) sender;

// Go to the Etresoft support web site.
- (IBAction) gotoEtresoftSupport: (id) sender;

// Display help.
- (IBAction) showHelp: (id) sender;

// Display FAQ.
- (IBAction) showFAQ: (id) sender;

// Show the log window.
- (IBAction) showLog: (id) sender;

// Show the EtreCheck window.
- (IBAction) showEtreCheck: (id) sender;

// Confirm cancel.
- (IBAction) confirmCancel: (id) sender;

// Save the EtreCheck report.
- (IBAction) saveReport: (id) sender;

// Share the EtreCheck report.
- (IBAction) shareReport: (id) sender;

// Show Terms of Use agreement for a standard copy.
- (IBAction) showTOUAgreementCopy: (id) sender;

// Show Terms of Use agreement for a copy report.
- (IBAction) showTOUAgreementCopyAll: (id) sender;

// Decline the Terms of Use.
- (IBAction) declineTOS: (id) sender;

// Dummy menu item action for auto-disable.
- (IBAction) dummyAction: (id) sender;

// Set focus to the problem description when a problem is selected.
- (IBAction) problemSelected: (id) sender;

// Show the donate panel.
- (IBAction) showDonate: (id) sender;

// Donate another day.
- (IBAction) donateLater: (id) sender;

// Donate now.
- (IBAction) donate: (id) sender;

// Lookup a donation.
- (IBAction) lookupDonation: (id) sender;

// Perform an automatic donation lookup.
- (IBAction) automaticDonationLookup: (id) sender;

// Lookup a donation via e-mail.
- (IBAction) manualDonationLookup: (id) sender;

// Cancel a donation lookup.
- (IBAction) cancelDonationLookup: (id) sender;

// Close the active window.
- (IBAction) closeWindow: (id) sender;

// Authorize EtreCheck options and disable copy/paste, if necessary.
- (IBAction) authorizeOptions: (id) sender;

@end
