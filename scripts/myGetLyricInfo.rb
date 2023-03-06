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
        ee.to_html
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

        ee.to_html
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

        re = [ # 作品タイトル名にの整理番号は除去 / 英字で始まり . - 数字を含むもの
          '(', [ 'Op[.]', 'WoO[ .]', 'TrV ', 'AV ', 'D ', ].join( '|' ), ')',
          '(', '\d', '[-/,\d\w]*', ')',
        ].join

        titleTRAN =
          ee.to_html
            .gsub( /[[:space:]]*<[^<>]+>/, '' )
            .gsub( /(#{re})/, '　' )
            .sub(  /^[[:space:]]+/, '' )
            .sub(  /[　[:space:]]+$/, '' )
            .gsub( /[[:space:]]+/, '　' )

      else
        poemdata.push(
          ee.to_html
            .gsub(  /(<b>|<[^b][^<>]*>)/    , ''   ) # <br> 以外の html tag 削除
            .gsub(  /[[:space:]]+(<br>)/    , '\1' )
            .sub(   /^[[:space:]]+/         , ''   ) # 先頭の空白削除
            .sub(   /(<br>|[[:space:]]+)+$/ , ''   ) # 最後の <br> を含む空白を削除
            .split( /<br>/ )
        )
      end
    end

    def l0l1c0c1( ee, pp )
      ee.join( ' '                     )
        .gsub(  /[#{pp}]+/       , ' ' ) # 違うところ
        .sub(   /^[[:space:],]+/ , ''  )
        .sub(   /[[:space:]]+$/  , ''  )
    end

    l0 = l0l1c0c1( lyricist[0], "#{$WAJI}"  )
    l1 = l0l1c0c1( lyricist[1], "^#{$WAJI}" )
    c0 = l0l1c0c1( composer[0], "#{$WAJI}"  )
    c1 = l0l1c0c1( composer[1], "^#{$WAJI}" )

    @lyricinfo = {
      :File      => html,
      :Title     => [ titleORIG , titleTRAN ],
      :Reference => reference,
      :Lyricist  => [ l0, l1 ],
      :Composer  => [ c0, c1 ],
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
      # ":Lyric=>#{lyricinfo.lyricinfo[:Lyric]}",
    ].join( "\n    " )

    array = []

    ( 0 .. lyricinfo.lyricinfo[:Lyric].size - 1 )
      .select( &:even? ).each do | i |

      array.push( "  \\\\" ) if i > 0

      tmpi = lyricinfo.lyricinfo[:Lyric][i+0].size
      tmpj = lyricinfo.lyricinfo[:Lyric][i+1].size
      if tmpi < tmpj
        ( tmpi .. tmpj - 1 )
          .each do | j |
          lyricinfo.lyricinfo[:Lyric][i+0][j] = ""
        end
      end

      lyricinfo.lyricinfo[:Lyric][i+0]
        .zip( lyricinfo.lyricinfo[:Lyric][i+1] )
        .each_with_index do | jj |

        if  jj.join.size  > 0
          tmp = sprintf "  { %-40s } & { %s } \\\\", jj[0], jj[1]
          array.push( tmp )
        else
          array.push( "  \\\\% 連間空行" )
        end
      end
    end
    puts array
  end
end
