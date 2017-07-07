#!/usr/bin/perl

# Reverse an EtreCheck report into a machine readable format.

use strict;

use Getopt::Long;

my $help;

GetOptions(
  'help' => \$help
  );

die usage()
  if $help;

my %sections =
  (
  Header => \&processHeader,
  'Hardware Information' => \&processHardwareInformation,
  'Video Information' => \&processVideoInformation,
  'Disk Information' => \&processDiskInformation,
  'USB Information' => \&processUSBInformation,
  'FireWire Information' => \&processFireWireInformation,
  'Thunderbolt Information' => \&processThunderboltInformation,
  'Virtual disks' => \&processVirtualDiskInformation,
  'System Software' => \&processSystemSoftware,
  'Configuration files' => \&processConfigurationFiles,
  Gatekeeper => \&processGatekeeperInformation,
  'Kernel Extensions' => \&processKernelInformation,
  'System Launch Agents' => \&processSystemLaunchAgents,
  'System Launch Daemons' => \&processSystemLaunchDaemons,
  'Launch Agents' => \&processLaunchAgents,
  'Launch Daemons' => \&processLaunchDaemons,
  'User Launch Agents' => \&processUserLaunchAgents,
  'User Login Items' => \&processUserLoginItems,
  'Internet Plug-ins' => \&processInternetPlugIns,
  'User internet Plug-ins' => \&processUserInternetPlugIns,
  'Safari Extensions' => \&processSafariExtensions,
  '3rd Party Preference Panes' => \&process3rdPartyPreferencePanes,
  'Time Machine' => \&processTimeMachine,
  'Top Processes by CPU' => \&processTopProcessesByCPU,
  'Top Processes by Memory' => \&processTopProcessesByMemory,
  'Top Processes by Network Use' => \&processTopProcessesByNetwork,
  'Top Processes by Energy Use' => \&processTopProcessesByEnergy,
  'Virtual Memory Information' => \&processVirtualMemoryInformation,
  'Software installs' => \&processSoftwareInstalls,
  'Diagnostics Information' => \&processDiagnosticsInformation,
  'EtreCheck Information' => \&processEtreCheckInformation
  );

my $line;
my $section = 'Header';
my $currentSection = '';
my $index = 0;

my @tags;

pushTag('etrecheck');
pushTag('header');

while($line = <>)
  {
  chomp $line;

  processLine();
  }

my $current = lc $currentSection;

popTag('etrecheck');

# Process a single line according to the current section.
sub processLine
  {
  # Check for a new section.
  if($line =~ /^([^:]+):\sⓘ$/)
    {
    # Close the current section. The header section is special.
    my $name = sectionTag($section);

    popTag($name);

    # Start a new section.
    $section = $1;
    $index = 0;
    
    $name = sectionTag($section);

    pushTag($name);

    $currentSection = $section;

    return;
    }
  
  ++$index;

  # Process the current section.
  $sections{$section}();
  }

# Process the header section.
sub processHeader
  {
  if($line =~ /^EtreCheck\sversion:\s(.+)\s\((.+)\)$/)
    {
    my $version = $1;
    my $build =$2;

    printTag('version', $version);
    printTag('build', $build);
    }
  elsif($line =~ /^Report\sgenerated\s(.+)$/)
    {
    my $date = $1;

    printTag('date', $date);
    }
  elsif($line =~ /^Runtime:\s(.+)$/)
    {
    my $runtime = $1;

    printTag('runtime', $runtime);
    }
  elsif($line =~ /^Performance:\s(.+)$/)
    {
    my $performance = $1;

    printTag('performance', $performance);
    }
  elsif($line =~ /^Problem:\s(.+)$/)
    {
    my $problem = $1;

    printTag('problem', $problem);
    }
  }

# Process hardware information.
sub processHardwareInformation
  {
  if($index == 1)
    {
    my ($marketingName) = $line =~ /^\s+(\S.+\S)\s*$/;

    printTag('marketing_name', $marketingName);
    }
  elsif($index == 3)
    {
    my ($modelName, $modelCode) = $line =~ /^\s+(.+)\s-\smodel:\s(.+)$/;

    printTag('modelname', $modelName);
    printTag('modelcode', $modelCode);
    }
  elsif($index == 4)
    {
    my ($cpuCount, $speed, $chipName, $chipCode, $coreCount) = 
      $line =~ /^\s+(\d+)\s(.+\sGHz)\s(.+)\s\((.+)\)\sCPU:\s(\d+)-core/;

    printTag('cpucount', $cpuCount);
    printTag('speed', $speed);
    printTag('chipname', $chipName);
    printTag('chipcode', $chipCode);
    printTag('corecount', $coreCount);
    }
  elsif($index == 5)
    {
    my ($RAM, $upgradeable) = 
      $line =~ /^\s+(\d+)\sGB\sRAM\s(Not\supgradeable|Upgradeable)/;

    printTag('ram', $RAM);
    printTag('upgradeable', $upgradeable);
    }
  elsif($line =~ /^\s+Battery:\sHealth\s=\s(.+)\s-\sCycle\scount\s=\s(\d+)/)
    {
    my $batteryHealth = $1;
    my $batteryCycleCount = $2;

    printTag('batteryhealth', $batteryHealth);
    printTag('batterycyclecount', $batteryCycleCount);
    }
  }

