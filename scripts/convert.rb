#!/usr/bin/env ruby
require "fileutils"
require "unicode/name"

def iso8859_1_to_unicode(num)
  # Rejecting
  return nil,nil if num < 0x20
  return nil,nil if 0x7E < num && num < 0xA0
  # convert
  utf8 = num.chr.force_encoding("ISO8859-1").encode("UTF-8")
  codepoint = utf8.codepoints.first
  # p [:ISO8859_1, utf8, "0x"+codepoint.to_s(16), Unicode::Name.of(utf8)]
  return utf8, codepoint
end

def jisx0201_to_unicode(num)
  # Rejecting
  return nil,nil if num < 0x20
  return nil,nil if 0x7E < num && num < 0xA1
  return nil,nil if num > 0xDF # undefined
  # convert start
  if num==0x5C # Yen Sign
    return "¥", "¥".codepoints.first
  elsif num==0x7E # overline
    return "‾", "‾".codepoints.first
  elsif num <= 0x7E # Ascii
    return num.chr.encode("UTF-8"), num.chr.encode("UTF-8").codepoints.first
  end
  # Hankaku
  tmp = [0x8E,num].pack("c*").force_encoding("EUC-JP-MS")
  utf8 = tmp.encode("UTF-8")
  return utf8, utf8.codepoints.first
end

def jisx0208_to_unicode(num)
  a = (num >> 8) & 0xFF
  b = num & 0xFF
  a = a-0x20+0xA0
  b = b-0x20+0xA0
  tmp = [a,b].pack("c*").force_encoding("EUC-JP-MS")
  utf8 = tmp.encode("UTF-8")
  return utf8, utf8.codepoints.first
end

def parse(bdf)
  header = bdf.match(Regexp.new("(STARTFONT.*?)STARTCHAR",Regexp::MULTILINE))[1].lines(chomp:true)
  chars = bdf.scan(Regexp.new("STARTCHAR.*?ENDCHAR",Regexp::MULTILINE)).map{|char|
    char.lines(chomp:true)
  }
  return header, chars
end

def convert_a_char(char,encode)
  encoding = char.find{|l| l.start_with? "ENCODING" }
  _,enc = encoding.split
  if encode == :jisx0201
    utf8, codepoint = jisx0201_to_unicode enc.to_i
  elsif encode == :jisx0208
    utf8, codepoint = jisx0208_to_unicode enc.to_i
  elsif encode == :iso8859_1
    utf8, codepoint = iso8859_1_to_unicode enc.to_i
  end
  return nil unless codepoint
  # name = Unicode::Name.of(utf8)
  name = ("U%04X" % codepoint)
  if name.to_s.empty?
    raise "* [#{utf8}](#{codepoint}) unicode name not found"
  end
  newchar = [
    "STARTCHAR #{name}",
    "ENCODING #{codepoint}"
  ]+char.reject{|l| l.start_with?("ENCODING") || l.start_with?("STARTCHAR") }
  return newchar
end

def convert_header(header,xlfd,chars_size)
  newheader = header.dup
  prop_start = newheader.index{|l| l.start_with?("STARTPROPERTIES ") }
  prop_end   = newheader.index{|l| l.start_with?("ENDPROPERTIES") }
  props = newheader[prop_start..prop_end]
  props.reject!{|prop| prop.start_with? "_" }
  props[0] = "STARTPROPERTIES #{props.size-2}"
  newheader[prop_start..prop_end] = props
  newheader.size.times{|i|
    l = newheader[i]
    if l.start_with? "FONT "
      newheader[i] = "FONT #{xlfd}"
    elsif l.start_with? "CHARSET_REGISTRY "
      newheader[i] = "CHARSET_REGISTRY \"ISO10646\""
    elsif l.start_with? "CHARSET_ENCODING "
      newheader[i] = "CHARSET_ENCODING \"1\""
    elsif l.start_with? "CHARS"
      newheader[i] = "CHARS #{chars_size}"
    end
  }
  return newheader
end

