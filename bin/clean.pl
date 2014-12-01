#!/usr/bin/perl
use strict;
my $fh = undef;
while ( my $line = <> ) {
  if ( $line =~ m/^>(\w+)/ ) {
    warn "open $1.fa";
    close $fh if $fh;
    open $fh, ">$1.fa";
  }
  print $fh $line;
}
