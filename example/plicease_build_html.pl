#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Nightly::Bundle;
use Nightly::Tar::File;
use Nightly::Git::Repo;
use Path::Class qw( dir file );
use File::HomeDir;

# PODNAME: plicease_build_html
# ABSTRACT: Build HTML for Plicease
# VERSION

my $bundle = Nightly::Bundle->new(
  brand    => 'Plicease',
  root     => "/home/ollisg/web/sites/default/perl/",
  root_url => "http://grunion.isc.wdlabs.com/perl",
);

$bundle->root->subdir('cpan')->mkpath(0,0755);
system "rsync", 
  '-av',
  '--delete',
  'cpan-rsync.perl.org::CPAN/authors/id/P/PL/PLICEASE/',
  $bundle->root->subdir('cpan');

foreach my $tar (map { Nightly::Tar::File->new( file => $_ ) }grep /\.tar.gz$/, $bundle->root->subdir('cpan')->children(no_hidden => 1))
{
  next if $tar->file =~ /\d+_\d+\.tar.gz$/;
  $bundle->add_dist($tar->checkout);
}

my $dev = dir(File::HomeDir->my_home, 'dev');
if(-d $dev)
{
  foreach my $child (sort { $a->basename cmp $b->basename } $dev->children(no_hidden => 1))
  {
    next if $child->basename eq 'File-Listing-Ftpcopy'
    ||      $child->basename eq 'App-RegexFileUtils'
    ||      $child->basename eq 'Color-XS'
    ||      $child->basename eq 'Shell-Guess';
    next if ! $child->is_dir || ! -d $child->subdir('.git');
    say $child->basename;
    my $repo = Nightly::Git::Repo->new( root => $child );
    my $dist = $repo->checkout;
    next unless $dist->is_perl_dist;
    $bundle->add_dist($dist);
  }
}

$bundle->build_pod_list;
$bundle->copy_support_files;
$bundle->generate_index_html;
$bundle->generate_pod_html;
