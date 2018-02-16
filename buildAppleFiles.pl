#!/usr/bin/perl 

open(OUT, '>appleLaunchd.plist');
print OUT qq{<?xml version="1.0" encoding="UTF-8"?>\n};
print OUT qq{<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n};
print OUT qq{<plist version="1.0">\n};
print OUT qq{<dict>\n};
#print OUT launchdContents('launchd', '10.6');
#print OUT launchdContents('launchd', '10.7');
print OUT launchdContents('launchd', '10.8');
print OUT launchdContents('launchd', '10.9');
print OUT launchdContents('launchd', '10.10');
print OUT launchdContents('launchd', '10.11');
print OUT launchdContents('launchd', '10.12');
print OUT launchdContents('launchd', '10.13');
print OUT qq{</dict>\n};
print OUT qq{</plist>\n};
close(OUT);

open(OUT, '>appleSoftware.plist');
print OUT qq{<?xml version="1.0" encoding="UTF-8"?>\n};
print OUT qq{<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n};
print OUT qq{<plist version="1.0">\n};
print OUT qq{  <dict>\n};
#print OUT appContents('apps', '10.6');
#print OUT appContents('apps', '10.7');
print OUT appContents('apps', '10.8');
print OUT appContents('apps', '10.9');
print OUT appContents('apps', '10.10');
print OUT appContents('apps', '10.11');
print OUT appContents('apps', '10.12');
print OUT appContents('apps', '10.13');
print OUT qq{  </dict>\n};
print OUT qq{</plist>\n};
close(OUT);

sub launchdContents
  {
  my $type = shift;
  my $version = shift;

  local $/;

  open(IN, "$type$version.xml");

  my $data = <IN>;

  close(IN);

  return "\t<key>$version</key>\n\t<dict>\n$data\t</dict>\n";
  }

sub appContents
  {
  my $type = shift;
  my $version = shift;

  local $/;

  open(IN, "$type$version.xml");

  my $data = <IN>;

  close(IN);

  return "    <key>$version</key>\n    <dict>\n$data    </dict>\n";
  }