# Process video information.
sub processVideoInformation
  {
  if($line =~ /^\s+(.+)\s-\sVRAM:\s(.+)\s(?:MB|GB)/)
    {
    my $gpu = $1;
    my $VRAM = $2;

    popTag('displays')
      if currentTag() eq 'displays';

    popTag('gpu')
      if currentTag() eq 'gpu';

    pushTag('gpu');
    printTag('name', $gpu);
    printTag('vram', $VRAM);
    }
  elsif($line =~ /^\s+(\S.+\S)\s*$/)
    {
    my $display = $1;

    pushTag('displays')
      if currentTag() ne 'displays';

    printTag('display', $display);
    }
  }

# Process disk information.
sub processDiskInformation
  {
  if($line =~ /^\s+(\S.+\S)\s(disk.+):\s\(([\d.]+)\s.B\)\s\((Solid\sState|Rotational).*\)/)
    {
    my $diskModel = $1;
    my $device = $2;
    my $size = $3;
    my $type = $4;

    printTag('disk', $diskModel);
    printTag('device', $device);
    printTag('size', $size);
    printTag('type', $type);
    }
  }

# Process USB information.
sub processUSBInformation
  {
  if($line =~ /^\s+(\S.+\S)\s(disk.+):\s\(([\d.]+)\s.B\)\s\((Solid\sState|Rotational).*\)/)
    {
    my $diskModel = $1;
    my $device = $2;
    my $size = $3;
    my $type = $4;

    printTag('disk', $diskModel);
    printTag('device', $device);
    printTag('size', $size);
    printTag('type', $type);
    }
  }

# Process FireWire information.
sub processFireWireInformation
  {
  if($line =~ /^\s+(\S.+\S)\s(disk.+):\s\(([\d.]+)\s.B\)\s\((Solid\sState|Rotational).*\)/)
    {
    my $diskModel = $1;
    my $device = $2;
    my $size = $3;
    my $type = $4;

    printTag('disk', $diskModel);
    printTag('device', $device);
    printTag('size', $size);
    printTag('type', $type);
    }
  }

# Process Thunderbolt information.
sub processThunderboltInformation
  {
  if($line =~ /^\s+(\S.+\S)\s(disk.+):\s\(([\d.]+)\s.B\)\s\((Solid\sState|Rotational).*\)/)
    {
    my $diskModel = $1;
    my $device = $2;
    my $size = $3;
    my $type = $4;

    printTag('disk', $diskModel);
    printTag('device', $device);
    printTag('size', $size);
    printTag('type', $type);
    }
  }

# Process virtual disk information.
sub processVirtualDiskInformation
  {
  }

# Process system software.
sub processSystemSoftware
  {
  if($line =~ /^\s+(\S.+\S)\s+(10\.\d+.\d+)\s\((.+)\)\s-\sTime\ssince\sboot:\s(\S.+\S)\s*$/)
    {
    my $osname = $1;
    my $version = $2;
    my $build = $3;
    my $uptime = $4;

    printTag('name', $osname);
    printTag('version', $version);
    printTag('build', $build);
    printTag('uptime', $uptime);
    }
  }

# Process configuration files.
sub processConfigurationFiles
  {
  if($line =~ /^\s+\/etc\/hosts\s-\sCount:\s(\d+)$/)
    {
    my $hosts = $1;

    printTag('hostcounts', $hosts);
    }
  }

# Process Gatekeeper information.
sub processGatekeeperInformation
  {
  if($line =~ /^\s+(\S.+\S)\s*$/)
    {
    my $gatekeeper = $1;

    printTag('gatekeeper', $gatekeeper);
    }
  }

# Process kernel information.
sub processKernelInformation
  {
  if($line =~ /^\s+\[(\S+)\]\s+(.+)\s+\((\S+)\s-\sSDK\s(\S+)\)/)
    {
    my $status = $1;
    my $bundleID = $2;
    my $version = $3;
    my $SDKVersion = $4;

    pushTag('extension');
    printTag('bundleid', $bundleID);
    printTag('status', $status);
    printTag('version', $version);
    printTag('sdkversion', $SDKVersion);
    popTag('extension');
    }
  elsif($line =~ /^\s+(\S.+\S)\s*$/)
    {
    my $directory = $1;

    popTag('directory')
      if currentTag() eq 'directory';
    
    pushTag('directory');
    printTag('path', $directory);
    pushTag('extensions');
    }
  }

