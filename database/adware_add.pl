#!/usr/bin/perl

use strict;

use Getopt::Long;
use DBI;
use File::Basename;

my $connection;
my $user;
my $password;

GetOptions(
  'db=s' => \$connection,
  'user=s' => \$user,
  'password=s' => \$password
  );

my $category = shift;
my $path = shift;

die usage()
  if not $category and not $path;

my $db = DBI->connect($connection, $user, $password, { RaiseError => 1 });

my $insert = 
  $db->prepare(
    "INSERT INTO adware(category, name) VALUES (?, ?)");

die "Category $category not found\n"
  if not verifyCategory($category);

$insert->execute($category, basename($path));

$db->disconnect;

sub verifyCategory
  {
  my $category = shift;

  my $select = $db->prepare("select distinct category from adware order by category") 
    or die "Can't prepare statement: $DBI::errstr";
 
  my $result = $select->execute
    or die "Can't execute statement: $DBI::errstr";
 
  my $rows = $select->fetchall_arrayref({});

  my %categories = map { $_->{category} => 1 } @{$rows};

  return $categories{$category};
  }

sub usage
  {
  return << 'EOS';
Usage: adware_add.pl [options...] <category> <path>
  where [options...] are:
    db = DBI database connection string
    user = Database user 
    password = Database password

  and <category> is one of:
    adwareextensions
    blacklist
    blacklist_match
    blacklist_suffix
    whitelist
    whitelist_prefix
    
  and <path> is the path to a file

Example usage: perl adware_add.pl --db=dbi:SQLite:adware.db blacklist /path/to/malware
EOS
  }
