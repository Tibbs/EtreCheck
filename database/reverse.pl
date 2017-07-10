#!/usr/bin/perl

# Reverse an EtreCheck report into a machine readable format.

use strict;

use Getopt::Long;
use POSIX qw(floor);

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

# Time Machine is messy.
my $volumesBeingBackedUp = 0;
my $destinations = 0;

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
  if($line =~ /^\s+(\S.+\S)\s+(\S+)\s\((\S.+\S)\s-\sinstalled\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $type = $2;
    my $signature = $3;
    my $installdate = $4;

    popTag('loginitem')
      if currentTag() eq 'loginitem';

    pushTag('loginitem');
    printTag('name', $name);
    printTag('type', $type);
    printTag('signature', $signature);
    printTag('installdate', $installdate);
    }
  else
    {
    $line =~ /^\s+\((.+)\)/;
  
    my $path = $1;

    printTag('path', $path)  
      if $path;
    }
  }

# Process internet plug-ins.
sub processInternetPlugIns
  {
  processPlugInLine();
  }

# Process user internet plug-ins.
sub processUserInternetPlugIns
  {
  processPlugInLine();
  }

# Process a plug in line.
sub processPlugInLine
  {
  if($line =~ /^\s+(\S.+\S)\s*:\s+(\S.+\S)\s+\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $version = $2;
    my $installdate = $3;

    pushTag('plugin');
    printTag('name', $name);
    printTag('version', $version);
    printTag('installdate', $installdate);
    popTag('plugin');
    }
  }

# Process Safari extensions.
sub processSafariExtensions
  {
  if($line =~ /^\s+\[(.+)\]\s+(\S.+\S)\s-\s(\S.+\S)\s-\s(\S+)\s\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $status = $1;
    my $name = $2;
    my $developer = $3;
    my $url = $4;
    my $installdate = $5;

    pushTag('extension');
    printTag('name', $name);
    printTag('status', $status);
    printTag('developer', $developer);
    printTag('url', $url);
    printTag('installdate', $installdate);
    popTag('extension');
    }
  }

# Process 3rd party preference panes.
sub process3rdPartyPreferencePanes
  {
  if($line =~ /^\s+(\S.+\S)\s+\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $installdate = $2;

    pushTag('preferencepane');
    printTag('name', $name);
    printTag('installdate', $installdate);
    popTag('preferencepane');
    }
  }

# Process Time Machine.
sub processTimeMachine
  {
  if($line =~ /^\s+Skip\sSystem\sFiles:\s(\S+)/)
    {
    my $skipSystemFiles = $1;

    printTag('skipsystemfiles', $skipSystemFiles);
    }
  elsif($line =~ /^\s+Mobile\sbackups:\s(\S+)/)
    {
    my $mobileBacksups = $1;

    printTag('mobilebackups', $mobileBacksups);
    }
  elsif($line =~ /^\s+Auto\sbackup:\s(\S+)/)
    {
    my $autoBackup = $1;

    printTag('autobackup', $autoBackup);
    }
  elsif($line =~ /^\s+Volumes\sbeing\sbacked\sup:/)
    {
    pushTag('volumesbeingbackedup');

    $volumesBeingBackedUp = 1;
    }
  elsif($line =~ /^\s+Destinations:/)
    {
    popTag('volumesbeingbackedup');
    pushTag('destinations');

    $volumesBeingBackedUp = 0;
    $destinations = 1;
    }
  elsif($volumesBeingBackedUp)
    {
    $line =~ /^\s+(\S.+\S):\sDisk\ssize:\s([0-9.]+)\s(GB|TB)\sDisk\sused:\s([0-9.]+)\s(GB|TB)/;

    my $name = $1;
    my $size = $2 * 1024 * 1024 * 1024;
    my $sizeUnits = $3;
    my $used = $4 * 1024 * 1024 * 1024;
    my $usedUnits = $5;

    $size *= 1024
      if $sizeUnits eq 'TB';

    $used *= 1024
      if $usedUnits eq 'TB';

    pushTag('volume');
    printTag('name', $name);
    printTag('size', $size);
    printTag('used', $used);
    popTag('volume');
    }
  elsif($destinations)
    {
    if($line =~ /^\s+Total\ssize:\s([0-9.]+)\s(GB|TB)/)
      {
      my $size = $1 * 1024 * 1024 * 1024;
      my $sizeUnits = $2;

      $size *= 1024
        if $sizeUnits eq 'TB';

      printTag('size', $size);
      }
    elsif($line =~ /^\s+Total\snumber\sof\sbackups:\s(\d+)/)
      {
      my $count = $1;

      printTag('count', $count);
      }
    elsif($line =~ /^\s+Oldest\sbackup:\s(\S.+\S)/)
      {
      my $oldestBackup = $1;

      printTag('oldestbackup', $oldestBackup);
      }
    elsif($line =~ /^\s+Last\sbackup:\s(\S.+\S)/)
      {
      my $lastBackup = $1;

      printTag('lastbackup', $lastBackup);
      }
    elsif($line =~ /^\s+Size\sof\sbackup\sdisk:\s\S+/)
      {
      }
    elsif($line =~ /^\s+Backup\ssize\s.+/)
      {
      }
    elsif($line)
      {
      $line =~ /^\s+(\S.+\S)\s\[(\S+)\]/;

      my $name = $1;
      my $type = $2;

      pushTag('destination');
      printTag('name', $name);
      printTag('type', $type);
      }
    else
      {
      popTag('destination');
      }
    }
  }

