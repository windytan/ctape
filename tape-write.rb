#!/usr/bin/ruby -w
# ctape: write data onto a Compact Cassette
# (c) windytan / Oona Räisänen
# ISC license

require 'yaml'

conf = YAML::load(File.open('config.yml'))
$bitlen = conf['bitlen']
$device = conf['device']
$volume = conf['volume']

$sox = IO.popen('sox -q -t .raw -r 44100 -c 1 -b 16 -e signed-integer - '+$device,'w')

def putbyte(value)
  putbit 1
  0.upto(7) { |i| putbit((value>>(7-i)) & 1) }
  putbit 0
end

def putbit(value)
  if value == 1
    $bitlen.times     { $sox.write [-0x7FFF * $volume].pack("s") }
    $bitlen.times     { $sox.write [ 0x7FFF * $volume].pack("s") }
  else
    ($bitlen/2).times { $sox.write [-0x7FFF * $volume * 0.5].pack("s") }
    ($bitlen/2).times { $sox.write [ 0x7FFF * $volume * 0.5].pack("s") }
  end
end

# Polarity calibration header
200.times do
  $bitlen.times     { $sox.write [-0x7FFF * $volume].pack("s") }
  (3*$bitlen).times { $sox.write [ 0x7FFF * $volume].pack("s") }
end

# Lead-in
20.times { putbyte 0xFF }

# Sync sequence
for i in [0x08, 0x07, 0x05, 0x04] do putbyte(i) end

# Data
until STDIN.eof?
  putbyte STDIN.read(1).unpack('C')[0]
end

$sox.close
