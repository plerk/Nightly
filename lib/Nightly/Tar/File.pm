package Nightly::Tar::File;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use File::Temp qw( tempdir );
use Nightly;
use Nightly::Dist;

# ABSTRACT: Tar file
# VERSION

has file => (
  is       => 'ro',
  required => 1,
  Nightly->isa_file,
);

sub checkout
{
  my($self, $dest) = @_;
  $dest = Path::Class::Dir->new( tempdir( CLEANUP => 1 ) )
    unless defined $dest;
  $dest = dir( $dest ) unless ref $dest;
  Nightly->extract_tar($self->file->stringify, $dest);
  Nightly::Dist->new( root => $dest );
}

1;
