package Nightly::ExternalLink;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use Nightly;

# ABSTRACT: External WWW Links
# VERSION

has name => (
  is       => 'ro',
  required => 1,
);

has url => (
  is       => 'ro',
  required => 1,
  Nightly->isa_uri,
);

1;
