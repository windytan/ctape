#!/usr/bin/ruby -w
# ctape: read data from a Compact Cassette
# (c) windytan / Oona Räisänen
# ISC license

require 'yaml'

conf = YAML::load(File.open('config.yml'))
$bitlen = conf['bitlen']
$device = conf['device']

$bitreg  = 0
$bytereg = 0
$bitsync = false
$bytesync = false

def bit(value)
  $bitreg = (($bitreg << 1) & 0x3FF) + (value ? 1 : 0)

  if !$bitsync
    if ($bitreg >> 9 > 0) && ($bitreg & 1) == 0
      $bitsync  = true
      $bitcount = 0
    else
      $bitsync = false
      $bytereg = 0
    end
  else
    $bitcount += 1
    if $bitcount == 10
      $bitcount = 0
      if !(($bitreg >> 9 > 0) && ($bitreg & 1) == 0)
        abort if $bytesync
        $bitsync  = false
        $bytesync = false
        $bytereg  = 0
      elsif $bytesync
        print((($bitreg >> 1) & 0xFF).chr)
        $stdout.flush
      else
        $bytereg = (($bytereg << 8) + (($bitreg >> 1) & 0xFF)) & 0xFFFFFFFF
        $bytesync = true if $bytereg == 0x08070504
      end
    end
  end
end


$sox = IO.popen('sox -q '+$device+' -t .raw -r 44100 -c 1 -b 16 -e signed-integer -','r')

# Calibrate polarity
# (wait for 50 repetitions of nppp or pnnn)

polarity  = 0
prevsamp  = 0
slen      = 0
calstring = ""
until $sox.eof? or polarity != 0
  sample = $sox.read(2).unpack('s')[0]
  slen += 1
  if prevsamp * sample < 0
    calstring += (prevsamp > 0 ? "p" : "n") * (slen.to_f / $bitlen).round
    calstring = calstring.slice(-150,150) if calstring.length > 150

    if (slen.to_f / $bitlen).round > 0
      if calstring =~ /(nppp){30}/
        polarity = 1
        break
      end
      if calstring =~ /(pnnn){30}/
        polarity = -1
        break
      end
    end
    slen = 0
  end
  prevsamp = sample
end

# Read data

prevsamp  = 0
curlen  = 0
until $sox.eof?
  sample = $sox.read(2).unpack('s')[0] * polarity
  curlen += 1
  if prevsamp > 0 && sample <= 0
    bit(curlen > $bitlen*1.5)
    curlen = 0
  end
  prevsamp = sample
end

$sox.close
