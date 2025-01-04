#!/usr/bin/env ruby
require "unicode/name"

def parse(bdf)
  header = bdf.match(Regexp.new("(STARTFONT.*?)STARTCHAR",Regexp::MULTILINE))[1].lines(chomp:true)
  chars = bdf.scan(Regexp.new("STARTCHAR.*?ENDCHAR",Regexp::MULTILINE)).map{|char|
    char.lines(chomp:true)
  }
  return header, chars
end

def chars_to_hash(chars)
  chars.map{|char| [char[1].split.last.to_i, char] }.to_h # codepoint=>char
end

def update_header(header,chars,xlfd)
  header = header.dup
  header.size.times{|i|
    h = header[i]
    if h.start_with? "FONT "
      header[i] = "FONT #{xlfd}"
    elsif h.start_with? "CHARS "
      header[i] = "CHARS #{chars.size}"
    end
  }
  return header
end
def check_duplicate(chars_a,chars_b)
  dupe_chars = chars_a.keys & chars_b.keys
  puts "#{dupe_chars.size} characters duplicated"
  dupe_chars.each{|codepoint|
    utf8 = [codepoint].pack("U*")
    name = Unicode::Name.of(utf8)
    cp = "U+%04X" % codepoint
    puts "- `#{utf8}`(#{cp}) `#{name}`"
  }
end
[
  # 16px
  "Shinonome16.bdf", "tmp/shnmk16-unicode.bdf", "tmp/shnm8x16r-unicode.bdf", "tmp/shnm8x16a-unicode.bdf",
      "-Shinonome-Gothic-Medium-R-Normal--16-150-75-75-C-%<avg_width>d-ISO10646-1",0,
  # 16px Bold
  "Shinonome16b.bdf", "tmp/shnmk16b-unicode.bdf", "tmp/shnm8x16rb-unicode.bdf", "tmp/shnm8x16ab-unicode.bdf",
      "-Shinonome-Gothic-Bold-R-Normal--16-150-75-75-C-%<avg_width>d-ISO10646-1",0,
  # 12px
  "Shinonome12.bdf", "tmp/shnmk12-unicode.bdf", "tmp/shnm6x12r-unicode.bdf", "tmp/shnm6x12a-unicode.bdf",
      "-Shinonome-Gothic-Medium-R-Normal--12-110-75-75-C-%<avg_width>d-ISO10646-1",0,
  # 12px Bold
  "Shinonome12b.bdf", "tmp/shnmk12b-unicode.bdf", "tmp/shnm6x12rb-unicode.bdf", "tmp/shnm6x12ab-unicode.bdf",
      "-Shinonome-Gothic-Bold-R-Normal--12-110-75-75-C-%<avg_width>d-ISO10646-1",0,
].each_slice(6){|outfile,jisx0208,jisx0201,iso8859_1,xlfd,avg_width|
  xlfd = format( xlfd, avg_width:avg_width)
  p [jisx0208,jisx0201,iso8859_1,xlfd,outfile]
  jisx0208_header,jisx0208_chars = parse(File.read(jisx0208))
  jisx0201_header,jisx0201_chars = parse(File.read(jisx0201))
  iso8859_1_header,iso8859_1_chars = parse(File.read(iso8859_1))
  # merge
  jisx0208_chars = chars_to_hash(jisx0208_chars)
  jisx0201_chars = chars_to_hash(jisx0201_chars)
  iso8859_1_chars = chars_to_hash(iso8859_1_chars)

  puts "dupe jisx0208 vs iso8859-1"
  check_duplicate(jisx0208_chars,iso8859_1_chars)
  puts "dupe jisx0208 vs jisx0201"
  check_duplicate(jisx0208_chars,jisx0201_chars)
  puts "dupe iso8859-1 vs jisx0201"
  check_duplicate(iso8859_1_chars,jisx0201_chars)

  merged_chars = jisx0208_chars.merge(iso8859_1_chars)
  merged_chars = merged_chars.merge(jisx0201_chars)
  merged_chars = merged_chars.values
  merged_chars.sort!{|a,b|
    a_codepoint = a[1].split.last.to_i
    b_codepoint = b[1].split.last.to_i
    a_codepoint <=> b_codepoint
  }
  new_header = update_header(jisx0208_header,merged_chars,xlfd)
  bdf = new_header.flatten.join("\n") + "\n" + merged_chars.flatten.join("\n") + "\nENDFONT\n"
  bdf.gsub!(/^AVERAGE_WIDTH .*$/,"AVERAGE_WIDTH #{avg_width}")
  File.write outfile, bdf
}
