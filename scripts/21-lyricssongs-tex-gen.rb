#!/usr/bin/env ruby -

require "date"
#require 'fileutils'
#require 'nkf'
#require 'nokogiri'
#require 'open-uri'
#require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGit'
require_relative 'myYomi'
require_relative 'myConvertHtml2tex'
#require_relative 'myGetHtmlHash'
require_relative 'myGetLyricInfo'
require_relative 'myGetSongbookInfo'

def main

  if __FILE__ == $0 then

    htmlfilescount = ARGV.grep( /.htm$/ ).size

    ARGV.grep( /.htm$/ ).each_with_index do | compfile, number |
      next nil unless File.exist?( compfile )

      STDERR.puts [ "#{number+1} / #{htmlfilescount}",
                    DateTime.now.strftime( "%F %T" ),
                    "#{compfile}",
                  ].join( ' ' )

      htmlfilescount -= 1

      composer = File.basename( compfile, '.htm' )

      myGit( composer, '!*.tex' )

      sbi = MyGetSongbookInfo.new( compfile )

      if mm = sbi.songbookinfotitle.match(
           [
             "(.*[[#{$WAJI}]])" ,
             "[[:space:]]+"     ,
             "([^[:space:]].*)" ,
           ].join
         )
        composer_name = [
          mm[1].sub( /([^,]+),(.*)/, '\2 \1'),
          mm[2] ]
      else
        composer_name =
          [ sbi.songbookinfotitle ,
            sbi.songbookinfotitle
          ]
      end

      sectioncount = 0
      sbi.songbookinfolist.each do | e1 |
        e1.each do | e2 |
          case e2[:name]
          when 'a', 'p' then sectioncount += 1
          end
        end # e1.each do | e2 |
      end # sbi.songbookinfolist.each do | e1 |

      composer_section_filename_format =
        [ "#{composer}/#{composer}-section-"    ,
          "%0#{( sectioncount - 1 ).to_s.size}d" ,
          ".tex"                                ,
        ].join

      # DONE セクション毎のファイル名 ... XXX/XXX-section-xxx.tex

      if 1 == 0 # DEBUG
        ( 0 .. sectioncount - 1 ).each do | ii |
          STDOUT.puts sprintf( composer_section_filename_format, ii )
        end
      end

      bookARRAY    = []
      sectionARRAY = []
      sectioncount = 0
      output_filename_of_section = ""

      sbi.songbookinfolist.each do | e1 |
        e1.each do | e2 |

          name             = e2[:name] # <a> <p> <dir>
          textfile         = e2[:href] # 詩のファイル名 TEXT/Sxxx.htm
          comporiginaltext = e2[:text] # タイトルやその他情報

          textfile = textfile.join( '/' ) if textfile.kind_of?( Array )
          textfile = textfile.to_s

          unless comporiginaltext[0] =~ /^\d+\w*$/
            # 先行文字が無い <a> や <p><a> を <dir> と同形式にすることで
            # 処理を単純化するための前処理
            # 先行文字は作曲集の項番を示す数字列と
            # 場合によってそれに続く補助英字で構成される
            # comporiginaltext[0] ..... <a> や <p><a>に先行する文字
            # comporiginaltext[1] ..... タイトル
            # comporiginaltext[2..] ... その他情報
            comporiginaltext.unshift( "" )
          end

          if 1 == 0 # DEBUG
            STDOUT.puts ["#{composer_name}"    ,
                         "#{name}"             ,
                         "#{textfile}"         ,
                         "#{comporiginaltext}" ,
                        ].join( "<>" )
            next
          end # DEBUG

          reference = nil # 整理番号
          lyricinfo = nil # textfile の内容

          unless textfile.nil? # textfile から reference lyricinfo を作成

            if File.exist?( textfile )

              lyricinfo = MyGetLyricInfo.new( textfile )

              if 1 == 0 # DEBUG
                puts ""
                puts [
                  # "#{lyricinfo.lyricinfo[:File]}"                  ,
                  # ":Title=>#{lyricinfo.lyricinfo[:Title]}"         ,
                  ":Reference=>[#{lyricinfo.lyricinfo[:Reference]}]" ,
                  # ":Lyricist=>#{lyricinfo.lyricinfo[:Lyricist]}"   ,
                  # ":Composer=>#{lyricinfo.lyricinfo[:Composer]}"   ,
                ].join( "\n    " )
              end #DEBUG

              unless lyricinfo.lyricinfo[:Reference] == []
                reference = lyricinfo.lyricinfo[:Reference]
              end
            end # if File.exist?( textfile )
          end # unless textfile.nil?

          if comporiginaltext[1].match( # タイトル部分の 原文 と 訳文 に分離
               [ "^■*"                        ,
                 "([^#{$WAJI}]+)"             ,
                 "[[:space:]]+"               ,
                 "([^#{$WAJI}]*[#{$WAJI}].*)" ,
                 "$"
               ].join
             )
            comptitle = [ $1, $2 ]
          else
            comptitle = [ "", "" ]
          end # if comporiginaltext[1].match

          compmiscinfo = [ # その他情報を纏める
            [ comporiginaltext[ 2 .. ] ].join # 原文部分
              .gsub( /[^[:space:]]*[#{$WAJI}].*/  , ''  ) # 和字を含む文字列以降
              .gsub( /[[:space:]]+/               , ' ' )
              .gsub( /^[[:space:]]+/              , ''  )
              .gsub( /[[:space:]]+$/              , ''  ) ,

            [ comporiginaltext[ 2 .. ] ].join # 和訳部分
              .gsub( /[^#{$WAJI}]{2,}[[:space:]]/ , ''  ) # 和字を含まない文字列以降
              .gsub( /[[:space:]]+/               , ' ' )
              .gsub( /^[[:space:]]+/              , ''  )
              .gsub( /[[:space:]]+$/              , ''  ) ,
          ]
          compmiscinfo[1] = # 重複情報削除
            compmiscinfo[1]
              .sub( compmiscinfo[1], "" )

          # 整理番号情報は作品に記載されたもの、そこになければ曲目一覧からを取り出す
          if compmiscinfo[0].match( # 整理番号情報を取り出す
               /(Op[.]|WoO|TrV|D )/ )
            tmp =
              compmiscinfo[0]
                .sub( /[[:space:]]*[(].*/, '')

            compmiscinfo[0] =
              compmiscinfo[0]
                .sub( /#{tmp}[[:space:]]*/, '' )

            reference = tmp if reference.nil?
          end # if compmiscinfo[0].match(
          reference = "" if reference.nil?

          if 1 == 0 # DEBUG
            msg = []
            msg.push(
              [ ''                                         ,
                ":name=>[#{name}]"                         ,
                ":textfile=>[#{textfile}]"                 ,
                ":comporiginaltext=>[#{comporiginaltext}]" ,
                ":comptitle=>[#{comptitle}]"               ,
                ":compmiscinfo=>[#{compmiscinfo}]"         ,
                ":reference=>[#{reference}]"               ,
              ].join( "\n#{File.basename( compfile )}::" )
            )
            unless lyricinfo.nil?
              msg.push(
                [ ''                                                 ,
                  ":Title=>[#{lyricinfo.lyricinfo[:Title]}]"         ,
                  ":Reference=>[#{lyricinfo.lyricinfo[:Reference]}]" ,
                  ":Lyricist=>[#{lyricinfo.lyricinfo[:Lyricist]}]"   ,
                  ":Composer=>[#{lyricinfo.lyricinfo[:Composer]}]"   ,
                ].join ( "\n#{composer}:#{textfile}:" )
              )
            end

            STDOUT.puts msg.join
            next
          end # if 1 == 0 DEBUG

          proc_file_output_section_or_subsection(
            {
              :composer         => composer         ,
              :name             => name             ,
              :compfile         => compfile         ,
              :textfile         => textfile         ,
              :comporiginaltext => comporiginaltext ,
              :comptitle        => comptitle        ,
              :compmiscinfo     => compmiscinfo     ,
              :reference        => reference        ,
              :lyricinfo        => lyricinfo        ,
            }
          )
          # proc_file_output_section( "ファイル名など指定しなくて" )

          tempref = reference.to_s.size > 0 ? "(#{reference})" : ""
          if textfile.to_s.size > 0
            pageref = [ "\\pageref{"                 ,
                        "myindex:subsection:"        ,
                        File.basename( textfile.to_s , ".htm" ),
                        "}"                          ,
                      ].join
          else
            pageref = nil
          end

          case e2[:name]
          when 'a', 'p' then

            unless sectionARRAY.empty?
              output_filename_of_section = # 初回対策
                sprintf( composer_section_filename_format, sectioncount)

              bookARRAY.push(
                proc_file_output_section(
                  sectionARRAY,
                  output_filename_of_section
                )
              )
              sectioncount += 1 # 最終 section 用準備
              output_filename_of_section =
                sprintf( composer_section_filename_format, sectioncount)
            end

            yomi = myYomi( comptitle[1] )
            sectionARRAY = [
              { :section =>
                [ "\\SECTION",
                  "{ #{comptitle[0]} }%書名・詩集名（原）" ,
                  "{ #{comptitle[1]} }%書名・詩集名（訳）" ,
                  "{ #{yomi} }%よみ" ,
                  "{ #{reference} }%整理番号" ,
                  [
                    "{ #{compmiscinfo[0]} }" ,
                    "{ #{compmiscinfo[1]} }",
                    "%監修者等(原・訳)、年情報" ,
                  ].join,
                ].join( "\n" ),
              }
            ]
          end
          tmptoc = [ # 章目次・小目次
            [ "#{comporiginaltext[0]}" , # <a> <p><a> の前の文字列
              "%----%----%----%----%"  ,
            ].join( " " )              ,
            [ "&"                      ,
              "#{comptitle[0]}"        , # タイトル原語
              "#{tempref}"             , # (整理番号)
            ].join( " " )              ,
            [ "&"                      ,
              "#{comptitle[1]}"        , # タイトル和訳
            ].join( " " )              ,
            [ "&"                      ,
              "#{pageref}"             , # 参照ページ情報
              '\\\\%'                  ,
            ].join( " " )              ,
          ]

          case e2[:name]
          when 'a', 'p' then
            tmptoc.push( [ '\cline[2pt]{2-3}' ] )
          else
            tmptoc.push( [ '\cline[dashed]{2-3}'] )
          end

          if textfile.size > 0 # \input ファイル名情報
            tmpinput =
              [ "\\input{",
                "#{composer}",
                "/",
                "#{File.basename(textfile.to_s)}",
                ".tex}",
              ].join
          else
            tmpinput = nil
          end # if textfile.size > 0

          sectionARRAY.push( # 章目次・小目次と \input ファイル名情報
            { :toc => tmptoc, :input => tmpinput }
          )
        end # e1.each do | e2 |
      end # sbi.songbookinfolist.each do | e1 |

      bookARRAY.push(
        proc_file_output_section(
          sectionARRAY,
          output_filename_of_section
        )
      )
      proc_file_output_book(
        {
          :template     => $COMPOSERTEMPLATE2,
          :composer     => composer,
          :composerinfo => [
            sbi.songbookinfocomposerinfo, # [0]COMPOSERINFO
            composer_name[0], # [0]作曲家
            composer_name[1], # [0]COMPOSER
          ],
          :input        => bookARRAY,
        }
      )
    end
  end
end

def proc_file_output_section_or_subsection( ee )

  return nil if ee[:lyricinfo].nil?

  yomi = myYomi( ee[:lyricinfo].lyricinfo[:Title][1] )
  array = []

  array.push( # \SUBSECTION 情報
    [
      [ "\\SUBSECTION" ],
      [ "% 書名・詩名",
        "{ #{ee[:lyricinfo].lyricinfo[:Title][0]} }",
        "{ #{ee[:lyricinfo].lyricinfo[:Title][1]} }",
      ].join( "\n" ),
      [ "{ #{yomi} }",
        "% よみ情報",
      ].join,
      [ "{ #{ee[:lyricinfo].lyricinfo[:Reference]} }",
        "% 整理番号",
      ].join,
      [ "% 作詞情報",
        "{ #{ee[:lyricinfo].lyricinfo[:Lyricist][0]} }",
        "{ #{ee[:lyricinfo].lyricinfo[:Lyricist][1]} }",
      ].join( "\n" ),
      [ "% 作曲情報",
        "{ #{ee[:lyricinfo].lyricinfo[:Composer][0]} }",
        "{ #{ee[:lyricinfo].lyricinfo[:Composer][1]} }",
      ].join( "\n" ),
    ].join( "\n" )
  )

  tmp = File.basename(ee[:textfile], ".htm" )
  array.push( "", "\\label{myindex:subsection:#{tmp}}", )

  array.push( "", "\\begin{myTBLR}[]" )

  ( 0 .. ee[:lyricinfo].lyricinfo[:Lyric].size - 1 )
    .select( &:even? ).each do | i |

    array.push( "\\\\" ) if i > 0

    tmpi = ee[:lyricinfo].lyricinfo[:Lyric][i+0].size
    tmpj = ee[:lyricinfo].lyricinfo[:Lyric][i+1].size
    if tmpi < tmpj
      ( tmpi .. tmpj - 1 )
        .each do | j |
        ee[:lyricinfo].lyricinfo[:Lyric][i+0][j] = ""
      end
    end

    ee[:lyricinfo].lyricinfo[:Lyric][i+0]
      .zip( ee[:lyricinfo].lyricinfo[:Lyric][i+1] )
      .each do | jj |

      if jj.join.size > 0
        array.push(
          [ "{ #{jj[0]} } &",
            "{ #{jj[1]} }",
            "\\\\",
          ].join( "\n" )
        )
      else
        array.push( "\\\\% 連間空行" )
      end
    end
  end

  array.push( "\\end{myTBLR}" )

  ff =
    [ "#{ee[:composer]}"                  ,
      "/"                                 ,
      "#{File.basename( ee[:textfile] )}" ,
      ".tex"                              ,
    ].join

  File.open( ff, "w" ) do | f |
    f.puts myConvertHtml2tex( array.join( "\n" ) )
  end
end

def proc_file_output_section( aSECTION, outfile )

  return outfile  if aSECTION.empty?

  # :section [ "\SECTION{..}", .....] この時は :toc :input は無い
  # :toc
  # :input

  cnttoc   = 0
  cntinput = 0
  aOUTPUT = []

  aSECTION.each do | hash |
    # :toc と :input はそれぞれ先に有効件数を調べておく
    hash.each do | key, val |
      case key
      when :section then
        aOUTPUT.push( val )
      when :toc     then
        cnttoc   += 1 if val.to_s.size > 0
      when :input   then
        cntinput += 1 if val.to_s.size > 0
      end
    end
  end

  if cnttoc > 0
    aOUTPUT.push(
      [ '\begin{longtblr}[]{'                  ,
        '  colspec = { r X X r },'             ,
        '  rowhead = 1,'                       ,
        '}'                                    ,
        [ ' & \textbf{\large Liste der Lieder}',
          ' & \textbf{\large 曲目一覧}'         ,
          ' & \\\\'                            ,
        ].join,
        '\cline[2pt]{2-3}',
      ].join( "\n" )
    )

    aSECTION.each do | e |
      aOUTPUT.push( e[:toc] ) if e[:toc].to_s.size > 0
    end

    aOUTPUT.push( '\end{longtblr}' )
    aOUTPUT.push( '' ) if cntinput > 0
  end

  if cntinput > 0
    aSECTION.each do | e |
      aOUTPUT.push( e[:input] ) if e[:input].to_s.size > 0
    end
  end

  File.open( outfile, "w" ) do | f |
    f.puts myConvertHtml2tex( aOUTPUT.join( "\n" ) )
  end

  "\\input{#{outfile}}" # XXX/XXX.tex に書きこむイメージ
end

def proc_file_output_book( hash )
  # :template
  # :composer
  # :composerinfo
  # :input

  composerTEXFILE  =
    [ "#{hash[:composer]}", "/",
      "#{hash[:composer]}", ".tex",
    ].join

  composerTEXFILEhyperlink =
    [ "#{hash[:composer]}", "/",
      "#{hash[:composer]}", "-hyper-link", ".tex",
    ].join

  File.open( composerTEXFILE, "w" ) do | f |
    f.puts File
             .read( hash[:template] )
             .gsub( /%%--COMPOSERINFO--%%/ , hash[:composerinfo][0] )
             .gsub( /%%--作曲家--%%/        , hash[:composerinfo][1] )
             .gsub( /%%--COMPOSER--%%/     , hash[:composerinfo][2] )
             .gsub( /%%--INPUT--%%/ , "#{hash[:input].join("\n")}"  )
  end

  File.open( composerTEXFILEhyperlink, "w" ) do | f |
    f.puts File
             .read( composerTEXFILE )
             .sub( /^%%(\\usepackage)/, '')
  end
end

if __FILE__ == $0 then main end
