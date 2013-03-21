package Nightly;

use strict;
use warnings;
use v5.10;
use Path::Class::Dir;
use Path::Class::File;
use File::ShareDir qw( dist_dir );
use Archive::Tar;
use File::Temp qw( tempdir );
use URI;

# ABSTRACT: Tools for Continuous Integration Testing and Documentation
# VERSION

sub isa_dir
{
  state $attr = [
    isa      => sub {
      # TODO: how to report back to the caller?
      die "must be a Path::Class::Dir or a string"
        unless eval { $_[0]->isa('Path::Class::Dir') }
    },
    coerce   => sub {
      return ref $_[0] ? $_[0] : Path::Class::Dir->new($_[0]);
    },
  ];

  return @$attr;
}

sub isa_file
{
  state $attr = [
    isa      => sub {
      # TODO: how to report back to the caller?
      die "must be a Path::Class::Dir or a string"
        unless eval { $_[0]->isa('Path::Class::File') }
    },
    coerce   => sub {
      return ref $_[0] ? $_[0] : Path::Class::File->new($_[0]);
    },
  ];

  return @$attr;
}

sub isa_uri
{
  state $attr = [
    isa      => sub {
      # TODO: how to report back to the caller?
      die "must be a URI or a string"
        unless eval { $_[0]->isa('URI') }
    },
    coerce   => sub {
      return ref $_[0] ? $_[0] : URI->new($_[0]);
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
      unless -r $path->file('Nightly.txt');
  }
  
  return $path;
}

sub extract_tar
{
  my($class, $tar_fn, $root) = @_;
  
  $root //= Path::Class::Dir->new( tempdir( CLEANUP => 1) );
  $root = Path::Class::Dir->new($root) unless ref $root;
  
  my $tar = Archive::Tar->new;
  $tar->read($tar_fn);
  foreach my $fn ($tar->list_files)
  {
    if($fn =~ m{/$})
    {
      $root->subdir( $fn )->mkpath(0, 0700);
    }
    else
    {
      my $dest_fn = $fn;
      $dest_fn =~ s{^.*?/}{};
      $tar->extract_file($fn, $root->file( $dest_fn )->stringify );
    }
  }
  
  return $root;
}

1;
