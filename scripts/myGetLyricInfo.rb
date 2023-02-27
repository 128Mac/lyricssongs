#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGlobalValue'

class MyGetLyricInfo

  def initialize( html )

    return nil unless File.exist?( html )

    doc = Nokogiri::HTML( File.read( html ) )

    fontinfo = doc.xpath( '/html/body/font' )

    return nil if fontinfo.size == 0

    tmpA = []

    fontinfo.each_with_index do | ee, ii |

      tmpA.push(
        ee.to_s
          #.gsub(  /<a ([^<>]*)>/ , '<A>\1<A>'         ) # 将来の作曲者や作詞者情報が必要になった時
          .gsub(   /[[:space:]]+/ , ' '                )
          .split(  /[[:space:]]*<[^<>]+>[[:space:]]*/  )
          .reject( &:empty?                            )
      )
    end

    tmpA.push( [], [], [] )
    lyricist = [ tmpA[0] + tmpA[1] , tmpA[0] + tmpA[1] ]
    composer = [ tmpA[2]           , tmpA[2]           ]

    tmp = doc.xpath( '/html/body/table' )

    return nil if tmp.size == 0

    titleTRAN = ""
    titleORIG = ""
    reference = ""
    poemdata = []

    doc.xpath( '//table/tbody/tr/td' ).each_with_index do | ee, ii |

      tmp1 = []
      tmp2 = []

      case ii
      when 0 then

        ee.to_s
          .split( /[[:space:]]*<[^<>]+>[[:space:]]*/ )
          .each do | eee |

          case eee
          when /^[^\d].*\d/ then tmp2.push( eee )
          when /^$/         then
          else
            tmp1.push( eee )
          end
        end
        titleORIG = tmp1.join( ' ' )
        reference = tmp2.join( ' ' ).gsub( /[[:blank:]]+/, " ")

      when 1 then
        tmp1 = []
        ee.to_s
          .split( /[[:space:]]*<[^<>]+>[[:space:]]*/ )
          .each do | eee |

          case eee
          when /^$/ then
          else
            tmp1.push( eee )
          end
        end

        titleTRAN  = tmp1.join( ' ' )

      else
        poemdata.push(
          ee.to_html
            .gsub(  /(<b>|<[^b][^<>]*>)/                      , ''   ) # <br> 以外の html tag 削除
            .sub(   /^[[:space:]]*(<br>|[[:space:]])/         , ''   ) # 先頭の空白削除
            .sub(   /[[:space:]]+(<br>)/                      , '\1' )
            .sub(   /(<br>[[:space:]]*)*(<br>|[[:space:]])*$/ , ''   ) # 最後の <br> を含む空白を削除
            .split( /<br>/                          )
        )
      end
    end

    l1 = lyricist[0].join( ' ' ).gsub( /[#{$WAJI}]+/  , ' ' ).sub( /^[[:space:],]+/ , '' ).sub( /[[:space:]]+$/ , '' )
    l2 = lyricist[1].join( ' ' ).gsub( /[^#{$WAJI}]+/ , ' ' ).sub( /^[[:space:],]+/ , '' ).sub( /[[:space:]]+$/ , '' )
    c1 = composer[0].join( ' ' ).gsub( /[#{$WAJI}]+/  , ' ' ).sub( /^[[:space:],]+/ , '' ).sub( /[[:space:]]+$/ , '' )
    c2 = composer[1].join( ' ' ).gsub( /[^#{$WAJI}]+/ , ' ' ).sub( /^[[:space:],]+/ , '' ).sub( /[[:space:]]+$/ , '' )

    @lyricinfo = {
      :File      => html,
      :Title     => [ titleORIG , titleTRAN ],
      :Reference => reference,
      :Lyricist  => [ l1, l2 ],
      :Composer  => [ c1, c2 ],
      :Lyric     => poemdata
    }
  end

  def lyricinfo
    @lyricinfo
  end
end

if __FILE__ == $0 then

  ARGV.grep( /.htm$/ ).each do | html |
    next unless File.exist?( html )

    lyricinfo = MyGetLyricInfo.new( html )
    puts ""
    puts [
      "#{lyricinfo.lyricinfo[:File]}",
      ":Title=>#{lyricinfo.lyricinfo[:Title]}",
      ":Reference=>[#{lyricinfo.lyricinfo[:Reference]}]",
      ":Lyricist=>#{lyricinfo.lyricinfo[:Lyricist]}",
      ":Composer=>#{lyricinfo.lyricinfo[:Composer]}",
    ].join( "\n    " )
    #puts lyricinfo.lyricinfo[:Lyric]
  end
end
