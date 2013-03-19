package Nightly::Dist;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use File::chdir;
use Dist::Zilla::App;
use File::Temp qw( tempdir );
use Path::Class::Dir;
use AnyEvent;
use AnyEvent::Open3::Simple;
use CPAN::Meta;
use Archive::Tar;
use Nightly;

# ABSTRACT: Checked or untared dist
# VERSION

has root => (
  is       => 'ro',
  required => 1,
  Nightly->isa_dir,
);

has build_root => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    local $CWD = $self->root->stringify;
    if(-e $self->root->file('dist.ini'))
    {
      my $build_root = Path::Class::Dir->new( tempdir( CLEANUP => 1 ) );
      $self->_run('dzil', 'build', '--in' => $build_root);      
      return $build_root;
    }
    elsif(-e $self->root->file('Build.PL'))
    {
      $self->_run($^X, 'Build.PL');
      $self->_run($^X, 'Build', 'dist');
      return $self->_extract_tar($self->_find_tar($self->root));
    }
    elsif(-e $self->root->file('Makefile.PL'))
    {
      $self->_run($^X, 'Makefile.PL');
      $self->_run('make', 'dist');
      return $self->_extract_tar($self->_find_tar($self->root));
    }
    else
    {
      die 'FIXME';
    }
  },
);

has build_meta => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $root = shift->build_root;
    my $fn;
    foreach my $file (qw( META.json META.yml ))
    { $fn = $root->file($file) if -r $root->file($file) }
    die "could not find META.json or META.yml" unless defined $fn;
    CPAN::Meta->load_file($fn->stringify);
  },
);

sub _run
{
  my($self,@cmdline) = @_;
  
  my @out;
  my $cv = AnyEvent->condvar;
  
  local $| = 1;
       
  my $ipc = AnyEvent::Open3::Simple->new(
    on_stdout => sub { push @out, 'out: ' . pop },
    on_stderr => sub { push @out, 'err: ' . pop },
        
    on_exit => sub {
      my($proc, $exit_value, $signal) = @_;
      
      if($exit_value != 0 || $signal != 0)
      {
        $DB::single = 1;
        $cv->croak(join("\n", 'External Command Error', "% @cmdline", @out));
      }
      else
      {
        $cv->send;
      }
    },
  );

  $ipc->run(@cmdline);
  $cv->recv;
  return;
}

sub _find_tar
{
  my($self, $dir) = @_;
  my @list = grep { $_->basename =~ /\.tar.gz$/ } $dir->children(no_hidden => 1);
  if(@list > 1)
  {
    die "found multiple tarballs";
  }
  elsif(@list == 0)
  {
    die "tarball not found"
  }
  return $list[0];
}

sub _extract_tar
{
  my($self, $tar_fn, $dir) = @_;
  
  my $root = Path::Class::Dir->new( tempdir( CLEANUP => 1) );
  
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
