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
  brand     => 'Plicease',
  root      => "/home/ollisg/web/sites/default/perl/",
  root_url  => "http://grunion.isc.wdlabs.com/perl",
  run_tests => 1,
);

$bundle->root->subdir('cpan')->mkpath(0,0755);

$bundle->add_dist(
  Nightly::Git::Repo->new( 
    root => dir(File::HomeDir->my_home, 'dev', $_)
  )->checkout
) foreach qw( Foo-Bar Baz );

$bundle->build_pod_list;
$bundle->copy_support_files;
$bundle->generate_index_html;
$bundle->generate_pod_html;
