#!/usr/bin/perl

use strict;

use Getopt::Long;
use XML::Parser::Expat;
use DBI;

my $connection;
my $user;
my $password;
my $help;

GetOptions(
  'db=s' => \$connection,
  'user=s' => \$user,
  'password=s' => \$password,
  'help' => \$help
  );

die usage()
  if $help;

my $db = DBI->connect($connection, $user, $password, { RaiseError => 1 });
 
my $insert = 
   $db->prepare(
     "INSERT INTO adware(category, name) VALUES (?, ?)");

my $prefix;

while(my $line = <>)
  {
  chomp $line;

  if($line eq 'System Launch Agents: ⓘ')
    {
    $prefix = '/System/Library/LaunchAgents/';
    }
  elsif($line eq 'System Launch Daemons: ⓘ')
    {
    $prefix = '/System/Library/LaunchDaemons/';
    }
  elsif($line eq 'Launch Agents: ⓘ')
    {
    $prefix = '/Library/LaunchAgents/';
    }
  elsif($line eq 'Launch Daemons: ⓘ')
    {
    $prefix = '/Library/LaunchDaemons/';
    }
  elsif($line eq 'User Launch Agents: ⓘ')
    {
    $prefix = '~/Library/LaunchAgents/';
    }
  elsif($line eq 'Internet Plug-ins: ⓘ')
    {
    $prefix = undef;
    }
  elsif($prefix)
    {
    my ($file) = $line =~ /^\s+\[.+\]\s+(.+)\s+✔︎/;

    if($file)
      {
      my $category = 'signed';

      if($file =~ /^com.adobe.ARMDCHelper./)
        {
        $category = 'signed_prefix';
        $file = 'com.adobe.ARMDCHelper.';
        }

      my $path = "$prefix$file";

      eval
        {
        $insert->execute($category, $path);
        };
      }
    }
  }

$db->disconnect;

sub usage
  {
  return << 'EOS';
Usage: parse.pl  [options...]
  where [options...] are:
    db = DBI database connection string
    user = Database user 
    password = Database password

Example usage: pbpaste | perl parse.pl --db=dbi:SQLite:adware.db
EOS
  }
