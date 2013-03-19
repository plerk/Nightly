use strict;
use warnings;
use v5.10;
use Test::More tests => 14*3;
use Path::Class qw( file );
use Nightly::Git::Repo;

require(file( __FILE__ )->parent->file('testlib.pl'));

foreach my $name (sort qw( build-git dz-git make-git ))
{
  my $repo_root = extract_tar("$name.tar.gz");
  $DB::single = 1;

  my $repo = Nightly::Git::Repo->new(
    root => $repo_root->subdir('Foo-Bar'),
  );

  isa_ok $repo, 'Nightly::Git::Repo';
  ok -d $repo->root, "root exists: " . $repo->root;
  isa_ok $repo->root, 'Path::Class::Dir';

  $repo = Nightly::Git::Repo->new(
    root => $repo_root->subdir('Foo-Bar')->stringify,
  );

  isa_ok $repo, 'Nightly::Git::Repo';
  ok -d $repo->root, "root exists: " . $repo->root;
  isa_ok $repo->root, 'Path::Class::Dir';

  my $dist = eval { $repo->checkout };
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
}
