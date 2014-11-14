#!/usr/bin/perl
use strict;
use lib 'RangeHash';
use RangeHash;
use Data::Dumper qw(Dumper);

my $segment = {};

my $segment_file = shift @ARGV;
open(O, $segment_file);
while ( my $line = <O> ) {
  next unless $line =~ m/^\@SQ/;
  chomp $line;
  my ($seg, $len) = split /\s+/, $line;
  $seg =~ s/SN://;
  $len =~ s/LN://;
  $segment->{ $seg } = $len;
  #->{ $chr } = $len;

  last unless $line =~ m/^\@/;
}

#XXX right now we assume sample is identical across all lanes and we encode lane numerically from @RG in sam header, see:
#zcat NA12878.bam.gz | ./samtools-1.1/samtools view -H -
my $SAMPLE = 'NA12878';

my $codec = new RangeHash( segment => $segment );
while ( my $line = <> ) {
  chomp $line;
  my @F = split /\t/, $line;
  my $flag = $F[1];

  my $fstr = '+';
  if ( $flag & 0x4  ) { $fstr = '?' }
  if ( $flag & 0x10 ) { $fstr = '-' }

  my $fid  = $F[0];
  my $fseg = $F[2];
  my $fmin = $F[3];
  my $fmax = $F[3] + length($F[9]);
  my ( $lane ) = $line =~ m/RG:Z:(\d+)/;
  my $encoded = $codec->encode_range($fid, $fseg, $fmin, $fmax, $fstr);
  print "$encoded-$SAMPLE-$lane\t$line\n";# if $. % 10_000 == 1;
}

__END__
my @F = (
#  [ 'chr19', 58_617_614, 58_617_615, '?' ], #overflows!
#  [ 'chr1' ,          1,         10, '?' ], #underflows!
#  [ 'chr1' , 40_000_000, 40_000_999, '?' ],
#  [ 'chr1' , 40_000_000, 40_000_099, '+' ],
#  [ 'chr1' , 40_000_000, 40_000_009, '-' ],
#  [ 'chr1' , 40_000_000, 40_000_001, '.' ],
#  [ 'chrY' , 57_227_414, 57_227_415, '.' ],
);
foreach my $f ( @F ) {
  my ( $fseg, $fmin, $fmax, $fstr ) = @$f;
  my $encoded = $codec->encode_range($fseg, $fmin, $fmax, $fstr);
  print "$encoded\t$fseg\t$fstr\t$fmin\t$fmax\n";
  my $decoded = $codec->decode_range($encoded);
  print Dumper($decoded), "\n";
}
