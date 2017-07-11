# A class that can reverse an EtreCheck report.
package EtreCheck;

use strict;
use Exporter;
use vars qw($VERSION);

use POSIX qw(floor);

use EtreCheckSection;

our $VERSION = 1.00;

our %sections =
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

sub new
  {
  my $class = shift;

  my $self = 
    {
    line => undef,
    section => 'Header',
    currentSection => undef,
    index => 0,
    tags => []
    };

  bless $self, $class;

  return $self;
  }

sub reverse
  {
  my $self = shift;

  my $fh = shift;

  $self->pushTag('etrecheck');
  $self->pushTag('header');

  while($self->{line} = <$fh>)
    {
    chomp $self->{line};

    $self->processLine();
    }

  $self->popTag('etrecheck');
  }

# Process a single line according to the current section.
sub processLine
  {
  my $self = shift;

  # Check for a new section.
  if($self->{line} =~ /^([^:]+):\sⓘ$/)
    {
    # Close the current section. The header section is special.
    my $name = $self->sectionTag($self->{section});

    $self->popTag($name);

    # Start a new section.
    $self->{section} = $1;
    $self->{index} = 0;
    
    $name = $self->sectionTag($self->{section});

    $self->pushTag($name);

    $self->{currentSection} = new EtreCheckSection();

    return;
    }
  
  ++$self->{index};

  # Process the current section.
  $sections{$self->{section}}($self);
  }

# Process the header section.
sub processHeader
  {
  my $self = shift;

  if($self->{line} =~ /^EtreCheck\sversion:\s(.+)\s\((.+)\)$/)
    {
    my $version = $1;
    my $build =$2;

    $self->printTag('version', $version);
    $self->printTag('build', $build);
    }
  elsif($self->{line} =~ /^Report\sgenerated\s(.+)$/)
    {
    my $date = $1;

    $self->printTag('date', $date);
    }
  elsif($self->{line} =~ /^Runtime:\s(.+)$/)
    {
    my $runtime = $1;

    $self->printTag('runtime', $runtime);
    }
  elsif($self->{line} =~ /^Performance:\s(.+)$/)
    {
    my $performance = $1;

    $self->printTag('performance', $performance);
    }
  elsif($self->{line} =~ /^Problem:\s(.+)$/)
    {
    my $problem = $1;

    $self->printTag('problem', $problem);
    }
  }

# Process hardware information.
sub processHardwareInformation
  {
  my $self = shift;

  if($self->{index} == 1)
    {
    my ($marketingName) = $self->{line} =~ /^\s+(\S.+\S)\s*$/;

    $self->printTag('marketing_name', $marketingName);
    }
  elsif($self->{index} == 3)
    {
    my ($modelName, $modelCode) = $self->{line} =~ /^\s+(.+)\s-\smodel:\s(.+)$/;

    $self->printTag('modelname', $modelName);
    $self->printTag('modelcode', $modelCode);
    }
  elsif($self->{index} == 4)
    {
    my ($cpuCount, $speed, $chipName, $chipCode, $coreCount) = 
      $self->{line} =~ /^\s+(\d+)\s(.+\sGHz)\s(.+)\s\((.+)\)\sCPU:\s(\d+)-core/;

    $self->printTag('cpucount', $cpuCount);
    $self->printTag('speed', $speed);
    $self->printTag('chipname', $chipName);
    $self->printTag('chipcode', $chipCode);
    $self->printTag('corecount', $coreCount);
    }
  elsif($self->{index} == 5)
    {
    my ($RAM, $upgradeable) = 
      $self->{line} =~ /^\s+(\d+)\sGB\sRAM\s(Not\supgradeable|Upgradeable)/;

    $self->printTag('ram', $RAM);
    $self->printTag('upgradeable', $upgradeable);
    }
  elsif($self->{line} =~ /^\s+Battery:\sHealth\s=\s(.+)\s-\sCycle\scount\s=\s(\d+)/)
    {
    my $batteryHealth = $1;
    my $batteryCycleCount = $2;

    $self->printTag('batteryhealth', $batteryHealth);
    $self->printTag('batterycyclecount', $batteryCycleCount);
    }
  }

