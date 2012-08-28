#!/usr/bin/perl
#
# tape-write.pl
#
# Record digital data on a Compact Cassette using a format
# resembling that of Commodore Datassette
#
# Usage: tape-write.pl datafile
#
# (c) Oona "windytan" Räisänen 2012
#
# MIT license
#

use warnings;

# start bit (1)
# 8 data (msb first)
# stop bit (0)
#
# start byte seq: 0x08 0x07 0x05 0x04

open(IN,$ARGV[0]) or die ($!);
open(OUT,"|sox -t .raw -r 32000 -c 1 -b 16 -e signed-integer - nauhalle.wav");

# 50-byte lead-in
for (0..50) {
  putbit(1);
  putbit(1) for (0..7);
  putbit(0);
}

# sync sequence
for $a (0x08, 0x07, 0x05, 0x04) {
  putbit(1);
  putbit(($a >> (7-$_)) & 1) for (0..7);
  putbit(0);
}

# data
while (not eof(IN)) {
  read(IN,$a,1);
  putbit(1);
  putbit((ord($a) >> (7-$_)) & 1) for (0..7);
  putbit(0);
}
close(OUT);
close(IN);

sub putbit {
  if ($_[0]) {
    print OUT (pack("s",-20000) x 12);
    print OUT (pack("s", 20000) x 12);
  } else {
    print OUT (pack("s",-10000) x 6);
    print OUT (pack("s", 10000) x 6);
  }
}