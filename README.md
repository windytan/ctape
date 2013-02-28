ctape
=====

Save digital data onto a Compact Cassette using a format
resembling that of Commodore Datassette.

Usage:

* encoding: `./tape-write.pl FILE`
* decoding: `./tape-read.pl`

Explanation and videos in [this blog post](http://windytan.blogspot.fi/2012/08/vintage-bits-on-cassettes.html).

`tape-write.pl` encodes the file given on its command line to the sound card. `tape-read.pl` records from
the sound card and decodes to stdout on the fly.

A WORD OF WARNING. Before running the script, please make sure
that your speakers are turned off. The signal is very loud, and
its spectral composition is guaranteed to turn your speakers into
a long-range acoustic weapon.

Requires [SoX](http://sox.sourceforge.net/).

© windytan (Oona Räisänen) 2012

MIT license