# Process video information.
sub processVideoInformation
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(.+)\s-\sVRAM:\s(.+)\s(?:MB|GB)/)
    {
    my $gpu = $1;
    my $VRAM = $2;

    $self->popTag('displays')
      if $self->currentTag() eq 'displays';

    $self->popTag('gpu')
      if $self->currentTag() eq 'gpu';

    $self->pushTag('gpu');
    $self->printTag('name', $gpu);
    $self->printTag('vram', $VRAM);
    }
  elsif($self->{line} =~ /^\s+(\S.+\S)\s*$/)
    {
    my $display = $1;

    $self->pushTag('displays')
      if $self->currentTag() ne 'displays';

    $self->printTag('display', $display);
    }
  }

# Process disk information.
sub processDiskInformation
  {
  my $self = shift;

  if($self->printDisk())
    {
    }
  elsif($self->printPartition())
    {
    }
  }

# Print a disk.
sub printDisk
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s(disk.+):\s\(([\d.]+)\s(..)\)\s\((Solid\sState|Rotational).*\)/)
    {
    my $diskModel = $1;
    my $device = $2;
    my $size = $3 * 1024 * 1024;
    my $sizeUnits = $4;
    my $type = $5;

    $size *= 1024
      if $sizeUnits eq 'GB';

    $size *= 1024
      if $sizeUnits eq 'TB';

    $self->popTag('partitions')
      if $self->currentTag() eq 'partitions';

    $self->popTag('disk')
      if $self->currentTag() eq 'disk';
    
    $self->pushTag('disk');
    $self->printTag('model', $diskModel);
    $self->printTag('device', $device);
    $self->printTag('size', floor($size));

    $self->printTag('type', $type)
      if $type;

    return 1;
    }

  return 0;
  }

# Print a partition.
sub printPartition
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(?:(\S.+\S)\s)?\((disk\S+)(?:\s-\s(\S.+\S))?\)\s(\S.+\S)\s+(?:\[(.+)\])?:\s([\d.]+)\s(..)/)
    {
    my $name = $1;
    my $device = $2;
    my $fileSystem = $3;
    my $mountPoint = $4;
    my $type = $5;
    my $size = $6 * 1024 * 1024;
    my $sizeUnits = $7; 

    $size *= 1024
      if $sizeUnits eq 'GB';

    $size *= 1024
      if $sizeUnits eq 'TB';

    $self->pushTag('partitions')
      if $self->currentTag() eq 'disk';
    
    $self->pushTag('partition');

    $self->printTag('name', $name)
      if $name;

    $self->printTag('device', $device);
    $self->printTag('filesystem', $fileSystem);
    $self->printTag('size', floor($size));

    $self->printTag('type', $type)
      if $type;

    $self->printTag('mountpoint', $mountPoint)
      if $mountPoint ne '<not mounted>';

    $self->popTag('partition');

    return 1;
    }

  return 0;
  }

# Process USB information.
sub processUSBInformation
  {
  my $self = shift;

  if($self->printDisk())
    {
    }
  elsif($self->printPartition())
    {
    }
  elsif($self->{line} =~ /^(\s+)(\S.+\S)\s*$/)
    {
    my $indent = length($1) / 2;
    my $name = $2;

    if($self->{currentSection}->{indent} < $indent)
      {
      $self->pushTag('node');
      $self->printTag('name', $name);
      }
    elsif($self->{currentSection}->{indent} > $indent)
      {
      $self->popTag('node');
      }

    $self->{currentSection}->{indent} = $indent;
    }
  }

# Process FireWire information.
sub processFireWireInformation
  {
  my $self = shift;

  if($self->printDisk())
    {
    }
  elsif($self->printPartition())
    {
    }
  elsif($self->{line} =~ /^(\s+)(\S.+\S)\s*$/)
    {
    my $indent = scalar($1) / 2;
    my $name = $2;

    if($self->{currentSection}->{indent} < $indent)
      {
      $self->pushTag('node');
      $self->printTag('name', $name);
      }
    elsif($self->{currentSection}->{indent} > $indent)
      {
      $self->popTag('node');
      }

    $self->{currentSection}->{indent} = $indent;
    }
  }

