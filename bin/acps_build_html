#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Nightly::Bundle;
use Nightly::Git;

# PODNAME: acps_build_html
# ABSTRACT: Build HTML for ACPS
# VERSION

my $bundle = Nightly::Bundle->new;

foreach my $repo (Nightly::Git->find_repos('/cm/git'))
{
  my $dist = $repo->checkout;
  next unless $dist->is_perl_dist;
  eval { $bundle->add_dist($dist) };
  if(my $error = $@)
  {
    say STDERR "ERROR " . $repo->root;
    say STDERR $@;
  }
}

$bundle->build_pod_list;
$bundle->copy_support_files;
$bundle->generate_index_html;
