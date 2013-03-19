package Nightly::Git::Repo;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use Path::Class::Dir;
use Carp qw( croak );
use File::Temp qw( tempdir );
use Git::Wrapper;
use Nightly;
use Nightly::Dist;

# ABSTRACT: Git Repo class
# VERSION

has root => (
  is       => 'ro',
  required => 1,
  Nightly->isa_dir,
);

sub checkout
{
  my($self, $dest) = @_;
  $dest = Path::Class::Dir->new( tempdir( CLEANUP => 1 ) )
    unless defined $dest;
  $dest = dir( $dest ) unless ref $dest;
  Git::Wrapper->new( $self->root )->clone( $self->root, $dest );
  Nightly::Dist->new( root => $dest );
}

1;
