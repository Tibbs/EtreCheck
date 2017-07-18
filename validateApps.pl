#!/usr/bin/env perl

use strict;
use File::Basename;
use Capture::Tiny ':all';

my %apps = ();

my @xpc = `find /System -type d -iname "*.xpc" 2> /dev/null`;
my @sysapps = `find /System -type d -iname "*.app" 2> /dev/null`;
my @apps = `find /Applications -type d -iname "*.app" 2> /dev/null`;
my @bin = `find /bin -type f -or -type l 2> /dev/null`;
my @sbin = `find /sbin -type f -or -type l 2> /dev/null`;
my @usrbin = `find /usr/bin -type f -or -type l 2> /dev/null`;
my @usrsbin = `find /usr/sbin -type f -or -type l 2> /dev/null`;
my @libexec = `find /usr/libexec -type f -or -type l 2> /dev/null`;
my @launchd = getLaunchdExecutables();

my $expectedTemplate = 
  "%s: valid on disk\n"
  . "%s: satisfies its Designated Requirement\n"
  . "%s: explicit requirement satisfied\n";

my $notSignedTemplate = 
  "%s: code object is not signed at all\nIn architecture: x86_64\n";

my $OSVersion = getOSVersion();

foreach 
  my $bundle 
  (@xpc, 
  @sysapps, 
  @apps, 
  @bin, 
  @sbin, 
  @usrbin, 
  @usrsbin, 
  @libexec, 
  @launchd)
  {
  chomp $bundle;
        
  # Skip over shell scripts.
  next 
    if $bundle =~ /\.(plist|so|dylib|dylib\..+)$/;
    
  # Hack for MiniTerm.
  $bundle = '/usr/libexec/MiniTerm.app'
    if $bundle eq '/usr/libexec/MiniTerm.app/Contents/MacOS/MiniTerm';
  
  next 
    if $bundle =~ m|^/usr/libexec/MiniTerm.app/|;
     
  next
    if $bundle =~ m|\.DS_Store$|;
    
  $apps{$bundle} = 1;
  }

foreach my $app (sort keys %apps)
  {
  next 
    if $app =~ m|^/Library/Parallels|;

  my $shell = $app =~ /\.(pl|cgi|d|py|rb|sh)$/;
  
  my $result = 'signaturenotvalid';
  
  if($shell)
    {
    $result = 'signatureshell';
    }
  else
    {  
    $result = verify($app, 'apple', 'signatureapple');
  
    if($result eq 'signatureapple')
      {
      $result = 'signatureapple';
      }
    else
      {  
      $result = verify($app, 'apple generic', 'signaturevalid');
      }
    }
    
  printf("      <key>$app</key>\n      <string>$result</string>\n");
  }
    
sub verify
  {
  my $bundle = shift;
  my $anchor = shift;
  my $expectedResult = shift;
  
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
    if $data eq sprintf($notSignedTemplate, $ bundle);
    
  return "signaturenotvalid";
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
  
sub getLaunchdExecutables
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

  my @executables = ();
  
  foreach 
    my $plist 
    (@systemLaunchDaemons, 
    @systemLaunchAgents, 
    @launchDaemons, 
    @launchAgents, 
    @userLaunchAgents)
    {
    chomp $plist;
        
    my $entry = '"Print :Program"';
    
    my ($stdout, $stderr, $exit) = 
      capture 
        {
        system(qq{/usr/libexec/PlistBuddy -c $entry "$plist"});
        };
       
    chomp $stdout;
    
    my $program = $stdout;
     
    if(!$program || ! -e $program)
      {
      $entry = '"Print :ProgramArguments:0"';
    
      my ($stdout, $stderr, $exit) = 
        capture 
          {
          system(qq{/usr/libexec/PlistBuddy -c $entry "$plist"});
          };
      
      chomp $stdout;
      
      $program = $stdout;
      }
      
    my $parent = dirname($program);
    
    if($parent =~ m|(.+)/Contents/MacOS|)
      {
      $program = $1;
      }
      
    push @executables, $program
      if $program;
    }
    
  return @executables;
  }
  