# Process top processes by CPU.
sub processTopProcessesByCPU
  {
  if($line =~ /^\s+(\d+%)\s+(.+)$/)
    {
    my $pct = $1;
    my $process = $2;

    pushTag('process');
    printTag('cpupct', $pct);
    printTag('name', $process);
    popTag('process');
    }
  }

# Process top processes by memory.
sub processTopProcessesByMemory
  {
  if($line =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)\s+(.+)$/)
    {
    my $size = $1;
    my $sizeUnits = $2;
    my $process = $3;

    $size *= 1024
      if $sizeUnits eq 'KB';

    $size *= 1024 * 1024
      if $sizeUnits eq 'MB';

    $size *= 1024 * 1024 * 1024
      if $sizeUnits eq 'GB';

    pushTag('process');
    printTag('size', $size);
    printTag('name', $process);
    popTag('process');
    }
  }

# Process top processes by network.
sub processTopProcessesByNetwork
  {
  if($line =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)\s+([0-9.]+)\s(B|KB|MB|GB)\s+(.+)$/)
    {
    my $inputSize = $1;
    my $inputSizeUnits = $2;
    my $outputSize = $3;
    my $outputSizeUnits = $4;
    my $process = $5;

    $inputSize *= 1024
      if $inputSizeUnits eq 'KB';

    $inputSize *= 1024 * 1024
      if $inputSizeUnits eq 'MB';

    $inputSize *= 1024 * 1024 * 1024
      if $inputSizeUnits eq 'GB';

    $outputSize *= 1024
      if $outputSizeUnits eq 'KB';

    $outputSize *= 1024 * 1024
      if $outputSizeUnits eq 'MB';

    $outputSize *= 1024 * 1024 * 1024
      if $outputSizeUnits eq 'GB';

    pushTag('process');
    printTag('inputsize', $inputSize);
    printTag('outputsize', $outputSize);
    printTag('name', $process);
    popTag('process');
    }
  }

# Process top processes by energy.
sub processTopProcessesByEnergy
  {
  if($line =~ /^\s+([0-9.]+)\s+(.+)$/)
    {
    my $amount = $1;
    my $process = $2;

    pushTag('process');
    printTag('amount', $amount);
    printTag('name', $process);
    popTag('process');
    }
  }

# Process virtual memory information.
sub processVirtualMemoryInformation
  {
  my $size;
  my $sizeUnits;
  my $type;

  if($line =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)/)
    {
    $size = $1;
    $sizeUnits = $2;
    }

  if($line =~ /Available\sRAM/)
    {
    $type = 'availableram';
    }
  elsif($line =~ /Free\sRAM/)
    {
    $type = 'freeram';
    }
  elsif($line =~ /Used\sRAM/)
    {
    $type = 'usedram';
    }
  elsif($line =~ /Cached\sfiles/)
    {
    $type = 'cachedfiles';
    }
  elsif($line =~ /Swap\sUsed/)
    {
    $type = 'swapused';
    }
  else
    {
    return;
    }

  $size *= 1024
    if $sizeUnits eq 'KB';

  $size *= 1024 * 1024
    if $sizeUnits eq 'MB';

  $size *= 1024 * 1024 * 1024
    if $sizeUnits eq 'GB';

  printTag($type, floor($size));
  }

# Process software installs.
sub processSoftwareInstalls
  {
  if($line =~ /^\s+(\S.+\S):\s(.*)\s\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $version = $2;
    my $installdate = $3;

    pushTag('package');
    printTag('name', $name);

    printTag('version', $version)
      if $version;

    printTag('installdate', $installdate);
    popTag('package');
    }
  }

# Process diagnostics information.
sub processDiagnosticsInformation
  {
  if($line =~ /^\s+(\d{4}-\d\d-\d\d\s\d\d:\d\d:\d\d)\s+(\S.+\S)\s(Crash|High\sCPU\suse|Hang|Panic)/)
    {
    my $date = $1;
    my $app = $2;
    my $type = $3;

    popTag('cause')
      if currentTag() eq 'cause';

    popTag('event')
      if currentTag() eq 'event';

    pushTag('event');
    printTag('date', $date);
    printTag('type', $type);
    printTag('app', $app);
    }
  elsif($line =~ /^\s+(\d{4}-\d\d-\d\d\s\d\d:\d\d:\d\d)\s+Last\sshutdown\scause:\s(\d+)\s-\s(.+)/)
    {
    my $date = $1;
    my $type = 'lastshutdown';
    my $code = $2;
    my $description = $3;

    popTag('cause')
      if currentTag() eq 'cause';

    popTag('event')
      if currentTag() eq 'event';

    pushTag('event');
    printTag('date', $date);
    printTag('type', $type);
    printTag('code', $code);
    printTag('description', $description);
    popTag('event');
    }
  elsif($line =~ /^\s+Cause:\s+(.+)/)
    {
    my $text = $1;

    pushTag('cause');
    print "        $text\n";
    }
  elsif($line =~ /^\s+Standard\susers\scannot\sread\s\/Library\/Logs\/DiagnosticReports\./)
    {
    }
  elsif($line =~ /^\s+Run\sas\san\sadministrator\saccount\sto\ssee\smore\sinformation\./)
    {
    }
  elsif($line =~ /^\s+(\S.+\S)/)
    {
    my $text = $1;

    print "        $text\n";
    }
  else
    {
    popTag('cause')
      if currentTag() eq 'cause';

    popTag('event')
      if currentTag() eq 'event';
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
