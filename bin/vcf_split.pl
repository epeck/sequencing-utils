#!/usr/bin/perl
use strict;

my $vcf = shift @ARGV;

my $head1 = "";
my $head2 = "";

my %contig = ();
my %filled = ();

#pass1: identify contigs
open( H, $vcf );
while ( my $line = <H> ) {
  last unless $line =~ m/^#/;

  if ( $line =~ m/^##contig=<ID=(.+?),/ ) {
    my $c = $1;
    $contig{ $c } = $line;
  }
  elsif ( scalar keys %contig == 0 ) {
    $head1 .= $line;
  }
  else {
    $head2 .= $line;
  }
}
close( H );

#pass2: write contig headers
my %fh = ();
foreach my $c ( keys %contig ) {
  open( my $ff, ">$c.vcf" );
  $fh{ $c } = $ff;
  print $ff $head1;
  print $ff $contig{ $c };
  print $ff $head2;
}

#pass2: write scattered contig content
open(V, $vcf);
while ( my $line = <V> ) {
  next if $line =~ m/^#/;
  $line =~ m/^(.+?)\t/;
  my $ff = $fh{ $1 };
  $filled{ $1 } = 1;
  print $ff $line;
}
close(V);

foreach my $c ( keys %contig ) {
  close( $fh{ $c } );
  if ( ! $filled{ $c } ) {
    #unlink( "$c.vcf" );
  }
}