def convert(encode,bdf,xlfd)
  bdf = bdf.gsub!(/^COMMENT.*\n/,"") # remove comment
  header,chars = parse(bdf)
  puts "Chars: #{chars.size}"
  puts "Convert Chars"
  newchars = []
  chars.each{|char|
    newchar = convert_a_char(char,encode)
    next unless newchar
    newchars << newchar
    # !!!: WAVE DASH PROBLEM
    if encode==:jisx0208 && newchar.find{|l| l.start_with? "ENCODING #{0xFF5E}" }
      puts "* Fullwidth Tilde [#{0xFF5E}] copy to Wave Dash [#{0x301C}]"
      wavedash = newchar.dup
      wavedash[0] = "STARTCHAR U301C"
      wavedash[1] = "ENCODING #{0x301C}"
      newchars << wavedash
    end
  }
  puts "#{newchars.size} characters converted"
  puts "Convert Header"
  newheader = convert_header(header,xlfd,newchars.size)
  # Done
  return newheader.join("\n")+"\n"+newchars.flatten.join("\n")+"\nENDFONT\n"
end


FileUtils.mkdir_p "tmp"

[
  "src/shnmk16.bdf", "-Shinonome0208-Gothic-Medium-R-Normal--16-150-75-75-C-160-ISO10646-1",
  "src/shnmk16b.bdf","-Shinonome0208-Gothic-Bold-R-Normal--16-150-75-75-C-160-ISO10646-1",
  "src/shnmk12.bdf", "-Shinonome0208-Gothic-Medium-R-Normal--12-110-75-75-C-120-ISO10646-1",
  "src/shnmk12b.bdf","-Shinonome0208-Gothic-Bold-R-Normal--12-110-75-75-C-120-ISO10646-1",
].each_slice(2){|src,xlfd|
  out = File.join("tmp", File.basename(src,".bdf")+"-unicode.bdf")
  puts "- Convert #{src} -> #{out}"
  bdf = File.read(src)
  unibdf = convert(:jisx0208,bdf,xlfd)
  File.write out,unibdf
}

[
  "src/shnm8x16r.bdf", "-Shinonome0201-Gothic-Medium-R-Normal--16-150-75-75-C-80-ISO10646-1",
  "src/shnm8x16rb.bdf","-Shinonome0201-Gothic-Bold-R-Normal--16-150-75-75-C-80-ISO10646-1",
  "src/shnm6x12r.bdf", "-Shinonome0201-Gothic-Medium-R-Normal--12-110-75-75-C-60-ISO10646-1",
  "src/shnm6x12rb.bdf","-Shinonome0201-Gothic-Bold-R-Normal--12-110-75-75-C-60-ISO10646-1",
].each_slice(2){|src,xlfd|
  out = File.join("tmp", File.basename(src,".bdf")+"-unicode.bdf")
  puts "- Convert(jisx0201) #{src} -> #{out}"
  bdf = File.read(src)
  unibdf = convert(:jisx0201,bdf,xlfd)
  File.write out,unibdf
}

[
  "src/shnm8x16a.bdf", "-Shinonomea8859-Gothic-Medium-R-Normal--16-150-75-75-C-80-ISO10646-1",
  "src/shnm8x16ab.bdf","-Shinonomea8859-Gothic-Bold-R-Normal--16-150-75-75-C-80-ISO10646-1",
  "src/shnm6x12a.bdf", "-Shinonomea8859-Gothic-Medium-R-Normal--12-110-75-75-C-60-ISO10646-1",
  "src/shnm6x12ab.bdf","-Shinonomea8859-Gothic-Bold-R-Normal--12-110-75-75-C-60-ISO10646-1",
].each_slice(2){|src,xlfd|
  out = File.join("tmp", File.basename(src,".bdf")+"-unicode.bdf")
  puts "- Convert(iso8859-1) #{src} -> #{out}"
  bdf = File.read(src)
  unibdf = convert(:iso8859_1,bdf,xlfd)
  File.write out,unibdf
}
