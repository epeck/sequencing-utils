#!/usr/bin/perl
use strict;
while ( my $line = <> ) {
  if ( $line =~ m/^chr(\w+)/ ) {
    my $old = $1;
    my $new = $old;
    if ( $new eq 'M' ) {
      $new = 'MT';
    }
    $line =~ s/^chr$old/$new/;
  }
  print $line;
}
