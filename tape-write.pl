#!/usr/bin/perl
#
# tape-write.pl
#
# Record digital data on a Compact Cassette using a format
# resembling that of Commodore Datassette
#
# Usage: tape-write.pl datafile
#
# (c) windytan (Oona Räisänen)
#
# ISC license
#

use warnings;
use strict;

my %conf;
open(IN,"ctape.conf") or die($!);
for (<IN>) {
  chomp;
  $conf{$1} = $2 if (/^(\S+) (.+)/);
}
close(IN);

# start bit (1)
# 8 data (msb first)
# stop bit (0)
#
# start byte seq: 0x08 0x07 0x05 0x04

open(IN,$ARGV[0]) or die ($!);
open(OUT,"|sox -q -t .raw -r 44100 -c 1 -b 16 -e signed-integer - ".$conf{'device'}) or die ($!);

my @buffer = ();
$buffer[0] = pack("s",0);

# Polarity calibration header
# 1 bitlength negative, 3 bitlengths positive
my $round, my $b;
for $round (0..500) {
  print OUT pack("s",-32767 * $conf{'volume'}) for (0..$conf{'bitlen'}-1);
  print OUT pack("s", 32767 * $conf{'volume'}) for (0..$conf{'bitlen'}*3-1);
}

# 50-byte lead-in
putbyte(chr(0xFF)) for (0..49);

# sync sequence
putbyte(chr($_)) for (0x08, 0x07, 0x05, 0x04);

# data
while (not eof(IN)) {
  my $a;
  read(IN,$a,1);
  putbyte($a);
}
close(OUT);
close(IN);


sub putbyte {
  putbit(1);
  putbit((ord($_[0]) >> (7-$_)) & 1) for (0..7);
  putbit(0);
}

sub putbit {
  if ($_[0]) {
    print OUT pack("s",-32767 * $conf{'volume'}) x $conf{'bitlen'};
    print OUT pack("s", 32767 * $conf{'volume'}) x $conf{'bitlen'};
  } else {
    print OUT pack("s",-32767 * $conf{'volume'}/2) x ($conf{'bitlen'}/2);
    print OUT pack("s", 32767 * $conf{'volume'}/2) x ($conf{'bitlen'}/2);
  }
}
