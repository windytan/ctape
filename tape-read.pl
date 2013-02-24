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
use constant DELAY  => 32;

open(IN,"sox -q -t alsa hw:1 -t .raw -c 2 -r 44100 -b 16 -e signed-integer - |");#sinc -10640|");
#open(IN,"sox -q nauhalle.wav -t .raw -c 2 -r 44100 -b 16 -e signed-integer - |");#sinc -10640|");

# calibrate channel order & polarity
# (wait for 50 repetitions of (nppp) or (pnnn) on either channel)
my $polty = 0;
while ( (not eof(IN)) && $polty == 0 ) {
  read(IN,$samp[0],2);
  read(IN,$samp[1],2);

  for $chan (0..1) {
    $samp[$chan] = unpack("s",$samp[$chan]);
    $slen[$chan]++;
    if (($prevsamp[$chan] // 0) * $samp[$chan] < 0) {
      $calstring[$chan] .= ($prevsamp[$chan] > 0 ? "p" : "n") x round($slen[$chan] / BITLEN);
      $calstring[$chan] = substr($calstring[$chan],-150) if (length($calstring[$chan]) > 150);

      if (round($slen[$chan] / BITLEN) > 0) {
        if ($calstring[$chan] =~ /(nppp){30}/) {
          $polty = 1;
          $leftc = $chan;
          last;
        }
        if ($calstring[$chan] =~ /(pnnn){30}/) {
          $polty = -1;
          $leftc = $chan;
          last;
        }
      }
      $slen[$chan] = 0;
    }
    $prevsamp[$chan] = $samp[$chan];
  }
}

# read data

open(G,"|sox -q -t .raw -c 1 -r 44100 -b 16 -e signed-integer - g.wav");#sinc -10640|");
my $prev_c  = 0;
my $bitreg  = 0;
my $bytereg = 0;
while (not eof(IN)) {
  read(IN,$a[0],2);
  read(IN,$a[1],2);

  push(@buffer, $a[$leftc]);
  shift(@buffer) if (@buffer > DELAY);

  $c = $polty * (unpack("s",$a[1-$leftc]) + unpack("s",$buffer[0]));
  print G pack("s",$c);
  $len ++;
  if ($prev_c > 0 && $c <= 0) {
    bit($len > BITLEN*1.5);
    $len = 0;
  }
  $prev_c = $c;
}
close(IN);
close(G);



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

sub round {
  int($_[0] + .5);
}
