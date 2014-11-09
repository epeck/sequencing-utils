package RangeHash;
use strict;
use Data::Dumper qw(Dumper);

use constant DEBUG       =>  1;
use constant MIN_BIN     => 12; #2^12 = 4K
use constant MAX_BIN     => 32; #2^32 = 4G
use constant EXP_BASE    =>  2; #log2 for bits
use constant SEG_BITS    =>  6; #64 possible chromosomes
use constant STRAND_BITS =>  2;
#use constant S_BIT       =>  1; #if block is split across 2 segments, 0=lower, 1=upper. XXX what about 3+ segments in block (e.g. whole-segment range)

sub new {
  my ( $class, %arg ) = @_;
  my $raw_segment = $arg{ 'segment' };

  my $segrank = [ sort keys %$raw_segment ];
  my $segment = {};

  my $o = 0;
  foreach my $s ( @$segrank ) {
    my $length = $raw_segment->{ $s };
    $segment->{ $s }{ 'length' } = $length;
    $segment->{ $s }{ 'offset' } = $o;
    $o += $length;
  }

  my $self = bless {segment=>$segment, segrank=>$segrank}, $class;
  return $self;
}

=item $bin_name = bin($start,$stop,$bin_size,$base)

Given a start, stop and bin size on the genome, translate this
location into a bin name.  In a list context, returns the bin tier
name and the position that the bin begins.

=cut

sub encode_range {
  my ($self, $fid, $fseg, $fmin, $fmax, $fstr) = @_;

  $fmin = abs($fmin);  # to allow negative coordinates
  $fmax = abs($fmax);

  print STDERR "unknown segment '$fseg', id='$fid'" and return(undef) unless defined $self->{ 'segment' }{ $fseg };
  die "feature size too large." unless $fmax - $fmin < EXP_BASE ** MAX_BIN;

  $fmin += $self->{ 'segment' }{ $fseg }{ 'offset' };
  $fmax += $self->{ 'segment' }{ $fseg }{ 'offset' };

  my $tier = EXP_BASE ** MIN_BIN;
  my ($bmin,$bmax);
  while (1) {
    $bmin = int $fmin/$tier;
    $bmax = int $fmax/$tier;
    last if $bmin == $bmax;
    $tier *= EXP_BASE;
  }
  #print "fmin=$fmin\n";
  #print "fmax=$fmax\n";
  #print "tier=$tier\n";
  #print "bmin=".($tier*$bmin)."\n";
  #print "bmax=".($tier*($bmin+$tier))."\n";
  #my $seg0 = $self->decode_segment( $tier * $bmin );
  #my $seg1 = $self->decode_segment( $tier * ($tier+$bmin) );
  #my $sbit = $fseg eq $seg0 ? 0 : 1;
  my $encoded = range_name($tier,$bmin,$fstr);#,$sbit);
  return $encoded;
}
sub decode_range {
  my ($self, $encoded) = @_;
  my $packed = pack("N", $encoded);
  my $bitstring = unpack("B32", $packed);
  my $bpos  = substr( $bitstring, 0, MAX_BIN - MIN_BIN );
  my $btier = substr( $bitstring, MAX_BIN - MIN_BIN, SEG_BITS );
  my $bstr  = substr( $bitstring, SEG_BITS + (MAX_BIN - MIN_BIN), STRAND_BITS );
  #my $sbit  = substr( $bitstring, SEG_BITS + (MAX_BIN - MIN_BIN) + STRAND_BITS, S_BIT );

  my $block_tier = oct("0b$btier");
  my $block_size = EXP_BASE ** $block_tier;
  my $block_pos  = oct("0b$bpos");
  my $strand = $bstr eq '00' ? '?' : $bstr eq '01' ? '+' : $bstr eq '10' ? '-' : '.';

  my $block_min = $block_pos * $block_size;
  my $block_max = $block_min + $block_size;

  #print "btier=$btier\n";
  #print "bpos =$bpos\n";
  #print "bstr =$bstr\n";

  my @segment = ();
  my $segment_min = $self->decode_segment( $block_min );
  my $segment_max = $self->decode_segment( $block_max );
  if ( $segment_min eq $segment_max ) {
    push @segment, [
      $segment_min,
      $block_min - $self->{ 'segment' }{ $segment_min }{ 'offset' } || 1,
      $block_max - $self->{ 'segment' }{ $segment_min }{ 'offset' },
    ];
  }
  else {
    push @segment, [
      $segment_min,
      $block_min - $self->{ 'segment' }{ $segment_min }{ 'offset' },
      int($self->{ 'segment' }{ $segment_min }{ 'length' }),
    ];
    push @segment, [
      $segment_max,
      1,
      $block_max - $self->{ 'segment' }{ $segment_max }{ 'offset' },
    ] if defined $segment_max;
  }

  return {
    block_tier => $block_tier,
    block_rank => $block_pos,
    block_size => $block_size,
    strand => $strand,
    segments => \@segment,
  };
}
sub decode_segment {
  my ( $self, $pos ) = @_;

  print "finding segment for $pos...\n" if DEBUG;

  my @rank = @{ $self->{ 'segrank' } };

  for ( my $i = 0 ; $i < scalar( @rank ) ; $i++ ) {
    my $offL = $self->{ 'segment' }{ $rank[$i]   }{ 'offset' };
    my $offR;
    if ( $i + 1 == scalar( @rank ) ) {
      #last
      $offR = $offL + $self->{ 'segment' }{ $rank[$i] }{ 'length' };
    }
    else {
      $offR = $self->{ 'segment' }{ $rank[$i+1] }{ 'offset' };
    }
    print "  comparing to segment $rank[$i] at $offL..$offR\n" if DEBUG;
    if ( $offL <= $pos && $offR > $pos ) {
      print "    got it\n" if DEBUG;
      return $rank[$i];
    }
  }
  if ( $pos > $rank[-1] ) {
    return undef; #overflow;
  }
}
sub range_name {
  my ($tier, $int, $strand ) = @_;#, $sbit) = @_;
  my $pos = abs($int);
  $pos = 0 if $pos < 0;

  my $istrand = $strand eq '?' ? 0 : #unknown
                $strand eq '+' ? 1 : #plus
                $strand eq '-' ? 2 : 3; #minus : unstranded

  my $btier = sprintf("%b",logB($tier));
  my $bpos  = sprintf("%b", $pos);
  my $bstr  = sprintf("%b", $istrand);
  my $bres  = "0000"; #reserved bits
  while( length($btier) < (SEG_BITS)  ) {
    #MSB padding
    $btier = "0$btier";
  }
  while( length($bpos)  < (MAX_BIN - MIN_BIN) ) {
    #MSB padding
    $bpos  = "0$bpos";
  }
  while( length($bstr)  < STRAND_BITS ) {
    #MSB padding
    $bstr  = "0$bstr";
  }

  return unpack("N", pack("B32", "$bpos$btier$bstr$bres")); #$sbit
}
sub logB {
  my $i = shift;
  log($i)/log(EXP_BASE);
}
1;
