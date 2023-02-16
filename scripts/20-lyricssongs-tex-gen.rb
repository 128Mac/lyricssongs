#!/usr/bin/env ruby -

require "date"
require 'fileutils'
require 'nkf'
require 'nokogiri'
require 'open-uri'
require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGit'
require_relative 'myYomi'
require_relative 'myConvertHtml2tex'
require_relative 'myGetHtmlHash'

def main

  tomlfile = ARGV.grep( /.toml$/ )
  if tomlfile.size == 0
    puts "Usage: ruby #{$0} xxx.toml ..."
    exit
  end

  myGetHtmlHash( myGetTomlHash( tomlfile ) ).each do | composer, htmlfiles |

    git_auto_committed = nil

    htmlfiles.each do | htmlfile |
      next unless htmlfile.match( /.htm/ )
      next nil unless File.exist?( htmlfile )

      if git_auto_committed.nil?
        # DONE 2) git で composer ディレクトリを作成しておく
        myGit( composer, '!*.tex' )
        git_auto_committed = true
      end

      doc = Nokogiri::HTML( File.read( htmlfile ) )

      if doc.xpath( '//p/b' ).size < 1
        def_booklet( composer, htmlfile )
      else
        def_composer( composer, htmlfile )
      end
    end
  end
end

NIHONGO = [
  '\p{hani}\p{hira}\p{kana}ー' , # 所謂日本語漢字、ひらがな、カタカナ
  '「」『』（）'               , # 括弧類
  '．，。、'                   , # 句読点
  '：・'                       , # 記号類
  '０-９'                      ,
].join

def def_booklet( composerdir, html )

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
    # info[1] タイトル（原題）・・・ Liebestreu
    # info[2] 作品番号など・・・・・ Op.3-1 Sechs Gesänge
    # info[3] タイトル（邦訳）・・・ 愛の誠
    # info[4] 作品集名・・・・・・・ ６つの歌
    # info[5] 作詞者情報
    # info[6] その他情報
    # info[7] 左曲射情報
  end

  doc.xpath( '//td' ).each_with_index do | ee, i |
    data[i] =
      ee.to_s
        .sub( /^<[^<>]+>[[:space:]]*/, '' )
        .split( /[[:space:]]*<[^<>]+>[[:space:]]*/ )

    # data[0][1] タイトル（原題）・・ Liebestreu
    # data[0][3] 作品番号・・・・・・ Op.3-1
    # data[0][4] 作品集名（原題）・・ Sechs Gesänge
    # data[1][1] タイトル（邦訳）・・ 愛の誠
    # data[1][4] 作品集名（邦訳）・・ ６つの歌
    # data[2 以上の偶数] 原文
    # data[3 以上の奇数] 訳文
  end

  data.each do | ee |   # 最後の要素が空だったら削除
    while ee.last.size == 0 do ee.pop end
  end

  # puts "#{data.size}  #{html}" # TODO
  # TODO 102 2 TEXT/SET4038.htm
  # TODO 18 2 TEXT/SET6316.htm

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
      "\\mySUBSECTION{#{sec}}{#{sub}}",
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

