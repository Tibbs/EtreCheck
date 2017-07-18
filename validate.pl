#!/usr/bin/perl 

my ($version) = `sysctl kern.osversion`;
my ($code) = $version =~ /^kern.osversion:\s+(\d\d)/;
my $osversion = $code - 4;

$version = "10.$osversion";

system("./validateLaunchd.pl > launchd$version.xml");
system("./validateApps.pl > apps$version.xml");
