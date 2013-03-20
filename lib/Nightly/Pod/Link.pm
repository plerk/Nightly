package Nightly::Pod::Link;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use Pod::Abstract;
use Nightly::HTML::Generator;

# ABSTRACT: Pod file
# VERSION

has name => (
  is       => 'ro',
  required => 1,
);

has abstract => (
  is       => 'ro',
  required => 1,
);

has filename => (
  is => 'ro',
  lazy => 1,
  default => sub {
    shift->name . '.html';
  },
);

1;

