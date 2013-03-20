use strict;
use warnings;
use Test::More tests => 19;
use Path::Class qw( file );
use Nightly::Bundle;
use Nightly::Tar::File;
use File::Temp qw( tempdir );

my $bundle = eval { Nightly::Bundle->new( root => tempdir( CLEANUP => 1 ) )};

isa_ok $bundle, 'Nightly::Bundle';

is $bundle->description, 'Pod Documentation', 'description';
is $bundle->author, 'Unknown', 'author';
is $bundle->favicon, 'http://perl.com/favicon.ico', 'favicon';
is $bundle->brand, 'Perl Documentation', 'brand';
isa_ok $bundle->root_url, 'URI';
isa_ok $bundle->root, 'Path::Class::Dir';
isa_ok $bundle->home_url, 'URI';

$bundle->add_dist(
  Nightly::Tar::File->new(
    file => file( __FILE__ )->parent->file(qw(tar Foo-Bar-0.01.tar.gz)),
  )->checkout
);

isa_ok $bundle->dists->{'Foo-Bar'}, 'Nightly::Dist';

$bundle->build_pod_list;

isa_ok $bundle->pods->{foo}, 'Nightly::Pod::File';
isa_ok $bundle->pods->{'Foo::Bar'}, 'Nightly::Pod::File';
isa_ok $bundle->pods->{'Foo::FAQ'}, 'Nightly::Pod::File';

$bundle->copy_support_files;

ok -r $bundle->root->file('css', 'bootstrap.css'), 'support files copied (at least some)';

$bundle->generate_index_html;

ok -d $bundle->root->subdir('Foo-Bar'), 'has Foo-Bar dir';
ok -r $bundle->root->file('Foo-Bar', 'index.html'), 'has Foo-Bar/index.html';
ok -r $bundle->root->file('index.html'), 'has index.html';

$bundle->generate_pod_html;

ok(-r $bundle->root->file('Foo-Bar', 'Foo::Bar.html'), 'has Foo-Bar/Foo::Bar.html');
ok(-r $bundle->root->file('Foo-Bar', 'Foo::FAQ.html'), 'has Foo-Bar/Foo::FAQ.html');
ok(-r $bundle->root->file('Foo-Bar', 'foo.html'), 'has Foo-Bar/foo.html');
