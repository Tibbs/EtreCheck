#!/usr/bin/env perl

use strict;
use File::Basename;
use Capture::Tiny ':all';
use Digest::CRC qw(crc32);

my %apps = ();

my $expectedTemplate = 
  "%s: valid on disk\n"
  . "%s: satisfies its Designated Requirement\n"
  . "%s: explicit requirement satisfied\n";

my $notSignedTemplate = "%s: code object is not signed at all\n";

my $OSVersion = getOSVersion();

my @launchd = getLaunchdFiles();

foreach my $plist (@launchd)
  {
  my $path = $plist->{path};
  my $label = $plist->{label};
  my $program = $plist->{program};
  my $programArguments = $plist->{programArguments};
  my $signature = $plist->{signature};
  my $plist_checksum = $plist->{plist_checksum};
  my $executable_checksum = $plist->{executable_checksum};
  
  next 
    if $label =~ /^com\.parallels\./;

  printf("\t\t<key>$path</key>\n");
  printf("\t\t<dict>\n");

  if($label)
    {
    printf("\t\t\t<key>label</key>\n");
    printf("\t\t\t<string>$label</string>\n");
    }

  if($program)
    {
    printf("\t\t\t<key>program</key>\n");
    printf("\t\t\t<string>$program</string>\n");
    }

  if($programArguments)
    {  
    printf("\t\t\t<key>programArguments</key>\n");

    if(scalar(@{$programArguments}) > 0)
      {
      printf("\t\t\t<array>\n");
  
      for my $argument (@{$programArguments})
        {
        $argument =~ s/^\s+//;
        $argument =~ s/\s+$//;
        $argument =~ s/&/&amp;/g;
        $argument =~ s/"/&quot;/g;
    
        printf("\t\t\t\t<string>$argument</string>\n");
        }
    
      printf("\t\t\t</array>\n");
      }
    else
      {
      printf("\t\t\t<array/>\n");
      }
    }

  printf("\t\t\t<key>signature</key>\n");
  printf("\t\t\t<string>$signature</string>\n");

  if($plist_checksum)
    {
    printf("\t\t\t<key>plist_checksum</key>\n");
    printf("\t\t\t<string>$plist_checksum</string>\n");
    }

  if($executable_checksum)
    {
    printf("\t\t\t<key>executable_checksum</key>\n");
    printf("\t\t\t<string>$executable_checksum</string>\n");
    }

  printf("\t\t</dict>\n");
  }

sub verify
  {
  my $bundle = shift;
  my $anchor = shift;
  my $expectedResult = shift;
  
  return "executablemissing"
    if not -e $bundle;
    
  my ($data, $exit) = 
    capture_merged 
      {
      # Don't forget to add --no-strict for 10.9.5 and 10.10 only.
      my $hack = '';
      
      $hack = '--no-strict'
        if ($OSVersion eq '10.9.5') || ($OSVersion =~ /^10.10/);
        
      system(qq{/usr/bin/codesign -vv -R="anchor $anchor" $hack "$bundle"});
      };

  return $expectedResult
    if $data eq sprintf($expectedTemplate, $bundle, $bundle, $bundle);
    
  return "signaturemissing"
    if $data eq sprintf($notSignedTemplate, $bundle);
    
  return "signaturenotvalid";
  }

sub checkSignature
  {
  my $bundle = shift;
  
  return 'signatureshell'
    if isShellExecutable($bundle);

  my $result = verify($bundle, 'apple', 'signatureapple');

  if($result eq 'signatureapple')
    {
    $result = 'signatureapple';
    }
  else
    {  
    $result = verify($bundle, 'apple generic', 'signaturevalid');
    }

  if($result == 'signaturemissing')
    {
    return 'signatureshell'
      if isShellScript($bundle);
    }
    
  return $result;
  }
  
sub isShellExecutable
  {
  my $path = shift;
  
  my $name = basename($path);
  
  return 1
    if $path eq "tclsh";
  
  return 1
    if $path eq "perl";
  
  return 1
    if $path eq "ruby";
  
  return 1
    if $path eq "python";
  
  return 1
    if $path eq "sh";
  
  return 1
    if $path eq "csh";
  
  return 1
    if $path eq "bash";
  
  return 1
    if $path eq "zsh";
  
  return 1
    if $path eq "tsh";
  
  return 1
    if $path eq "ksh";
  
  return 0;  
  }
  
sub isShellScript
  {
  my $path = shift;
  
  my $shell = $path =~ /\.(sh|csh|pl|py|rb|cgi|php)$/;
  
  if(!$shell)
    {
    open(IN, $path);
    
    my $line = <IN>;
    
    $shell = $line =~ /^#!/;
    
    close(IN);
    }
    
  return $shell;
  }
  
sub getOSVersion
  {
  my ($stdout, $stderr, $exit) = 
    capture 
      {
      system(qq{system_profiler SPSoftwareDataType});
      };
  
  my ($version) = $stdout =~ /System\sVersion:\s(?:OS\sX|macOS)\s(\S+)\s\(.+\)/;
  
  return $version;
  }
  
