#!/usr/bin/perl

# Reverse an EtreCheck report into a machine readable format.

use strict;

use Getopt::Long;
use POSIX qw(floor);
use EtreCheck;

my $help;
my $force;

GetOptions(
  'help' => \$help,
  'force' => \$force
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
else
  {
  my $input = "/Users/jdaniel/Programming/Reports-EtreCheck/originals/$etrecheck->{id}.txt";

  open(IN, ">$input");

  print OUT $etrecheck->{input};

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

Example usage: pbpaste | perl reverse.pl
EOS
  }