# Process Thunderbolt information.
sub processThunderboltInformation
  {
  my $self = shift;

  if($self->printDisk())
    {
    }
  elsif($self->printPartition())
    {
    }
  elsif($self->{line} =~ /^(\s+)(\S.+\S)\s*$/)
    {
    my $indent = scalar($1) / 2;
    my $name = $2;

    if($self->{currentSection}->{indent} < $indent)
      {
      $self->pushTag('node');
      $self->printTag('name', $name);
      }
    elsif($self->{currentSection}->{indent} > $indent)
      {
      $self->popTag('node');
      }

    $self->{currentSection}->{indent} = $indent;
    }
  }

# Process virtual disk information.
sub processVirtualDiskInformation
  {
  my $self = shift;

  if($self->{line} =~ /\s+(\S.+\S)\s\((disk.+)\s-\s([^)]+)\)\s(\S(?:.+\S)?)\s+(?:\[(Startup|Recovery|EFI|KernelCoreDump)\])?:\s([\d.]+)\s(..)\s\(([\d.]+)\s(..)\sfree.*\)/)
    {
    my $diskName = $1;
    my $device = $2;
    my $fileSystem = $3;
    my $mountPoint = $4;
    my $type = $5;
    my $size = $6 * 1024 * 1024;
    my $sizeUnits = $7;
    my $free = $8 * 1024 * 1024;
    my $freeUnits = $9;

    $size *= 1024
      if $sizeUnits eq 'GB';

    $size *= 1024
      if $sizeUnits eq 'TB';

    $free *= 1024
      if $freeUnits eq 'GB';

    $free *= 1024
      if $freeUnits eq 'TB';

    $self->popTag('disk')
      if $self->currentTag() eq 'disk';

    $self->pushTag('disk');
    $self->printTag('name', $diskName);
    $self->printTag('device', $device);
    $self->printTag('filesystem', $fileSystem);
    $self->printTag('mountpoint', $mountPoint);

    $self->printTag('type', $type)
      if $type;

    $self->printTag('size', floor($size));
    $self->printTag('free', floor($free));
    }
  elsif($self->{line} =~ /^\s+Encrypted\sAES-XTS\s(.+)/)
    {
    my $status = $1;

    $self->pushTag('encryption');
    $self->printTag('encrypted', 'true');
    $self->printTag('method', 'AES-XTS');
    $self->printTag('status', $status);
    $self->popTag('encryption');
    }
  elsif($self->{line} =~ /^\s+Physical\sdisk:\s(\S.+\S)\s([\d.]+)\s(..)(?:\s\(([\d.]+)\s(..)\sfree\))?(?:\s(.+))?/)
    {
    my $name = $1;
    my $size = $2 * 1024 * 1024;
    my $sizeUnits = $3;
    my $free = $4 * 1024 * 1024;
    my $freeUnits = $5;
    my $status = $6;

    $size *= 1024
      if $sizeUnits eq 'GB';

    $size *= 1024
      if $sizeUnits eq 'TB';

    $free *= 1024
      if $freeUnits eq 'GB';

    $free *= 1024
      if $freeUnits eq 'TB';

    $self->pushTag('physicaldisk');
    $self->printTag('name', $name);
    $self->printTag('size', $size);

    $self->printTag('free', $free)
      if $free;
    
    $self->printTag('status', $status)
      if $status;

    $self->popTag('physicaldisk');
    }
  }

# Process system software.
sub processSystemSoftware
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s+(10\.\d+.\d+)\s\((.+)\)\s-\sTime\ssince\sboot:\s(\S.+\S)\s*$/)
    {
    my $osname = $1;
    my $version = $2;
    my $build = $3;
    my $uptime = $4;

    $self->printTag('name', $osname);
    $self->printTag('version', $version);
    $self->printTag('build', $build);
    $self->printTag('uptime', $uptime);
    }
  }

