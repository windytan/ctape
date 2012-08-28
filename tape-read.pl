#!/usr/bin/perl
#
# tape-read.pl
#
# read data from a Compact Cassette
#
# (c) Oona "windytan" Räisänen 2012
#
# MIT license
#

use warnings;
$|++;

open(IN,"rec -t .raw -c 1 -r 32000 -e signed-integer -b 16 -|");
$prev_a = 0;
$bitreg = $bytereg = 0;
while (not eof(IN)) {
  read(IN,$a,2);
  $a = -unpack("s",$a);
  $len ++;
  if ($prev_a > 0 && $a <= 0) {
    bit($len > 18);
    $len = 0;
  }
  $prev_a = $a;
}
close(IN);

sub bit {
  my $b = $_[0];

  $bitreg = (($bitreg << 1) & 0x3FF) + $b;

  if (not $bitsync) {
    if (($bitreg >> 9) == 1 && ($bitreg & 1) == 0) {
      $bitsync  = 1;
      $bitcount = 0;
      print STDERR "bitsync\n";
    } else {
      $bitsync = $bytereg = 0;
    }

  } else {

    if (++$bitcount == 10) {
      $bitcount=0;
      if (!(($bitreg >> 9) == 1 && ($bitreg & 1) == 0)) {
        print STDERR "lost\n";
        die if ($bytesync);
        $bitsync = $bytesync = $bytereg = 0;
      } elsif ($bytesync) {
        print chr(($bitreg >> 1) & 0xFF);
      } else {
        $bytereg = (($bytereg << 8) + (($bitreg >> 1) & 0xFF)) & 0xFFFFFFFF;
        print STDERR "still sync'd\n";
        print STDERR sprintf("%08x\n",$bytereg);
        if ($bytereg == 0x08070504) {
          print STDERR "OMG Bytesync lol!\n";
          $bytesync = 1;
        }
      }
    }
  }

}