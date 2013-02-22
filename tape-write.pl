#!/usr/bin/perl
#
# tape-write.pl
#
# Record digital data on a Compact Cassette using a format
# resembling that of Commodore Datassette
#
# Usage: tape-write.pl datafile
#
# (c) Oona "windytan" Räisänen 2012-2013
#
# MIT license
#

use warnings;
use strict;

use constant BITLEN => 8;

# start bit (1)
# 8 data (msb first)
# stop bit (0)
#
# start byte seq: 0x08 0x07 0x05 0x04

open(IN,$ARGV[0]) or die ($!);
open(OUT,"|sox -q -t .raw -r 44100 -c 1 -b 16 -e signed-integer - -t alsa hw:1") or die ($!);
#open(OUT,"|sox -q -t .raw -r 44100 -c 1 -b 16 -e signed-integer - nauhalle.wav") or die ($!);

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
  my $shft;
  for $shft (0..7) {
    putbit((ord($_[0]) >> (7-$shft)) & 1);
  }
  putbit(0);
}

sub putbit {
  if ($_[0]) { print OUT (pack("s",-20000) x BITLEN)     . (pack("s", 20000) x BITLEN);       }
  else       { print OUT (pack("s",-10000) x (BITLEN/2)) . (pack("s", 10000) x (BITLEN/2)); }
}
