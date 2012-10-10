ctape
=====

Save digital data onto a Compact Cassette using a format
resembling that of Commodore Datassette.

Usage (write): tape-write.pl datafile
       (read): tape-read.pl

`tape-write.pl` will produce a file named `nauhalle.wav` which
can then be recorded on a tape or other media. `tape-read.pl` records
directly from the sound card and decodes to stdout on the fly.

Requires [SoX](http://sox.sourceforge.net/).

(c) Oona "windytan" Räisänen 2012

MIT license
