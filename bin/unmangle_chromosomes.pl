#!/usr/bin/perl
use strict;
while ( my $line = <> ) {
  if ( $line =~ m/^(X|Y|MT|\d+)/ ) {
    my $old = $1;
    my $new = $old;
    if ( $new eq 'MT' ) {
      $new = 'M';
    }
    $line =~ s/^$old/chr$new/;
  }
  print $line;
}
