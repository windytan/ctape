#!/usr/bin/perl
#
# tape-read.pl
#
# read data from a Compact Cassette
#
# (c) windytan (Oona Räisänen)
#
# ISC license
#

use warnings;
$|++;

my %conf;
open(IN,"ctape.conf") or die($!);
for (<IN>) {
  chomp;
  $conf{$1} = $2 if (/^(\S+) (.+)/);
}
close(IN);

open(IN,"sox -q ".$conf{'device'}." -t .raw -c 1 -r 44100 -b 16 -e signed-integer - |");

# calibrate polarity
# (wait for 50 repetitions of (nppp) or (pnnn))
my $polty = 0;
while ( (not eof(IN)) && $polty == 0 ) {
  read(IN,$samp,2);

  $samp = unpack("s",$samp);
  $slen++;
  if (($prevsamp // 0) * $samp < 0) {
    $calstring .= ($prevsamp > 0 ? "p" : "n") x round($slen / $conf{'bitlen'});
    $calstring = substr($calstring,-150) if (length($calstring) > 150);

    if (round($slen / $conf{'bitlen'}) > 0) {
      if ($calstring =~ /(nppp){30}/) {
        $polty = 1;
        last;
      }
      if ($calstring =~ /(pnnn){30}/) {
        $polty = -1;
        last;
      }
    }
    $slen = 0;
  }
  $prevsamp = $samp;
}

# read data

open(G,"|sox -q -t .raw -c 1 -r 44100 -b 16 -e signed-integer - g.wav");#sinc -10640|");
my $prev_c  = 0;
my $bitreg  = 0;
my $bytereg = 0;
while (not eof(IN)) {
  read(IN,$a,2);

  $c = $polty * unpack("s",$a);
  print G pack("s",$c);
  $len ++;
  if ($prev_c > 0 && $c <= 0) {
    bit($len > $conf{'bitlen'}*1.5);
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
