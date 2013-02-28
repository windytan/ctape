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
use constant DELAY  => 32;
use constant VOLUME => 0.98;

# start bit (1)
# 8 data (msb first)
# stop bit (0)
#
# start byte seq: 0x08 0x07 0x05 0x04

open(IN,$ARGV[0]) or die ($!);
open(OUT,"|sox -q -t .raw -r 44100 -c 2 -b 16 -e signed-integer - -t alsa hw:1") or die ($!);
#open(OUT,"|sox -q -t .raw -r 44100 -c 2 -b 16 -e signed-integer - nauhalle.wav") or die ($!);

my @buffer = ();
$buffer[0] = pack("s",0);

# Channel & polarity calibration header
# Left channel:  1 bitlength negative, 3 bitlengths positive
# Right channel: 2 bitlengths negative, 2 bitlengths positive
my $round, my $b;
for $round (0..500) {
  for $b (0..BITLEN-1) {
    print OUT pack("s",-32767 * VOLUME);
    print OUT pack("s", 32767 * VOLUME);
  }
  for $b (0..BITLEN-1) {
    print OUT pack("s", 32767 * VOLUME);
    print OUT pack("s",-32767 * VOLUME);
  }
  for $b (0..BITLEN-1) {
    print OUT pack("s", 32767 * VOLUME);
    print OUT pack("s", 32767 * VOLUME);
  }
  for $b (0..BITLEN-1) {
    print OUT pack("s", 32767 * VOLUME);
    print OUT pack("s", 32767 * VOLUME);
  }
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
  my $shft;
  for $shft (0..7) {
    putbit((ord($_[0]) >> (7-$shft)) & 1);
  }
  putbit(0);
}

sub putbit {
  if ($_[0]) {
    delay_write (pack("s",-32767 * VOLUME), BITLEN);
    delay_write (pack("s", 32767 * VOLUME), BITLEN);
  } else     {
    delay_write (pack("s",-32767 * VOLUME/2), BITLEN/2);
    delay_write (pack("s", 32767 * VOLUME/2), BITLEN/2);
  }
}

sub delay_write {
  my $s;
  for $s (0..$_[1]-1) {
    push(@buffer, $_[0]);
    shift(@buffer) if (@buffer > DELAY);
    print OUT $buffer[$#buffer];
    print OUT $buffer[0];
  }
}
