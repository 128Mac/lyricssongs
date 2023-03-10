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
    tmpB = []
    fontinfo.each_with_index do | ee, ii |

      tmpA.push(
        ee.to_html
          #.gsub(  /<a ([^<>]*)>/ , '<A>\1<A>'         ) # 将来の作曲者や作詞者情報が必要になった時
          .gsub(   /[[:space:]]+/ , ' '                )
          .split(  /[[:space:]]*<[^<>]+>[[:space:]]*/  )
          .reject( &:empty?                            )
      )

      tmpBsub =
        ee.to_html
          .gsub( /<[^<>]+>/     , ''  )
          .gsub( /[[:space:]]+/ , ' ' )
          .sub(  /^[[:space:]]+/, ''  )
          .sub(  /[[:space:]]+$/, ''  )
          .gsub( /(詩：.*[(][^()]+[)][[:space:]]*[#{$WAJI}]+)/, '\1' + "\\par\\hspace{4em}"  )

      while tmpBsub.match( /(.*)([[:space:]]*&amp;[[:space:]]*)(.*)/ ) # & の特殊処理
        tmpBsub = $1 + " \\& " + $3
      end
      tmpB.push( tmpBsub )
    end

    tmpA.push( [], [], [] )
    tmpB =
      tmpB.join( " " )
        .gsub(  /[[:space:]]*(曲：)/, "\n" + '\1' )
        .gsub(  /[[:blank:]]+([#{$WAJI}]+：)/, '　\1' )
        .split( "\n" )

    lyricist = [ tmpA[0] + tmpA[1] , tmpA[0] + tmpA[1] ]
    composer = [ tmpA[2]           , tmpA[2]           ]
    miscinfo = tmpB

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
            .gsub( /[[:space:]]+/, '　' )
            .sub(  /^[[:space:]]+/, '' )
            .sub(  /[[:space:]]+$/, '' )
      else
        poemdata.push(
          ee.to_html
            .gsub(  /(<b>|<[^b][^<>]*>)/    , ''   ) # <br> 以外の html tag 削除
            .gsub(  /[[:space:]]+(<br>)/    , '\1' )
            .sub(   /^[[:space:]]+/         , ''   ) # 先頭の空白削除
            .sub(   /(<br>|[[:space:]]+)+$/ , ''   ) # 最後の <br> を含む空白を削除
            .split( /<br>/ )
        )
        # /body/table/tbody/tr/td
        # /body/table/tbody/tr/td/dir ← インデントが必要なケース
        if ee.xpath( 'dir' ).to_html.size > 0
          indentglue =
            poemdata[-1].each_with_index do | e, i |
            if e.size > 0
              poemdata[-1][i] = " ~ ~ ~ ~  #{poemdata[-1][i]}"
              # TODO FIX see https://tex.stackexchange.com/questions/675331/tabularray-expand-multiple-macros-with-background-color
            end
          end
        end
      end
    end

    def l0l1c0c1( ee, pp )

      ee =
        ee.join( ' ' ) # from array
          .gsub( /（([^（）#{$WAJI}]+)）/, '(\1)' ) # 全角丸カッコを半角化
          .gsub( /[(]([#{$WAJI}]+)[)]/, '（\1）' ) # 半角丸カッコで囲まれた和字
          .gsub( /[#{pp}]+/       , ' ' ) # 違うところ
          .sub(  /^[[:space:],]+/ , ''  )
          .sub(  /[[:space:]]+$/  , ''  )

      while  ee.match( /(.*)([[:space:]]*&amp;[[:space:]]*)(.*)/ )
        ee = $1 + " \\& " + $3
      end

      ee
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
      :Miscinfo  => miscinfo,
      :Lyric     => poemdata,
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
      ":Miscinfo=>#{lyricinfo.lyricinfo[:Miscinfo]}"
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