# Process configuration files.
sub processConfigurationFiles
  {
  my $self = shift;

  if($self->{line} =~ /^\s+\/etc\/hosts\s-\sCount:\s(\d+)$/)
    {
    my $hosts = $1;

    $self->printTag('hostcounts', $hosts);
    }
  }

# Process Gatekeeper information.
sub processGatekeeperInformation
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s*$/)
    {
    my $gatekeeper = $1;

    $self->printTag('gatekeeper', $gatekeeper);
    }
  }

# Process kernel information.
sub processKernelInformation
  {
  my $self = shift;

  if($self->{line} =~ /^\s+\[(\S+)\]\s+(.+)\s+\((\S+)\s-\sSDK\s(\S+)\)/)
    {
    my $status = $1;
    my $bundleID = $2;
    my $version = $3;
    my $SDKVersion = $4;

    $self->pushTag('extension');
    $self->printTag('bundleid', $bundleID);
    $self->printTag('status', $status);
    $self->printTag('version', $version);
    $self->printTag('sdkversion', $SDKVersion);
    $self->popTag('extension');
    }
  elsif($self->{line} =~ /^\s+(\S.+\S)\s*$/)
    {
    my $directory = $1;

    $self->popTag('directory')
      if $self->currentTag() eq 'directory';
    
    $self->pushTag('directory');
    $self->printTag('path', $directory);
    $self->pushTag('extensions');
    }
  }

# Process system launch agents.
sub processSystemLaunchAgents
  {
  my $self = shift;

  $self->processSystemLaunchdAgents('/System/Library/LaunchAgents/');
  }

# Process system launch daemons.
sub processSystemLaunchDaemons
  {
  my $self = shift;

  $self->processSystemLaunchdAgents('/System/Library/LaunchDaemons/');
  }

# Process system launchd tasks.
sub processSystemLaunchdAgents
  {
  my $self = shift;

  my $prefix = shift;

  if($self->{line} =~ /^\s+\[(.+)\]\s+(\d+)\sApple\stask/)
    {
    my $status = $1;
    my $count = $2;

    $self->pushTag('appletasks');
    $self->printTag('status', $status);
    $self->printTag('count', $count);
    $self->popTag('appletasks');    
    }
  else
    {
    $self->processLaunchdLine($prefix);
    }
  }

# Process launch agents.
sub processLaunchAgents
  {
  my $self = shift;

  $self->processLaunchdLine('/Library/LaunchAgents/');
  }

# Process launch daemons.
sub processLaunchDaemons
  {
  my $self = shift;

  $self->processLaunchdLine('/Library/LaunchDaemons/');
  }

# Process user launch agents.
sub processUserLaunchAgents
  {
  my $self = shift;

  $self->processLaunchdLine('~/Library/LaunchAgents/');
  }

# Process a launchd script line.
sub processLaunchdLine 
  {
  my $self = shift;

  my $prefix = shift;

  if($self->{line} =~ /^\s+\[(.+)\]\s+(\S.+\S)\s\((\S.+\S)\s-\sinstalled\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $status = $1;
    my $name = $2;
    my $signature = $3;
    my $date = $4;

    $self->pushTag('task');
    $self->printTag('path', "$prefix$name");
    $self->printTag('status', $status);
    
    my ($plistcrc, $execrc) = $signature =~ /\?\s([0-9a-f]+)\s([0-9a-f]+)/;
    
    if($plistcrc && $execrc)
      {
      $self->printTag('signature', 'none');
      $self->printTag('plistcrc', $plistcrc);
      $self->printTag('execrc', $execrc);
      }
    else
      {
      ($plistcrc) = $signature =~ /\Shell\sScript\s([0-9a-f]+)/;

      if($plistcrc)
        {
        $self->printTag('signature', 'shellscript');
        $self->printTag('plistcrc', $plistcrc);
        }
      else
        {
        $self->printTag('signature', $signature);
        $self->printTag('plistcrc', $plistcrc);
        }
      }

    $self->printTag('installdate', $date);
    $self->popTag('task');    
    }
  }

# Process user login items.
sub processUserLoginItems
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s+(\S+)\s\((\S.+\S)\s-\sinstalled\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $type = $2;
    my $signature = $3;
    my $installdate = $4;

    $self->popTag('loginitem')
      if $self->currentTag() eq 'loginitem';

    $self->pushTag('loginitem');
    $self->printTag('name', $name);
    $self->printTag('type', $type);
    $self->printTag('signature', $signature);
    $self->printTag('installdate', $installdate);
    }
  else
    {
    $self->{line} =~ /^\s+\((.+)\)/;
  
    my $path = $1;

    $self->printTag('path', $path)  
      if $path;
    }
  }

