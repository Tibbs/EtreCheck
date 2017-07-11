# A class understands a single EtreCheck section.
package EtreCheckTimeMachineSection;

use strict;
use Exporter;
use vars qw($VERSION);

use EtreCheckSection;

our $VERSION = 1.00;
our @ISA = qw(EtreCheckSection);

sub new
  {
  my $class = shift;

  my $self = $class->SUPER::new();

  # Time Machine is messy.
  $self->{volumesBeingBackedUp} = 0;
  $self->{destinations} = 0;

  bless $self, $class;

  return $self;
  }

1;
