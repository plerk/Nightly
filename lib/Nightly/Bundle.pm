package Nightly::Bundle;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use URI;
use URI::file;
use File::HomeDir;
use Path::Class::File;
use Path::Class::Dir;
use File::Copy qw( copy );
use Template;
use Nightly;
use Nightly::HTML::Generator;

# ABSTRACT: Several Perl Dists together
# VERSION

has description => ( is => 'ro', default => sub { 'Pod Documentation' } );
has author => ( is => 'ro', default => sub { 'Unknown' } );
has favicon => ( is => 'ro', default => sub { 'http://perl.com/favicon.ico' } );
has brand => ( is => 'ro', default => sub { 'Perl Documentation' } );

has root => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Path::Class::Dir->new(File::HomeDir->my_home, 'public_html');
  },
  Nightly->isa_dir,
);

has root_url => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    URI::file->new(shift->root->stringify);
  },
  Nightly->isa_uri,
);

has home_url => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $uri = $self->root_url->clone;
    my $path = Path::Class::Dir
      ->new_foreign('Unix', $self->root_url->path, 'index.html')
      ->as_foreign('Unix');
    $uri->path($path);
    $uri;
  },
  Nightly->isa_uri,
);

has dists => (
  is      => 'ro',
  lazy    => 1,
  default => sub { { } },
);

sub add_dist
{
  my($self, $dist) = @_;
  
  my $name = $dist->build_meta->name;
  my $version = $dist->build_meta->version;
  if($self->dists->{$name})
  {
    # FIXME: handle dev releases here
    if($version > $self->dists->{$name}->build_meta->version)
    {
      $self->dists->{$name} = $dist;
    }
  }
  else
  {
    $self->dists->{$name} = $dist;
  }
  
  $self;
}

has pods => (
  is      => 'ro',
  lazy    => 1,
  default => sub { { } },
);

has warning => (
  is => 'ro',
  lazy => 1,
  default => sub { sub { say STDERR "warning: @_" } },
);

sub build_pod_list
{
  my($self) = @_;
  
  foreach my $dist (values %{ $self->dists })
  {
    foreach my $pod ($dist->find_pods)
    {
      if(defined $self->pods->{$pod->name})
      {
        $self->warning->(
          "duplicate POD: " . $pod->file .
          " and " . $self->pods->{$pod->name}->file
        );
      }
      else
      {
        $self->pods->{$pod->name} = $pod;
      }
    }
  }
  
  $self;
}

has css_url => ( is => 'rw', Nightly->isa_uri );
has img_url => ( is => 'rw', Nightly->isa_uri );
has js_url  => ( is => 'rw', Nightly->isa_uri );

sub copy_support_files
{
  my($self) = @_;
  foreach my $type (qw( css img js ))
  {
    my $to = $self->root->subdir($type);
    $to->mkpath(0,0755);
    copy($_, $to->file($_->basename))
      foreach Nightly
        ->share_dir
        ->subdir($type)
        ->children(no_hidden => 1);
    my $method = "${type}_url";
    
    my $uri = $self->root_url->clone;
    $uri->path(
      Path::Class::Dir
        ->new_foreign('Unix', $self->root_url->path)
        ->subdir($type)
        ->as_foreign('Unix')
    );
    
    $self->$method($uri);
  }
}

has tt => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    Template->new(
      INCLUDE_PATH => Nightly->share_dir->subdir('tt')->stringify
    );
  },
);

sub generate_index_html
{
  my($self) = @_;

  $self->root->mkpath(0,0755)
    unless -d $self->root;
  
  my @dists;
  
  foreach my $dist (sort { $a->build_meta->name cmp $b->build_meta->name } values %{ $self->dists })
  {
    $self->root->subdir($dist->build_meta->name)->mkpath(0,0755);
    
    my $uri = $self->root_url->clone;
    $uri->path(
      Path::Class::Dir
        ->new_foreign('Unix', $self->root_url->path)
        ->subdir($dist->build_meta->name)
        ->as_foreign('Unix')
    );
    
    $dist->root_url($uri->clone);
    
    $uri->path(
      Path::Class::Dir
        ->new_foreign('Unix', $self->root_url->path)
        ->file($dist->build_meta->name, 'index.html')
        ->as_foreign('Unix')
    );
    
    $dist->home_url($uri->clone);
    
    push @dists, $dist;
    
    my $html = '';
    $self->tt->process(
      'dist_index.tt',
      { bundle => $self, dist => $dist },
      \$html
    ) || die $self->tt->error;
    
    $self
      ->root
      ->file( $dist->build_meta->name, 'index.html' )
      ->spew($html);
  }

  $self->root->file('index.html')->spew(do {
    my $html = '';
    $self->tt->process(
      'dists_index.tt',
      { bundle => $self, dists => \@dists },
      \$html,
    ) || die $self->tt->error;
    $html;
  });
    
  $self;
}

sub generate_pod_html
{
  my($self) = @_;

  my $name;
  my $pod;

  Nightly::HTML::Generator->nightly_resolver(sub {
    my($page) = @_;
    if(my $pod = $self->pods->{$page})
    {
      my $uri = $pod->dist->root_url->clone;
      my $path = Path::Class::File
        ->new_foreign('Unix', $pod->dist->root_url->path, $pod->filename)
        ->as_foreign('Unix');
      $uri->path($path);
      return $uri->as_string;
    }
    else
    {
      return;
    }
  });

  while(($name, $pod) = each %{ $self->pods })
  {
    $self
      ->root
      ->file($pod->dist->build_meta->name, $pod->name . '.html')
      ->spew(do {
        my $html = '';
        $self->tt->process(
          'pod.tt',
          { bundle => $self, pod => $pod },
          \$html,
        );
        $html;
      })
    ;
  }
  
  $self;
}

1;