# Process internet plug-ins.
sub processInternetPlugIns
  {
  my $self = shift;

  $self->processPlugInLine();
  }

# Process user internet plug-ins.
sub processUserInternetPlugIns
  {
  my $self = shift;

  $self->processPlugInLine();
  }

# Process a plug in line.
sub processPlugInLine
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s*:\s+(\S.+\S)\s+\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $version = $2;
    my $installdate = $3;

    $self->pushTag('plugin');
    $self->printTag('name', $name);
    $self->printTag('version', $version);
    $self->printTag('installdate', $installdate);
    $self->popTag('plugin');
    }
  }

# Process Safari extensions.
sub processSafariExtensions
  {
  my $self = shift;

  if($self->{line} =~ /^\s+\[(.+)\]\s+(\S.+\S)\s-\s(\S.+\S)\s-\s(\S+)\s\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $status = $1;
    my $name = $2;
    my $developer = $3;
    my $url = $4;
    my $installdate = $5;

    $self->pushTag('extension');
    $self->printTag('name', $name);
    $self->printTag('status', $status);
    $self->printTag('developer', $developer);
    $self->printTag('url', $url);
    $self->printTag('installdate', $installdate);
    $self->popTag('extension');
    }
  }

# Process 3rd party preference panes.
sub process3rdPartyPreferencePanes
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S)\s+\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $installdate = $2;

    $self->pushTag('preferencepane');
    $self->printTag('name', $name);
    $self->printTag('installdate', $installdate);
    $self->popTag('preferencepane');
    }
  }

# Process Time Machine.
sub processTimeMachine
  {
  my $self = shift;

  if($self->{line} =~ /^\s+Skip\sSystem\sFiles:\s(\S+)/)
    {
    my $skipSystemFiles = $1;

    $self->printTag('skipsystemfiles', $skipSystemFiles);
    }
  elsif($self->{line} =~ /^\s+Mobile\sbackups:\s(\S+)/)
    {
    my $mobileBacksups = $1;

    $self->printTag('mobilebackups', $mobileBacksups);
    }
  elsif($self->{line} =~ /^\s+Auto\sbackup:\s(\S+)/)
    {
    my $autoBackup = $1;

    $self->printTag('autobackup', $autoBackup);
    }
  elsif($self->{line} =~ /^\s+Volumes\sbeing\sbacked\sup:/)
    {
    $self->pushTag('volumesbeingbackedup');

    $self->{currentSection}->{volumesBeingBackedUp} = 1;
    }
  elsif($self->{line} =~ /^\s+Destinations:/)
    {
    $self->popTag('volumesbeingbackedup');
    $self->pushTag('destinations');

    $self->{currentSection}->{volumesBeingBackedUp} = 0;
    $self->{currentSection}->{destinations} = 1;
    }
  elsif($self->{currentSection}->{volumesBeingBackedUp})
    {
    $self->{line} =~ /^\s+(\S.+\S):\sDisk\ssize:\s([0-9.]+)\s(GB|TB)\sDisk\sused:\s([0-9.]+)\s(GB|TB)/;

    my $name = $1;
    my $size = $2 * 1024 * 1024 * 1024;
    my $sizeUnits = $3;
    my $used = $4 * 1024 * 1024 * 1024;
    my $usedUnits = $5;

    $size *= 1024
      if $sizeUnits eq 'TB';

    $used *= 1024
      if $usedUnits eq 'TB';

    $self->pushTag('volume');
    $self->printTag('name', $name);
    $self->printTag('size', $size);
    $self->printTag('used', $used);
    $self->popTag('volume');
    }
  elsif($self->{currentSection}->{destinations})
    {
    if($self->{line} =~ /^\s+Total\ssize:\s([0-9.]+)\s(GB|TB)/)
      {
      my $size = $1 * 1024 * 1024 * 1024;
      my $sizeUnits = $2;

      $size *= 1024
        if $sizeUnits eq 'TB';

      $self->printTag('size', $size);
      }
    elsif($self->{line} =~ /^\s+Total\snumber\sof\sbackups:\s(\d+)/)
      {
      my $count = $1;

      $self->printTag('count', $count);
      }
    elsif($self->{line} =~ /^\s+Oldest\sbackup:\s(\S.+\S)/)
      {
      my $oldestBackup = $1;

      $self->printTag('oldestbackup', $oldestBackup);
      }
    elsif($self->{line} =~ /^\s+Last\sbackup:\s(\S.+\S)/)
      {
      my $lastBackup = $1;

      $self->printTag('lastbackup', $lastBackup);
      }
    elsif($self->{line} =~ /^\s+Size\sof\sbackup\sdisk:\s\S+/)
      {
      }
    elsif($self->{line} =~ /^\s+Backup\ssize\s.+/)
      {
      }
    elsif($self->{line})
      {
      $self->{line} =~ /^\s+(\S.+\S)\s\[(\S+)\]/;

      my $name = $1;
      my $type = $2;

      $self->pushTag('destination');
      $self->printTag('name', $name);
      $self->printTag('type', $type);
      }
    else
      {
      $self->popTag('destination');
      }
    }
  }

