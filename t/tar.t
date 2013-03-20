use strict;
use warnings;
use Test::More tests => 30;
use Nightly::Tar::File;
use Path::Class qw( file dir );

require(file( __FILE__ )->parent->file('testlib.pl'));

my $tar = Nightly::Tar::File->new(
  file => file( __FILE__ )->parent->file(qw(tar Foo-Bar-0.01.tar.gz)),
);

isa_ok $tar, 'Nightly::Tar::File';
isa_ok $tar->file, 'Path::Class::File';
ok -r $tar->file, 'tar readable';

my $dist = eval { $tar->checkout };
diag $@ if $@;

isa_ok $dist, 'Nightly::Dist';
ok -d $dist->root, 'extracted root ' . $dist->root;
isa_ok $dist->root, 'Path::Class::Dir';

ok -r $dist->root->file(qw( lib Foo Bar.pm )), "exists: lib/Foo/Bar.pm";

ok((-r $dist->build_root->file(qw( Build.PL ))
||  -r $dist->build_root->file(qw( Makefile.PL ))), "build exists Build.PL or Makefile.PL");

my $meta = eval { $dist->build_meta };
isa_ok $meta, 'CPAN::Meta';
is $meta->abstract, 'Something Wicked', 'abstract = Something Wicked';
is $meta->name, 'Foo-Bar', 'name = Foo-Bar';

my %pods = map { $_->name => $_ } $dist->find_pods;

ok defined $pods{'foo'}, 'has script foo';
ok defined $pods{'Foo::Bar'}, 'has module Foo::Bar';
ok defined $pods{'Foo::FAQ'}, 'has pod Foo::FAQ';

isa_ok $pods{'foo'}->file, 'Path::Class::File';
isa_ok $pods{'Foo::Bar'}->file, 'Path::Class::File';
isa_ok $pods{'Foo::FAQ'}->file, 'Path::Class::File';

is($pods{foo}->type,        'pl',  'type = pl');
is($pods{'Foo::Bar'}->type, 'pm',  'type = pm');
is($pods{'Foo::FAQ'}->type, 'pod', 'type = pod');

isa_ok $pods{foo}->dist, 'Nightly::Dist';
isa_ok $pods{'Foo::Bar'}->dist, 'Nightly::Dist';
isa_ok $pods{'Foo::FAQ'}->dist, 'Nightly::Dist';

ok $dist->is_module_build, 'is Module::Build';
ok !$dist->is_make_maker, 'is NOT MakeMaker';
ok !$dist->is_dist_zilla, 'is NOT Dist::Zilla';
ok $dist->is_perl_dist, 'is a Perl Dist';

is $pods{foo}->abstract, 'foo script', 'foo abstract';
is $pods{'Foo::Bar'}->abstract, 'Something Wicked', 'foo abstract';
is $pods{'Foo::FAQ'}->abstract, 'a FAQ about Foo', 'foo abstract';
