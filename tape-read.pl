#!/usr/bin/perl
#
# tape-read.pl
#
# read data from a Compact Cassette
#
# (c) Oona "windytan" Räisänen 2012-2013
#
# MIT license
#

use warnings;
$|++;

use constant BITLEN => 8;

open(IN,"sox -q -t alsa hw:1 -t .raw -c 2 -r 44100 -b 16 -e signed-integer - |");#sinc -10640|");
#open(IN,"sox -q nauhalle.wav -t .raw -c 2 -r 44100 -b 16 -e signed-integer - |");#sinc -10640|");
my $prev_c  = 0;
my $bitreg  = 0;
my $bytereg = 0;
while (not eof(IN)) {
  read(IN,$a,2);
  read(IN,$b,2);
  $c = -(unpack("s",$a) + unpack("s",$b));
  $len ++;
  if ($prev_c > 0 && $c <= 0) {
    bit($len > BITLEN*1.5);
    $len = 0;
  }
  $prev_c = $c;
}
close(IN);

sub bit {

  $bitreg = (($bitreg << 1) & 0x3FF) + $_[0];

  if (not $bitsync) {
    if (($bitreg >> 9) && not ($bitreg & 1)) {
      $bitsync  = 1;
      $bitcount = 0;
    } else {
      $bitsync = $bytereg = 0;
    }

  } else {

    if (++$bitcount == 10) {
      $bitcount=0;
      if (not (($bitreg >> 9) && not ($bitreg & 1))) {
        die if ($bytesync);
        $bitsync = $bytesync = $bytereg = 0;
      } elsif ($bytesync) {
        print chr(($bitreg >> 1) & 0xFF);
      } else {
        $bytereg = (($bytereg << 8) + (($bitreg >> 1) & 0xFF)) & 0xFFFFFFFF;
        $bytesync = 1 if ($bytereg == 0x08070504);
      }
    }
  }

}
