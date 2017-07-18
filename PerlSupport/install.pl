#!/usr/bin/perl 

my $includeDir = '/Library/Perl/';

foreach my $dir (@INC)
  {
  my @parts = split('/', $dir);

  $includeDir .= $parts[3];

  last;
  }

system("find Capture -type d -exec mkdir -p $includeDir/{} \\; -print");
system("find Capture -type f -exec cp {} $includeDir/{} \\; -print");
system("find darwin-thread-multi-2level -type d -exec mkdir -p $includeDir/{} \\; -print");
system("find darwin-thread-multi-2level -type f -exec cp {} $includeDir/{} \\; -print");

