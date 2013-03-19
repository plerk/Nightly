package Nightly;

use strict;
use warnings;
use v5.10;
use Path::Class::Dir;

# ABSTRACT: Tools for Continuous Integration Testing and Documentation
# VERSION

sub isa_dir
{
  state $attr = [
    isa      => sub {
      # TODO: how to report back to the caller?
      die "root must be a Path::Class::Dir or a string"
        unless eval { $_[0]->isa('Path::Class::Dir') }
    },
    coerce   => sub {
      return ref $_[0] ? $_[0] : Path::Class::Dir->new($_[0]);
    },
  ];

  return @$attr;
}

sub share_dir
{
  state $path;
  
  unless(defined $path)
  {
    $path = Path::Class::File
      ->new($INC{'Nightly.pm'})
      ->absolute
      ->dir
      ->parent
      ->subdir('share');
    
    $path = Path::Class::Dir->new(dist_dir('Nightly'))
      unless -d $path;
  }
  
  return $path;
}

1;
