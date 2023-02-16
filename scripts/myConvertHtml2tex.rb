#!/usr/bin/env ruby

def myConvertHtml2tex(str)

  convert_pattern_HASH = {
    '[[:blank:]]*“[[:blank:]]*' => ' {\glqq}' ,
    '[[:blank:]]*”[[:blank:]]*' => '{\grqq} ' ,
    '([^{])[[:blank:]]+([IV][IV]*[()]*)[[:space:]]*' => '\1 \textrm{\2}\3 ',
    '([^{])[[:blank:]]+([IV][IV]*)[[:space:]]*([（])' => '\1 \textrm{\2} \3',
    '_' => '\\_',
  }

  convert_pattern_HASH.each do | ee, vv |

    re = Regexp.new( ee )

    mm = str.match( re )
    str = str.gsub( /#{re}/, vv ) if mm
  end
  str
end
