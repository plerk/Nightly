use strict;
use warnings;
use v5.10;

sub extract_tar {
  my $name = shift;

  use Archive::Tar;
  use File::Temp qw( tempdir );
  use Path::Class qw( dir file );

  my $root = dir( tempdir( CLEANUP => 1 ) );
  my $tar_fn = file( __FILE__ )->parent->file('tar', $name);
  
  ok -d $root && -r $tar_fn, "x $tar_fn => $root";

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
      $tar->extract_file( $fn, $root->file( $fn )->stringify );
    }
  }
  
  return $root;
}

1;