sub getLaunchdFiles
  {
  my @systemLaunchDaemons = 
    `find /System/Library/LaunchDaemons -type f 2> /dev/null`;
  my @systemLaunchAgents = 
    `find /System/Library/LaunchAgents -type f 2> /dev/null`;
  my @launchDaemons = 
    `find /Library/LaunchDaemons -type f 2> /dev/null`;
  my @launchAgents = 
    `find /Library/LaunchAgents -type f 2> /dev/null`;
  my @userLaunchAgents = 
    `find ~/Library/LaunchAgents -type f 2> /dev/null`;

  my @files = ();
  
  foreach 
    my $plist 
    (@systemLaunchDaemons, 
    @systemLaunchAgents, 
    @launchDaemons, 
    @launchAgents, 
    @userLaunchAgents)
    {
    chomp $plist;
        
    next
      if $plist =~ m|\.DS_Store$|;
    
    my $entries = 
      '-c "Print :Label" -c "Print :Program" -c "Print :ProgramArguments"';
    
    my ($stdout, $stderr, $exit) = 
      capture 
        {
        system(qq{/usr/libexec/PlistBuddy $entries "$plist"});
        };
       
    my %missing;
    
    my (@errors) = split(/\n/, $stderr);
    
    foreach my $error (@errors)
      {
      # This should never happen.
      $missing{label} = 1
        if $error eq 'Print: Entry, ":Label", Does Not Exist';

      $missing{program} = 1 
        if $error eq 'Print: Entry, ":Program", Does Not Exist';
      
      $missing{programArguments} = 1
        if $error eq 'Print: Entry, ":ProgramArguments", Does Not Exist';
      }
      
    # Don't bother.
    next
      if $missing{label};
      
    my $label;
    my $program;
    my @programArguments;
    
    my (@lines) = split(/\n/, $stdout);

    $label = trim(shift(@lines));
    
    $program = trim(shift(@lines))
      if not $missing{program};
      
    @programArguments = @lines
      if not $missing{programArguments};
    
    shift(@programArguments)
      if $programArguments[0] eq 'Array {';
    
    pop(@programArguments)
      if $programArguments[$#programArguments] eq '}';
          
    $program = trim($programArguments[0])
      if not $program;
      
    my $bundle = $program;
      
    my $parent = dirname($program);
    
    if($parent =~ m~(.+\.app)/Contents/(?:MacOS|Resources)~)
      {
      $bundle = $1;
      }
      
    my $signature = checkSignature($bundle);

    my %checksums;

    if($signature ne 'signatureapple')
      {
      local $/;

      open(PLIST, $plist);
      my $plistData = <PLIST>;
      close(PLIST);

      my $crc = Digest::CRC->new(type=>"crc32");

      $crc->add($plistData);

      $checksums{'plist_checksum'} = $crc->hexdigest;
      }

    if($signature eq 'signaturenotvalid')
      {
      local $/;

      open(EXE, $program);
      my $exeData = <EXE>;
      close(EXE);

      my $crc = Digest::CRC->new(type=>"crc32");

      $crc->add($exeData);

      $checksums{'executable_checksum'} = $crc->hexdigest;
      }

    push 
      @files, 
        {
        path => $plist,
        label => $label,
        program => $program,
        programArguments => \@programArguments,
        signature => $signature,
        %checksums
        }
    }
    
  push @files, getManualAdditions();

  return @files;
  }
  
sub trim
  {
  my $value = shift;
  
  $value =~ s/^\s+//;
  $value =~ s/\s+$//;
  
  return $value;
  }  

sub getManualAdditions
  {
  my @additions;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.installer.osmessagetracing.plist',
    label => 'com.apple.installer.osmessagetracing',
    program => '/System/Library/PrivateFrameworks/OSInstaller.framework/Resources/OSMessageTracer',
    programArguments => ['/System/Library/PrivateFrameworks/OSInstaller.framework/Resources/OSMessageTracer'],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.10/ or $OSVersion =~ /^10\.11/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.xprotectupdater.plist',
    label => 'com.apple.xprotectupdater',
    program => '/usr/libexec/XProtectUpdater',
    programArguments => ['/usr/libexec/XProtectUpdater'],
    signature => 'executablemissing'
    }
    if $OSVersion =~ /^10\.10/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.rpmuxd.plist',
    label => 'com.apple.rpmuxd',
    program => '/usr/libexec/rpmuxd',
    programArguments => ['/usr/libexec/rpmuxd'],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.11/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchAgents/com.apple.webdriverd.plist',
    label => 'com.apple.webdriverd',
    program => '/usr/libexec/webdriverd',
    programArguments => [],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.11/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.hidfud.plist',
    label => 'com.apple.hidfud',
    program => '/System/Library/CoreServices/HID/FirmwareUpdates/hidfud',
    programArguments => ['/System/Library/CoreServices/HID/FirmwareUpdates/hidfud'],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchAgents/com.apple.SafariCloudHistoryPushAgent.plist',
    label => 'com.apple.SafariCloudHistoryPushAgent',
    program => '/usr/libexec/SafariCloudHistoryPushAgent',
    programArguments => [],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchAgents/com.apple.SafariNotificationAgent.plist',
    label => 'com.apple.SafariNotificationAgent',
    program => '/usr/libexec/SafariNotificationAgent',
    programArguments => [],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchAgents/com.apple.SafariPlugInUpdateNotifier.plist',
    label => 'com.apple.SafariPlugInUpdateNotifier',
    program => '/usr/libexec/SafariPlugInUpdateNotifier',
    programArguments => [],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchAgents/com.apple.webinspectord.plist',
    label => 'com.apple.webinspectord',
    program => '/usr/libexec/webinspectord',
    programArguments => [],
    signature => 'signatureapple'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.installer.cleanupinstaller.plist',
    label => 'com.apple.installer.cleanupinstaller',
    program => '/macOS Install Data/Locked Files/cleanup_installer',
    programArguments => ['/macOS Install Data/Locked Files/cleanup_installer'],
    signature => 'executablemissing'
    }
    if $OSVersion =~ /^10\.12/;

  push 
    @additions,
    {
    path => '/System/Library/LaunchDaemons/com.apple.jetsamproperties.Mac.plist',
    signature => 'executablemissing'
    }
    if $OSVersion =~ /^10\.12/;

  return @additions;
  }