package Nightly::HTML::Generator;

use strict;
use warnings;
use v5.10;
use base qw( Pod::Simple::XHTML );

# ABSTRACT: generate XHTML/HTML from POD
# VERSION

sub nightly_resolver
{
  state $resolver = sub { };
  my($class, $new_resolver) = @_;
  
  if(defined $new_resolver)
  {
    $resolver = $new_resolver;
  }
  
  return $resolver;
}

sub new
{
  my $class = shift;
  my %args = @_;
  my $self = $class->SUPER::new(%args);
  $self->html_header('');
  $self->html_footer('');
  $self->html_h_level(3);
  $self->perldoc_url_prefix("http://search.mcpan.org/perldoc?");
  return $self;
}

sub resolve_pod_page_link {
  my $self = shift;
  __PACKAGE__->nightly_resolver->(@_) // $self->SUPER::resolve_pod_page_link(@_);
}

1;
