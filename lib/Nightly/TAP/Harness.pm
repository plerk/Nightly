package Nightly::TAP::Harness;

use strict;
use warnings;
use v5.10;
use base qw( TAP::Harness::Archive );

# ABSTRACT: Test Harness
# VERSION

sub new
{
  my($class, $args) = @_;
  my %args = %$args;
  $args{archive} = $ENV{NIGHTLY_HARNESS} // '/tmp/nightly.tar.gz';
  shift->SUPER::new(\%args);
}

1;
