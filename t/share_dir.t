use strict;
use warnings;
use Test::More tests => 2;
use Nightly;

isa_ok eval { Nightly->share_dir }, 'Path::Class::Dir';
diag $@ if $@;

ok -d Nightly->share_dir->stringify, "path = " . Nightly->share_dir->stringify;
