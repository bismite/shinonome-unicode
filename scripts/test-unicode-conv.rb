#!/usr/bin/env ruby
require "unicode/name"
require "colorize"

def check(char,enc)
  cp = "0x%04x" % char.codepoints.first
  name = Unicode::Name.of(char)
  begin
    encoded = char.encode(enc)
  rescue
    puts "[#{char}](#{cp},#{name}) >< [#{enc}]UNDEFINED".yellow
    return
  end
  encoded_bytes = "0x"+encoded.bytes.map{|b| "%02X" % b }.join
  conv = encoded.encode("UTF-8")
  if conv == char
    puts "[#{char}](#{cp},#{name}) <=> [#{enc}]#{encoded_bytes}".green
  else
    # oops
    conv_cp = "0x%04x" % conv.codepoints.first
    conv_name = Unicode::Name.of(conv)
    puts "#{char}(#{cp},#{name}) -> [#{enc}]#{encoded_bytes} -> [UTF-8]#{conv}(#{conv_cp},#{conv_name})".red
  end
end

#　雑多な確認用
WAVEDASH = "〜"
F_TILDE = "～"
ASCII_MINUS="-"
MINUS="−"
F_MINUS="－"
ANGSTROM_SIGN = "\u212B"
A_WITH_RING = "\u00C5"
MULTI_SIGN = "\u00D7"
VEXTOR_OR_CROSS_PRODUCT = "\u2A2F"
[
  "¡",
  "¹",
  MULTI_SIGN, VEXTOR_OR_CROSS_PRODUCT,
  "Æ",
  F_TILDE, WAVEDASH, "~",
  "‾","￣",
  "√","∵",
  "〇","○",
  ANGSTROM_SIGN, A_WITH_RING,
  "∀",
  ASCII_MINUS, MINUS, F_MINUS,
  "£","￡","¬","￢","＼","\\","¥","￥"
].each{|c|
  check c,"EUC-JP"
  check c,"EUC-JP-MS"
  check c,"SJIS"
  check c,"CP932"
}
