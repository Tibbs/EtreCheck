#!/usr/bin/perl

use strict;

use Getopt::Long;
use DBI;
use File::Spec;

my $connection;
my $user;
my $password;

GetOptions(
  'db=s' => \$connection,
  'user=s' => \$user,
  'password=s' => \$password
  );

my $outputDir = shift;

die usage()
  if !-d $outputDir;

my $db = DBI->connect($connection, $user, $password, { RaiseError => 1 });

# Spit out the plist file.
run(
  $db, 
  ['adwareextensions', 'blacklist', 'blacklist_match', 'blacklist_suffix'],
  File::Spec->join($outputDir, 'adware.plist'));

run(
  $db, 
  ['whitelist', 'whitelist_prefix'],
  File::Spec->join($outputDir, 'whitelist.plist'));

$db->disconnect;

sub run
  {
  my $db = shift;
  my $categories = shift;
  my $output = shift;

  my $select = $db->prepare("select name from adware where category = ? order by name") 
    or die "Can't prepare statement: $DBI::errstr";

  open(OUT, ">$output")
    or die "Couldn't open $output for writing\n";

  print OUT qq{<?xml version="1.0" encoding="UTF-8"?>\n};
  print OUT qq{<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n};
  print OUT qq{<plist version="1.0">\n};
  print OUT qq{<dict>\n};

  foreach my $category (@{$categories})
    {
    print OUT "  <key>$category</key>\n";
    print OUT "  <array>\n";
    
    my $result = $select->execute($category)
      or die "Can't execute statement: $DBI::errstr";
 
    while(my $row = $select->fetchrow_hashref())
      {
      my $name = $row->{name};

      $name =~ s/&/&amp;/;

      print OUT "    <string>$name</string>\n";
      }

    print OUT "  </array>\n";
    }

  print OUT qq{</dict>\n};
  print OUT qq{</plist>\n};
  }

sub usage
  {
  return << 'EOS';
Usage: sql2plist.pl <DBI connection> [options...]
  where [options...] are:
    db = DBI database connection string
    user = Database user 
    password = Database password

Example usage: perl sql2plist.pl --db=dbi:SQLite:adware.db ../LibEtreCheck
EOS
  }
