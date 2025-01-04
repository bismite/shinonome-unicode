#!/usr/bin/env ruby
require "colorize"
require "unicode/name"

$uax11 = []
def load_uax11(txt)
  txt.each_line{|l|
    l = l.strip
    next if l.empty?
    next if l.start_with?("#")
    range,_,width = l.split
    a,b = range.split("..")
    if b
      a = a.to_i(16)
      b = b.to_i(16)
      $uax11.fill(width, (a..b))
    else
      $uax11[a.to_i(16)] = width
    end
  }
end

def check_unicode_bdf_width(bdf,width)
  if width==:full
    valid_width = %w(F W A ) # Fullwidth, Wide, Ambiguous
  elsif width == :half
    valid_width = %w(H Na N) # Halfwidth, Narrow, Neutral
  end
  bdf.scan(/^ENCODING (.*)$/).flatten.each{|codepoint|
    codepoint = codepoint.to_i
    utf8 = [codepoint].pack("U*")
    valid = valid_width.include?($uax11[codepoint])
    ok = valid ? "OK".green : "NG".red
    unless valid
      name = Unicode::Name.of(utf8)
      cp = "0x%04X" % codepoint
      puts "<#{ok}> [#{cp}][#{utf8}] UAX11=#{$uax11[codepoint]} [#{name}]"
    end
  }
end

eaw_txt = `curl https://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt`
load_uax11(eaw_txt)
Dir.glob("tmp/*.bdf"){|f|
  puts "check width #{f}"
  width = f.include?("shnmk") ? :full : :half
  bdf = File.read f
  check_unicode_bdf_width bdf, width
}