# Process top processes by CPU.
sub processTopProcessesByCPU
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\d+%)\s+(.+)$/)
    {
    my $pct = $1;
    my $process = $2;

    $self->pushTag('process');
    $self->printTag('cpupct', $pct);
    $self->printTag('name', $process);
    $self->popTag('process');
    }
  }

# Process top processes by memory.
sub processTopProcessesByMemory
  {
  my $self = shift;

  if($self->{line} =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)\s+(.+)$/)
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

    $self->pushTag('process');
    $self->printTag('size', $size);
    $self->printTag('name', $process);
    $self->popTag('process');
    }
  }

# Process top processes by network.
sub processTopProcessesByNetwork
  {
  my $self = shift;

  if($self->{line} =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)\s+([0-9.]+)\s(B|KB|MB|GB)\s+(.+)$/)
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

    $self->pushTag('process');
    $self->printTag('inputsize', $inputSize);
    $self->printTag('outputsize', $outputSize);
    $self->printTag('name', $process);
    $self->popTag('process');
    }
  }

# Process top processes by energy.
sub processTopProcessesByEnergy
  {
  my $self = shift;

  if($self->{line} =~ /^\s+([0-9.]+)\s+(.+)$/)
    {
    my $amount = $1;
    my $process = $2;

    $self->pushTag('process');
    $self->printTag('amount', $amount);
    $self->printTag('name', $process);
    $self->popTag('process');
    }
  }

# Process virtual memory information.
sub processVirtualMemoryInformation
  {
  my $self = shift;

  my $size;
  my $sizeUnits;
  my $type;

  if($self->{line} =~ /^\s+([0-9.]+)\s(B|KB|MB|GB)/)
    {
    $size = $1;
    $sizeUnits = $2;
    }

  if($self->{line} =~ /Available\sRAM/)
    {
    $type = 'availableram';
    }
  elsif($self->{line} =~ /Free\sRAM/)
    {
    $type = 'freeram';
    }
  elsif($self->{line} =~ /Used\sRAM/)
    {
    $type = 'usedram';
    }
  elsif($self->{line} =~ /Cached\sfiles/)
    {
    $type = 'cachedfiles';
    }
  elsif($self->{line} =~ /Swap\sUsed/)
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

  $self->printTag($type, floor($size));
  }

