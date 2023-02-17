#!/usr/bin/env ruby

require 'cgi'

def main_myConvertHtml2tex
  ARGV.each do | ee |
    puts "<#{ee}><#{myConvertHtml2tex( ee )}>"
  end
end

def myConvertHtml2tex(str)

  convert_pattern_HASH = {
    '[[:blank:]]*“[[:blank:]]*' => ' {\glqq}' ,
    '[[:blank:]]*”[[:blank:]]*' => '{\grqq} ' ,
    '([[:blank:]]+)(I*[VI])([^A-HJUX-Za-zäöüÄÖÜß:<]{2,5})' => ' \textrm{\2}\3',
    '_' => '\\_',
  }

  re = Regexp.new( '&\w+;' )
  mmm = str.match( re )
  str = CGI.unescapeHTML str

  convert_pattern_HASH.each do | ee, vv |

    re = Regexp.new( ee )

    mmm = str.match( re )
    str = str.gsub( /#{re}/, vv ) if mmm
  end
  str
end

if __FILE__ == $0 then main_myConvertHtml2tex end
