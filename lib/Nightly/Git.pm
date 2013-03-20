package Nightly::Git;

use strict;
use warnings;
use v5.10;
use Path::Class::Dir;
use File::HomeDir;
use Nightly::Git::Repo;

# ABSTRACT: Git tools
# VERSION

sub find_repos
{
  my($class, $root) = @_;
  $root //= Path::Class::Dir->new(File::HomeDir->my_home, 'public_git');
  $root = Path::Class::Dir->new($root) unless ref $root;
  
  my @repos;
  
  foreach my $child ($root->children(no_hidden => 1))
  {
    next unless $child->is_dir;
    
    if(-d $child->subdir('.git'))
    {
      push @repos, Nightly::Git::Repo->new(
        root => $child,
      );
    }
    else
    {
      push @repos, Nightly::Git->find_repos($child);
    }
  }
  
  @repos;
}

1;