def def_composer( composer, html )

  return nil unless File.exist?( html )
  doc = Nokogiri::HTML( File.read( html ) )

  title = doc.xpath( '/html/head/title' )

  # [#{composer}]/[#{composer}].tex
  #      \documentclass{...}
  #      mktitle 情報
  #      \begin{document}
  #      \input{[#{composer}]/[#{composer}]-A-[xx].tex}
  composer_A_file = [] # 分冊化された作曲集リスト
  #      \end{document}
  # [#{composer}]/[#{composer}]-B-[xx].tex
  composer_B_file = ""    # 小冊子毎
  composer_B_file_nbr = 0 #
  #      \begin{longtblr}
  #      ....
  #composer_linder_longtblr = [] #
  #      \end{longtblr}
  #      \input{op/Sxxx.tex}
  #composer_linder_input_file = [] #

  st = doc.xpath( '//p/b' ).size # TODO
  if st == 0                     # TODO
    p st
    raise
    return                       # TODO
  end                            # TODO

  doc
    .xpath( '//body' )
    .each_with_index do | body, body_ix | # doc.xpath('//body' ) {

    # DONE 1) composer 及び composerinfo 入手

    composerinfo = proc_010_composer_info( doc )
    next unless composerinfo

    # DONE 3) ■で始まる行毎に分冊にする
    repp  = '<p></p>'

    doc.to_html
      .split( /(#{repp})/ ).each do | dir_p_a |

      dir_p_a = proc_030_dir_p_a( dir_p_a )
      next if ( dir_p_a.size < 1 )

      # DONE 3-1) composer_A_file 用のカウンタ xx アップ
      composer_B_file_nbr += 1
      # DONE 3-2) composer_A_file の配列に composer}]-linder-[xx].tex
      composer_B_file =
        sprintf( "#{composer}/#{composer}-B-%03d.tex",
                 composer_B_file_nbr
               )

      # DONE 3-3) 小目次情報
      proc_033_composer_B_file( dir_p_a, composer, composer_B_file )

      # DONE 4) composer_A_file 出力
      composer_A_file.push( "\\input{#{composer_B_file}}" )
    end

    proc_composer_A_file(
      composer, composerinfo, composer_A_file
    )
  end # doc.xpath('//body') }
end

def proc_010_composer_info( doc )

  re1 = "[^[:blank:]]+" # 日本語表記
  re2 = "[^,()]+"       # 名前スペル
  re3 = "[^()]+"        # 誕生年-死亡年
  re4 = ".*"            # 国名

  # => #<MatchData "ブラームス (Johannes Brahms,1833-1897) ドイツ"
  # composer[1] "ブラームス"
  # composer[2] "Johannes Brahms"
  # composer[3] "1833-1897"
  # composer[4] "ドイツ"

  composerinfo =
    doc.xpath('//p')[1].text
      .gsub( /\n/, '' )
      .match(/(#{re1})[[:blank:]]+[(](#{re2}),(#{re3})[)][[:blank:]]+(#{re4})/)

  composerinfo
end

def proc_030_dir_p_a( tt )

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

def proc_033_composer_B_file( items, composer_dir, composer_B_filename )

  composer_B_file            = []
  composer_linder_input_file = []
  composer_linder_longtblr   = [] # 小目次情報
  myOpTitleORIG = '' # Op. / WoO / other
  baseOpID      = ''

  items.split(/<br>[[:space:]]*/).each do | item |
    # puts "debug #{composer_B_file} [#{item}]"

    # DONE 3-3-1) 小目次情報の収集(Op 番号、原題、訳題、Sxxx.htm)
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
    # ヘッダー部分の ■ には Op. 情報が記載されているので明細部で不足していたら補う
    baseOpID = idx[4] if baseOpID.size == 0 && idx[4].size > 0
    idx[4] = baseOpID if baseOpID.size > 0 && idx[4].size == 0

    # DONE 3-3-1-1) SECTION 情報（■の時)
    if idx[0] == '■' # プログラム的には <p><b> を一レコードとして扱う
      # DONE 3-3-1-1-1) タイトルのよみ
      idx[8] = myYomi( idx[3] )
      # DONE 3-3-1-1-2) SECTION 情報を composer_linder_input_file 出力用配列に追加
      composer_linder_input_file.push(
        '\mySECTION' +
        "{ #{idx[4]} }" + '%' ,
        "{ #{idx[2]} }" + '%' ,
        "{ #{idx[3]} }" + '%書名・詩集名' ,
        "{ #{idx[6]} }" +
        "{ #{idx[7]} }" +
        "{ #{idx[5]} }" + '%監修者等(原・訳)、年情報' ,
        "{ #{idx[8]} }" + '%よみ' ,
        '' , ''
)
    else # DONE 3-3-1-2) 小目次情報（■以外の時)
      # DONE 3-3-1-2-1) 小目次情報を作成し composer_linder_longtblr の配列に追加

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

  # DONE 3-3-2} composer_B_file ファイル出力
  # DONE 3-3-2-1) composer_linder_longtblr の前後に table の begin / end を補う
  # DONE 3-3-2-2) composer_linder_input_file を末尾に補う
  #puts composer_linder_longtblr.join( "\n" )
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

def proc_composer_A_file( composer, composerinfo, composer_a_file )

  composerTEMPLATE  = "sty/lieder-template.tex"
  composerTEXFILE = "#{composer}/#{composer}.tex"
  composerTEXFILEhyperlink = "#{composer}/#{composer}-hyper-link.tex"

  File.open( composerTEXFILE, "w" ) do | f |
    f.puts File.read( composerTEMPLATE )
             .sub( /%%--COMPOSER--%%/     , composerinfo[2] )
             .sub( /%%--COMPOSERINFO--%%/ , composerinfo[0] )
             .sub( /%%--作曲家--%%/ , composerinfo[1] )
             .sub( /%%--INPUT--%%/ , "#{composer_a_file.join("\n")}" )
    # composerinfo[0] "ブラームス (Johannes Brahms,1833-1897) ドイツ"
    # composerinfo[1] "ブラームス"
    # composerinfo[2] "Johannes Brahms"
    # composerinfo[3] "1833-1897"
    # composerinfo[4] "ドイツ"

    # \title{\uppercase{%%--COMPOSER--%%} \footnote{%%--COMPOSERINFO--%%}
    # \\ %%--作曲家--%% 歌曲集
    # %%--INPUT--%%
  end

  File.open( composerTEXFILEhyperlink, "w" ) do | f |
    f.puts File.read( composerTEXFILE )
             .sub( /^%%(\\usepackage)/, '')
  end
  #
  #[ composerTEXFILE, composerTEXFILEhyperlink].each { | f |
  #  ff = File.basename(f)
  #  File.delete(ff) if File.exist?(ff)
  #  File.symlink(f , File.basename(f))
  #}
end

if __FILE__ == $0 then main end