# Process software installs.
sub processSoftwareInstalls
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\S.+\S):\s(.*)\s\(installed\s(\d{4}-\d\d-\d\d)\)/)
    {
    my $name = $1;
    my $version = $2;
    my $installdate = $3;

    $self->pushTag('package');
    $self->printTag('name', $name);

    $self->printTag('version', $version)
      if $version;

    $self->printTag('installdate', $installdate);
    $self->popTag('package');
    }
  }

# Process diagnostics information.
sub processDiagnosticsInformation
  {
  my $self = shift;

  if($self->{line} =~ /^\s+(\d{4}-\d\d-\d\d\s\d\d:\d\d:\d\d)\s+(\S.+\S)\s(Crash|High\sCPU\suse|Hang|Panic)/)
    {
    my $date = $1;
    my $app = $2;
    my $type = $3;

    $self->popTag('cause')
      if $self->currentTag() eq 'cause';

    $self->popTag('event')
      if $self->currentTag() eq 'event';

    $self->pushTag('event');
    $self->printTag('date', $date);
    $self->printTag('type', $type);
    $self->printTag('app', $app);
    }
  elsif($self->{line} =~ /^\s+(\d{4}-\d\d-\d\d\s\d\d:\d\d:\d\d)\s+Last\sshutdown\scause:\s(\d+)\s-\s(.+)/)
    {
    my $date = $1;
    my $type = 'lastshutdown';
    my $code = $2;
    my $description = $3;

    $self->popTag('cause')
      if $self->currentTag() eq 'cause';

    $self->popTag('event')
      if $self->currentTag() eq 'event';

    $self->pushTag('event');
    $self->printTag('date', $date);
    $self->printTag('type', $type);
    $self->printTag('code', $code);
    $self->printTag('description', $description);
    $self->popTag('event');
    }
  elsif($self->{line} =~ /^\s+Cause:\s+(.+)/)
    {
    my $text = $1;

    $self->pushTag('cause');
    $self->printText($text);
    }
  elsif($self->{line} =~ /^\s+Standard\susers\scannot\sread\s\/Library\/Logs\/DiagnosticReports\./)
    {
    }
  elsif($self->{line} =~ /^\s+Run\sas\san\sadministrator\saccount\sto\ssee\smore\sinformation\./)
    {
    }
  elsif($self->{line} =~ /^\s+(\S.+\S)/)
    {
    my $text = $1;

    $self->printText($text);
    }
  else
    {
    $self->popTag('cause')
      if $self->currentTag() eq 'cause';

    $self->popTag('event')
      if $self->currentTag() eq 'event';
    }
  }

# Make a section name into an XML tag.
sub sectionTag
  {
  my $self = shift;

  my $name = lc shift;

  $name =~ s/\s/_/g;
  $name =~ s/-//g;

  return $name;
  }

# Push a new tag.
sub pushTag
  {
  my $self = shift;

  my $tag = shift;

  my $indent = '  ' x scalar(@{$self->{tags}});

  print "$indent<$tag>\n";

  push @{$self->{tags}}, $tag;
  }

# Get the current tag.
sub currentTag
  {
  my $self = shift;

  my $count = scalar(@{$self->{tags}}) - 1;

  return $self->{tags}->[$count];
  }

# Print a one-line tag with value.
sub printTag
  {
  my $self = shift;

  my $tag = shift;
  my $value = shift;

  my $indent = '  ' x scalar(@{$self->{tags}});

  print "$indent<$tag>$value</$tag>\n";
  }

# Print text.
sub printText
  {
  my $self = shift;

  my $text = shift;

  my $indent = '  ' x scalar(@{$self->{tags}});

  print "$indent$text\n";
  }

# Pop a specific tag, popping all intermediate tags to get there.
sub popTag
  {
  my $self = shift;

  my $tag = shift;

  my $foundTag = '';

  while(1)
    {
    $foundTag = pop @{$self->{tags}};

    my $indent = '  ' x scalar(@{$self->{tags}});

    print "$indent</$foundTag>\n";

    die "Failed to find tag $tag\n"
      if not defined $foundTag;

    last 
      if $foundTag eq $tag;
    }
  }

1;