# Process system launch agents.
sub processSystemLaunchAgents
  {
  processSystemLaunchdAgents('/System/Library/LaunchAgents/');
  }

# Process system launch daemons.
sub processSystemLaunchDaemons
  {
  processSystemLaunchdAgents('/System/Library/LaunchDaemons/');
  }

# Process system launchd tasks.
sub processSystemLaunchdAgents
  {
  my $prefix = shift;

  if($line =~ /^\s+\[(.+)\]\s+(\d+)\sApple\stask/)
    {
    my $status = $1;
    my $count = $2;

    pushTag('appletasks');
    printTag('status', $status);
    printTag('count', $count);
    popTag('appletasks');    
    }
  else
    {
    processLaunchdLine($prefix);
    }
  }

# Process launch agents.
sub processLaunchAgents
  {
  processLaunchdLine('/Library/LaunchAgents/');
  }

# Process launch daemons.
sub processLaunchDaemons
  {
  processLaunchdLine('/Library/LaunchDaemons/');
  }

# Process user launch agents.
sub processUserLaunchAgents
  {
  processLaunchdLine('~/Library/LaunchAgents/');
  }

# Process a launchd script line.
sub processLaunchdLine 
  {
  my $prefix = shift;

  if($line =~ /^\s+\[(.+)\]\s+(\S.+\S)\s\((\S.+\S)\s-\sinstalled\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $status = $1;
    my $name = $2;
    my $signature = $3;
    my $date = $4;

    pushTag('task');
    printTag('path', "$prefix$name");
    printTag('status', $status);
    
    my ($plistcrc, $execrc) = $signature =~ /\?\s([0-9a-f]+)\s([0-9a-f]+)/;
    
    if($plistcrc && $execrc)
      {
      printTag('signature', 'none');
      printTag('plistcrc', $plistcrc);
      printTag('execrc', $execrc);
      }
    else
      {
      ($plistcrc) = $signature =~ /\Shell\sScript\s([0-9a-f]+)/;

      if($plistcrc)
        {
        printTag('signature', 'shellscript');
        printTag('plistcrc', $plistcrc);
        }
      else
        {
        printTag('signature', $signature);
        printTag('plistcrc', $plistcrc);
        }
      }

    printTag('installdate', $date);
    popTag('task');    
    }
  }

# Process user login items.
sub processUserLoginItems
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process internet plug-ins.
sub processInternetPlugIns
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process user internet plug-ins.
sub processUserInternetPlugIns
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process Safari extensions.
sub processSafariExtensions
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process 3rd party preference panes.
sub process3rdPartyPreferencePanes
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process Time Machine.
sub processTimeMachine
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process top processes by CPU.
sub processTopProcessesByCPU
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process top processes by memory.
sub processTopProcessesByMemory
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process top processes by network.
sub processTopProcessesByNetwork
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process top processes by energy.
sub processTopProcessesByEnergy
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process virtual memory information.
sub processVirtualMemoryInformation
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process software installs.
sub processSoftwareInstalls
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Process diagnostics information.
sub processDiagnosticsInformation
  {
  if($line =~ //)
    {
    }
  elsif($line =~ //)
    {
    }
  }

# Make a section name into an XML tag.
sub sectionTag
  {
  my $name = lc shift;

  $name =~ s/\s/_/g;
  $name =~ s/-//g;

  return $name;
  }

# Push a new tag.
sub pushTag
  {
  my $tag = shift;

  my $indent = '  ' x scalar(@tags);

  print "$indent<$tag>\n";

  push @tags, $tag;
  }

# Get the current tag.
sub currentTag
  {
  return $tags[$#tags];
  }

# Print a one-line tag with value.
sub printTag
  {
  my $tag = shift;
  my $value = shift;

  my $indent = '  ' x scalar(@tags);

  print "$indent<$tag>$value</$tag>\n";
  }

# Pop a specific tag, popping all intermediate tags to get there.
sub popTag
  {
  my $tag = shift;

  my $foundTag = '';

  while(1)
    {
    $foundTag = pop @tags;

    my $indent = '  ' x scalar(@tags);

    print "$indent</$foundTag>\n";

    die "Failed to find tag $tag\n"
      if not defined $foundTag;

    last 
      if $foundTag eq $tag;
    }
  }

# Show a usage message.
sub usage
  {
  return << 'EOS';
Usage: reverse.pl  [options...]
  where [options...] are:
    --help = Show this help message

Example usage: pbpaste | perl reverse.pl
EOS
  }
