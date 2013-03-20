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
use Nightly;
use Nightly::Pod::File;

# ABSTRACT: Checked or untared dist
# VERSION

has root => (
  is       => 'ro',
  required => 1,
  Nightly->isa_dir,
);

has build_root => (
  is       => 'ro',
  lazy     => 1,
  init_arg => undef,
  default  => sub {
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
      return Nightly->extract_tar($self->_find_tar($self->root));
    }
    elsif(-e $self->root->file('Makefile.PL'))
    {
      $self->_run($^X, 'Makefile.PL');
      $self->_run('make', 'dist');
      return Nightly->extract_tar($self->_find_tar($self->root));
    }
    else
    {
      die 'FIXME';
    }
  },
);

has build_meta => (
  is       => 'ro',
  lazy     => 1,
  init_arg => undef,
  default  => sub {
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

sub find_pods
{
  my($self) = @_;
  
  my @list;
  
  if(-d $self->build_root->subdir('bin'))
  {
    foreach my $script ($self->build_root->subdir('bin')->children(no_hidden => 1))
    {
      push @list, Nightly::Pod::File->new(
        name => $script->basename,
        file => $script,
        type => 'pl',
        dist => $self,
      );
    }
  }
  
  my $recurse;
  $recurse = sub {
    my($dir, @name) = @_;
    foreach my $child ($dir->children(no_hidden => 1))
    {
      if($child->is_dir)
      { $recurse->($child, @name, $child->basename) }
      elsif($child->basename =~ /^(.*)\.(pod|pm)$/)
      {
        push @list, Nightly::Pod::File->new(
          name => join('::', @name, $1),
          file => $child,
          type => $2,
          dist => $self,
        );
      }
    }
  };
  
  if(-d $self->build_root->subdir('lib'))
  {
    $recurse->($self->build_root->subdir('lib'));
  }
  undef $recurse;
  
  return @list;
}

sub is_dist_zilla
{ -r shift->root->file('dist.ini') }

sub is_module_build
{
  my $self = shift;
  return 1 if -r $self->root->file('Build.PL');
  return $self->is_dist_zilla && $self->build_root->file('Build.PL');
}

sub is_make_maker
{
  my $self = shift;
  return 1 if -r $self->root->file('Makefile.PL');
  return $self->is_dist_zilla && $self->build_root->file('Makefile.PL');
}

sub is_perl_dist
{
  my $self = shift;
  $self->is_dist_zilla || $self->is_module_build || $self->is_make_maker;
}

has root_url => (
  is => 'rw',
  Nightly->isa_uri,
);

1;
