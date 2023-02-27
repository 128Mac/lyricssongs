#!/usr/bin/env ruby -

#require "date"
#require 'fileutils'
#require 'nkf'
#require 'nokogiri'
#require 'open-uri'
#require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGit'
require_relative 'myYomi'
#require_relative 'myConvertHtml2tex'
#require_relative 'myGetHtmlHash'
require_relative 'myGetLyricInfo'
require_relative 'myGetSongbookInfo'

def main

  if __FILE__ == $0 then
    ARGV.grep( /.htm$/ ).each do | html |
      next nil unless File.exist?( html )

      composer = File.basename( html, '.htm' )
      sbi       = MyGetSongbookInfo.new( html )

      if mm = sbi.songbookinfotitle.match(
           [
             "(.*[[#{$WAJI}]])",
             "[[:space:]]+",
             "([^[:space:]].*)",
           ].join
         )
        composer_name = [
          mm[1].sub( /([^,]+),(.*)/, '\2 \1'),
          mm[2] ]
      else
        composer_name =
          [ sbi.songbookinfotitle,
            sbi.songbookinfotitle
          ]
      end

      sectionsize = 0
      sbi.songbookinfolist.each do | e1 |
        e1.each do | e2 |
            case e2[:name]
            when 'a', 'p' then sectionsize += 1
            end
        end # e1.each do | e2 |
      end # sbi.songbookinfolist.each do | e1 |

      composer_section_filename_format =
        [ "#{composer}/#{composer}-section-",
          "%0#{( sectionsize - 1 ).to_s.size}d",
          ".tex",
        ].join

      # DONE セクション毎のファイル名 ... XXX/XXX-section-xxx.tex

      ( 0 .. sectionsize - 1 ).each do | ii |
        STDOUT.puts sprintf( composer_section_filename_format, ii )  if 1 == 0
      end

      # TODO toc list A
      # TODO toc list B
      # TODO Sxxx.tex
      sbi.songbookinfolist.each do | e1 |
        e1.each do | e2 |

          name = e2[:name]
          href = e2[:href]
          text = e2[:text]

          href = href.join( '/' ) if href.kind_of?( Array )

          # <a> や <p> の場合、先行する文字がないのでから文字追加
          # してデータ構造を単純化
          # text[0] ..... <a><p>に先行する文字
          # text[1] ..... タイトル
          # text[2..] ... その他情報
          text.unshift( "" ) unless text[0] =~ /^\d+\w*$/

          case e2[:name]
          when 'a', 'p' then sectionsize += 1
          end

          STDOUT.puts ["#{composer_name}",
                       "#{name}"             ,
                       "#{href}"             ,
                       "#{text}"             ,
                      ].join( "<>" ) if 1 == 0
          # TODO href のファイルの有無

          reference = nil
          lyricinfo = nil

          unless href.nil?

            if File.exist?( href )

             lyricinfo = MyGetLyricInfo.new( href )
             if 1 == 0
               puts ""
               puts [
                 # "#{lyricinfo.lyricinfo[:File]}",
                 # ":Title=>#{lyricinfo.lyricinfo[:Title]}",
                 ":Reference=>[#{lyricinfo.lyricinfo[:Reference]}]",
                 # ":Lyricist=>#{lyricinfo.lyricinfo[:Lyricist]}",
                 # ":Composer=>#{lyricinfo.lyricinfo[:Composer]}",
               ].join( "\n    " )
             end
             unless lyricinfo.lyricinfo[:Reference] == []
               reference = lyricinfo.lyricinfo[:Reference]
             end
            end
          end

          # DONE    あれば そのファイルから 整理番号情報を取り出す
          # DONE text を 原文 と 訳文 に分離

          if text[1].match(
               [ "^",
                 "([^#{$WAJI}]+)",
                 "[[:space:]]+",
                 "([^#{$WAJI}]*[#{$WAJI}].*)",
                 "$"
               ].join
             )
            info_title = [ $1, $2 ]
            info_title[0] =
              info_title[0].sub( /^■/, '' )
          else
            info_title = [ "", "" ]
          end

          info_lyric = [
            [ text[ 2 .. ] ].join
              .gsub( /[#{$WAJI}][^[:space:]]+/, '' )
              .gsub( /[[:space:]]+/ , ' ' )
              .gsub( /^[[:space:]]+/, ''  )
              .gsub( /[[:space:]]+$/, ''  ) ,
            [ text[ 2 .. ] ].join
              .gsub( /[^#{$WAJI}]{2,}/, '' )
              .gsub( /[[:space:]]+/ , ' ' )
              .gsub( /^[[:space:]]+/, ''  )
              .gsub( /[[:space:]]+$/, ''  ) ,
          ]
          # DONE text から 整理番号情報を取り出す
          if info_lyric[0].match( /(Op[.]|WoO|TrV|D )/ )
            tmp =
              info_lyric[0]
                .sub( /[[:space:]]*[(].*/, '')

            info_lyric[0] =
              info_lyric[0]
                .sub( /#{tmp}[[:space:]]*/, '' )

            reference = tmp if reference.nil?
          end
          reference = "" if reference.nil?

          puts "" if 1 == 1
          pp name, href, text, info_title, info_lyric, reference if 1 == 1 # DEBUG

          #xxx (
          #  {
          #    :composer => composer,
          #    :songbookinfotitle => songbookinfotitle,
          #    :name => name,
          #    :href => href,
          #    :text => text,
          #  }
          #)

        end # e1.each do | e2 |
      end # sbi.songbookinfolist.each do | e1 |
    end
  end
end

def xxx( ee )
  pp ee
end

def def_booklet( composerdir, html ) # TODO CHECK

  return nil unless File.exist?( html )

  doc = Nokogiri::HTML( File.read( html ) )

  title = doc.xpath( '/html/head/title' )

  return if doc.xpath( '//font' ).size < 1
  return if doc.xpath( '//td'   ).size < 1

  output = []
  info = []
  data = []

  doc.xpath( '//font' ).each_with_index do | ee, i |
    info[i] =
      ee.to_s
        .gsub( /[[:blank:]]*<\/*font[^<>]*>[[:blank:]]*/, '' )
        .gsub( /\n/ , ' ' )
        .gsub( /([[:space:]]|<br>)+/ , ' ' )
  end

  doc.xpath( '//td' ).each_with_index do | ee, i |
    data[i] =
      ee.to_s
        .sub( /^<[^<>]+>[[:space:]]*/, '' )
        .split( /[[:space:]]*<[^<>]+>[[:space:]]*/ )

  end

  data.each do | ee |   # 最後の要素が空だったら削除
    while ee.last.size == 0 do ee.pop end
  end

  if data[0].size == 2
    data[0][3] = nil
  end

  if data[0][3].nil?
    sec = sub = ""
  else
    sec = data[0][3].gsub( /([\w.]+\d+).*/, '\1' )
    sub = data[0][3].gsub( /.*(\d+)$/     , '\1' )
  end

  lyricist = []
  composer = []
  [ 5, 7 ].each do |i|
    if info[i].nil?
      lyricist[i] = ''
      composer[i] = ''
      next
    end

    lyricist[i] =
      info[i]
        .gsub( /[#{NIHONGO}]+/            , ' '      )
        .gsub( /[(][[[:space:]]]+[)]/     , ' '      )
        .gsub( /[(]([^()]+)[)]/           , '\1'     )
        .gsub( /,*([\d]{4})(-[\d]{4})*/   , '(\1\2)' )
        .gsub( /<[^<>]+>/                 , ' '      )
        .gsub( /[[[:space:]]]+/           , ' '      )
        .sub(  /^[[[:space:]],]+/         , ''       )
        .sub(  /[[[:space:]],]+$/         , ''       )

    composer[i] =
      info[i]
        .gsub( /[^#{NIHONGO}[:space:]]+/  , ' '      )
        .gsub( /(（[[:space:]]*）)/       , ''       )
        .gsub( /([（）])[[:space:]]+/     , '\1'     )
        .gsub( /[[[:space:]]]+/           , ' '      )
        .sub(  /^[[[:space:]],]+/         , ''       )
        .sub(  /[[[:space:]],]+$/         , ''       )
  end

  yomi = myYomi(data[1][1])
  basename = File.basename( html, ".htm" )

  output.push(
    [
      "\\mySUBSECTION{#{sec.gsub(/^[^\d]+/, '')}}{#{sub}}%#{sec}",
      "{ #{data[0][1]} }"  , # { Liebestreu }
      "{ #{data[1][1]} }"  , # { 愛の誠 }
      "{ #{lyricist[5]} }" , # { Robert Runic, (1805-1852) }
      "{ #{composer[5]} }" , # { Johannes Brahms, (1833-1897) }
      "{ #{lyricist[7]} }" , # { ライニック }
      "{ #{composer[7]} }" , # { ブラームス }
      "{ #{yomi} }"        , # { あいのまこと }
      "",
      "\\label{myindex:subsection:#{basename}}",
      "",
    ].join( "\n" )
  )

  output.push( "\\begin{myTBLR}[]" )
  ren_pushd = nil
  ( 2 .. data.size - 1 ).select( &:even? ).each do | oo |
    tt = oo + 1

    ( 0 .. [data[oo].size, data[tt].size].max - 1 ).each do | i |

      orig = data[oo][i].nil? ? '' : data[oo][i]
      tran = data[tt][i].nil? ? '' : data[tt][i]

      if ren_pushd.nil?
        next if orig.empty? && tran.empty?
        ren_pushd = true
      end

      if orig.empty? && tran.empty?
        output.push( "  \\\\%連間空行" )
      else
        output.push(
          [
            "  { #{orig} } &" ,
            "  { #{tran} }"   ,
            "  \\\\"
          ].join( "\n" )
        )
      end
    end
  end
  output.push( "\\end{myTBLR}" )

  ff = "#{composerdir}/#{basename}.tex"
  File.open( ff, "w" ) do | f |
    f.puts myConvertHtml2tex(
             output.join( "\n" )
           )
  end

end

def def_composer( composer, html ) # TODO CHECK

  return nil unless File.exist?( html )
  doc = Nokogiri::HTML( File.read( html ) )

  title = doc.xpath( '/html/head/title' )

  composer_A_file = [] # 分冊化された作曲集リスト
  composer_B_file = ""    # 小冊子毎
  composer_B_file_nbr = 0 #

  st = doc.xpath( '//p/b' ).size # TODO
  if st == 0                     # TODO
    p st
    raise
    return                       # TODO
  end                            # TODO

  doc
    .xpath( '//body' )
    .each_with_index do | body, body_ix | # doc.xpath('//body' ) {

    composerinfo = proc_010_composer_info( doc )
    next unless composerinfo

    repp  = '<p></p>'

    doc.to_html
      .split( /(#{repp})/ ).each do | dir_p_a |

      dir_p_a = proc_030_dir_p_a( dir_p_a )
      next if ( dir_p_a.size < 1 )

      composer_B_file_nbr += 1
      composer_B_file =
        sprintf( "#{composer}/#{composer}-B-%03d.tex",
                 composer_B_file_nbr
               )

      proc_033_composer_B_file( dir_p_a, composer, composer_B_file )

      composer_A_file.push( "\\input{#{composer_B_file}}" )
    end

    proc_composer_A_file(
      composer, composerinfo, composer_A_file
    )
  end # doc.xpath('//body') }
end

def proc_010_composer_info( doc ) # TODO CHECK

  re1 = "[^[:blank:]]+" # 日本語表記
  re2 = "[^,()]+"       # 名前スペル
  re3 = "[^()]+"        # 誕生年-死亡年
  re4 = ".*"            # 国名

  composerinfo =
    doc.xpath('//p')[1].text
      .gsub( /\n/, '' )
      .match(/(#{re1})[[:blank:]]+[(](#{re2}),(#{re3})[)][[:blank:]]+(#{re4})/)

  composerinfo
end

def proc_030_dir_p_a( tt ) # TODO CHECK

  tt = '' if tt =~ /(!DOCTYPE html PUBLIC|更新情報へ|曲目一覧)/
  tt = tt.gsub( /(>)[[:blank:]]+/                    , '\1' )
         .gsub( /[[:blank:]]+(>)/                    , '\1' )
         .gsub( /<(hr|dir)>/                         , '' )
         .gsub( /[[:blank:]]+(\d)/                   , ' \1' )
         .gsub( /[[:blank:]]+(\n)/                   , '\1' )
         .gsub( /(\n)+/                              , '\1' )
         .gsub( /[[:blank:]]*<p><b>(■)([^<][^<>]*)/ , '\1<a href="">\2</a>' )
         .gsub( /<\/*(p|b|body|html|dir)>/            , ''   )
         .sub(  /^[[:space:]]+/, '').sub( /[[:space:]]+$/, '' )
  tt
end

def proc_033_composer_B_file( items, composer_dir, composer_B_filename ) # TODO CHECK

  composer_B_file            = []
  composer_linder_input_file = []
  composer_linder_longtblr   = [] # 小目次情報
  myOpTitleORIG = '' # Op. / WoO / other
  baseOpID      = ''

  items.split(/<br>[[:space:]]*/).each do | item |

    re = [
      '(.*)'     , # m[1] ■  数字、空白
      '[[:blank:]]*<a href=' ,
      '"(.*)"'   , # m[2] ../TEXT/Sxxx.htm 空
      '>'        ,
      '([^<>]*)' , # m[3] 題名
      '<\/a>'    ,
      '(.*)'     , # m[4] OP 番号、年情報、その他情報
    ].join

    m = item.gsub( /[[:blank:]]+</, '<' ).match( /#{re}/ )
    if m
      if 1 == 0
        puts "<#{m[1]}><#{m[2]}><#{m[3]}><#{m[4]}>"
        puts item
        puts "#{m[2]}"
      end
    else
      puts ">>#{item}<<"
      raise
    end

    nihongo = '\p{hani}\p{hira}\p{kana}ー「」（）。、：・０-９'
    idx = []
    idx[0] = m[1] # ■ 番号 空
    idx[1] = File.basename( m[2], ".htm" ) # ファイル名情報
    idx[2] = m[3].sub( /([^#{nihongo}]+)([#{nihongo}].*)/, '\1' )#原題
               .sub( /[[:space:]]+$/, '' )
    idx[3] = m[3].sub( /([^#{nihongo}]+)([#{nihongo}].*)/, '\2' )#訳題

    mm = m[4].match( /(.*)([(][^()]+[)])(.*)/ )
    if mm
      idx[4] = mm[1] # Op 番号
      idx[5] = mm[2] # 年情報
      idx[6] = mm[3] # 監修者等（原語）
      idx[7] = mm[3] # 監修者等（訳語）
    else
      idx[4] = m[4] # Op 番号
      idx[5] = ''   # 年情報
      idx[6] = m[4] # 監修者等（原語）
      idx[7] = m[4] # 監修者等（訳語）
    end
    idx[4] = idx[4].gsub( /[^\w\d.]+/  , '-' )
               .sub( /^-+/             , ''  )
               .sub( /-+$/             , ''  )
    idx[6] = idx[6].gsub( /[^\w\d.]+/  , ''  )
               .sub( /#{idx[4]}/       , ''  )
    idx[7] = idx[7].gsub( /[\w\d.]+/   , ''  )
               .sub( /原詩：$/         , ''  )
    idx.each_with_index do | e , i |
      idx[i] = idx[i]
                 .sub( /^[[:space:]]+/ , ''  )
                 .sub( /[[:space:]]+$/ , ''  )
    end
    baseOpID = idx[4] if baseOpID.size == 0 && idx[4].size > 0
    idx[4] = baseOpID if baseOpID.size > 0 && idx[4].size == 0

    if idx[0] == '■' # プログラム的には <p><b> を一レコードとして扱う
      idx[8] = myYomi( idx[3] )

      composer_linder_input_file.push(
        '\mySECTION' +
        "{ #{idx[4].gsub(/^[^\d]+/, '').gsub(/-.*/, '')} }" + "%#{idx[4]}" ,
        "{ #{idx[2]} }" + '%' ,
        "{ #{idx[3]} }" + '%書名・詩集名' ,
        "{ #{idx[6]} }" +
        "{ #{idx[7]} }" +
        "{ #{idx[5]} }" + '%監修者等(原・訳)、年情報' ,
        "{ #{idx[8]} }" + '%よみ' ,
        '' , ''
      )
    else # DONE 3-3-1-2) 小目次情報（■以外の時)

      myOpTitleTRAN = '' # 作品 / 整理番号 / 作品
      myOpTitleHash = {
        "WoO" => "整理番号：",
      }
      tmpORIG = idx[4].sub( /(Op[.]|\w+).*/, '\1' )
                  .gsub( /\d+/, '')
      tmpTRAN = myOpTitleHash.fetch( tmpORIG, "作品" )

      composer_linder_longtblr.push(
        "% #{idx[4]} #{idx[1]}" ,
        "   #{tmpORIG}#{idx[0]} & #{idx[2]} \\dotfill",
        " & #{tmpTRAN}#{idx[0]} & #{idx[3]} \\dotfill",
        " & \\pageref{myindex:subsection:#{idx[1]}}",
        '\\\\%'
      )

      if ( tmpORIG == "Op." ) && ( tmpTRAN == "作品" )
        composer_B_file.push( "\\input{#{composer_dir}/#{idx[1]}.tex}" )
      else
        composer_B_file.push(
          [
            "{",
            "   \\renewcommand{\\myOpTitleORIG}{#{tmpORIG}}",
            "   \\renewcommand{\\myOpTitleTRAN}{#{tmpTRAN}}",
            "   \\input{#{composer_dir}/#{idx[1]}.tex}" ,
            "}",
          ].join( "\n" )
        )
      end
    end
  end

  if ( composer_linder_longtblr.size > 0 )
    composer_linder_longtblr.unshift(
      '\begin{longtblr}{ colspec = { c X c X r } }'
    )
    composer_linder_longtblr.push(
      '\end{longtblr}', "\n"
    )
  end

  File.open( composer_B_filename, "w" ) do | f |
    f.puts myConvertHtml2tex(
             [
               composer_linder_input_file ,
               composer_linder_longtblr   ,
               composer_B_file            ,
             ].flatten.join( "\n" )
           )
  end
end

def proc_composer_A_file( composer, composerinfo, composer_a_file ) # TODO CHECK

  composerTEMPLATE  = "sty/lieder-template.tex"
  composerTEXFILE = "#{composer}/#{composer}.tex"
  composerTEXFILEhyperlink = "#{composer}/#{composer}-hyper-link.tex"

  File.open( composerTEXFILE, "w" ) do | f |
    f.puts File.read( composerTEMPLATE )
             .sub( /%%--COMPOSER--%%/     , composerinfo[2] )
             .sub( /%%--COMPOSERINFO--%%/ , composerinfo[0] )
             .sub( /%%--作曲家--%%/ , composerinfo[1] )
             .sub( /%%--INPUT--%%/ , "#{composer_a_file.join("\n")}" )

  end

  File.open( composerTEXFILEhyperlink, "w" ) do | f |
    f.puts File.read( composerTEXFILE )
             .sub( /^%%(\\usepackage)/, '')
  end
end

if __FILE__ == $0 then main end
