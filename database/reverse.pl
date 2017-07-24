#!/usr/bin/perl

# Reverse an EtreCheck report into a machine readable format.

use strict;

use Getopt::Long;
use POSIX qw(floor);
use EtreCheck;

my $help;
my $force;
my $debug;

GetOptions(
  'help' => \$help,
  'force' => \$force,
  'debug' => \$debug
  );

die usage()
  if $help;

my $etrecheck = new EtreCheck();

eval
  {
  $etrecheck->reverse(\*STDIN);
  };

if($@)
  {
  print "$etrecheck->{output}\n$@\n";
  }
elsif($debug)
  {
  print $etrecheck->{output};
  }
else
  {
  my $input = "/Users/jdaniel/Programming/Reports-EtreCheck/originals/$etrecheck->{id}.txt";

  open(IN, ">$input");

  print IN $etrecheck->{input};

  close(IN);

  my $output = "/Users/jdaniel/Programming/Reports-EtreCheck/$etrecheck->{id}.xml";

  die "$output exists\n"
    if -f $output and not $force;

  open(OUT, ">$output");

  print OUT $etrecheck->{output};

  close(OUT);

  print "$output\n";
  }

# Show a usage message.
sub usage
  {
  return << 'EOS';
Usage: reverse.pl  [options...]
  where [options...] are:
    --help = Show this help message
    --debug = Dump to STDOUT

Example usage: pbpaste | perl reverse.pl
EOS
  }
