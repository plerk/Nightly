package Nightly::Pod::File;

use strict;
use warnings;
use v5.10;
use Moo;
use warnings NONFATAL => 'all';
use Pod::Abstract;
use Nightly::HTML::Generator;
use Nightly::Pod::Link;

# ABSTRACT: Pod file
# VERSION

has name => (
  is       => 'ro',
  required => 1,
);

has file => (
  is       => 'ro',
  required => 1,
  Nightly->isa_file,
);

has dist => (
  is       => 'ro',
  required => 1,
  isa      => sub { die 'dist must be Nightly::Dist' unless $_[0]->isa('Nightly::Dist') },
);

has abstract => (
  is       => 'ro',
  lazy     => 1,
  init_arg => undef,
  default  => sub {
    my $self = shift;
    my($pod) = Pod::Abstract
      ->load_file($self->file->stringify)
      ->select('/head1[=~ {NAME}]');
    if(defined $pod)
    {
      $_->detach for $pod->select('//#cut');
      ($pod) = $pod->children;
      if(defined $pod)
      {
        $pod = $pod->pod;
        $pod =~ s/^\s+//;
        $pod =~ s/\s+$//;
        if($pod =~ /^(.*) --? (.*)$/)
        {
          say STDERR "NAME section does not match " . $self->name
            if $1 ne $self->name;
          return $2;
        }
        else
        {
          say STDERR "NAME section bad format for " . $self->name;
        }
      }
      else
      {
        say STDERR "NAME section missing " . $self->name;
      }
    }
    else
    {
      say STDERR "NAME section missing " . $self->name;
    }
    return '';
  },
);

sub html
{
  my($self) = @_;
  
  my $psx = Nightly::HTML::Generator->new;
  my $html = '';
  $psx->output_string(\$html);
  $psx->parse_file($self->file->stringify);
  
  $html;
}

sub slurp
{
  scalar shift->file->slurp;
}

sub link
{
  my $self = shift;
  Nightly::Pod::Link->new(
    name     => $self->name,
    abstract => $self->abstract,
    filename => $self->filename,
  )
}

has filename => (
  is => 'ro',
  lazy => 1,
  default => sub {
    shift->name . '.html';
  },
);

1;

