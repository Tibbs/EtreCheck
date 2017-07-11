#!/usr/bin/perl

# Reverse an EtreCheck report into a machine readable format.

use strict;

use Getopt::Long;
use POSIX qw(floor);
use EtreCheck;

my $help;

GetOptions(
  'help' => \$help
  );

die usage()
  if $help;

my $etrecheck = new EtreCheck();

$etrecheck->reverse(\*STDIN);

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
