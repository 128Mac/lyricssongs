#!/usr/bin/env ruby -

require 'nokogiri'
require 'open-uri'
require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGlobalValue'

class MyGetSongbookInfo

  def initialize( html )

    return nil unless File.exist?( html )

    @songbookinfolist = []

    @songbookinfotitle =
      Nokogiri::HTML( File.read( html ) )
        .xpath( '/html/head/title'   )
        .to_html
        .gsub( /<[^<>]+>/      , ''  )
        .gsub( /[[:space:]]+/  , ' ' )
        .sub(  /^[[:space:]]+/ , ''  )
        .sub(  /[[:space:]]+$/ , ''  )

    @songbookinfocomposerinfo =
      Nokogiri::HTML( File.read( html ) )
        .xpath( '/html/body/p/font')
        .to_html
        .gsub( /<[^<>]+>/      , ''  )
        .gsub( /[[:space:]]+/  , ' ' )
        .sub(  /^[[:space:]]+/ , ''  )
        .sub(  /[[:space:]]+$/ , ''  )

    Nokogiri::HTML( File.read( html ) )
      .xpath( '/html/body/dir' )
      .each_with_index do | ee, ii |
      blocks = []
      block = []

      ee.children.each_with_index do | ee1, ii1 |

        STDERR.puts "DEBUG #{ii} #{ee.name} #{ii1} #{ee1.name}" if 1 == 0

        case ee1.name
        when 'a', 'p', 'dir' then
          blocks.push( block ) if block.size > 0
          block = []
        end
        block.push( ee1 )
      end

      blocks.push( block ) if block.size > 1 # 最後のデータを取り込む

      hash = [ # {
        # 'name' => '',
        # 'text' => [], # [ "path1", "path2", "htm" ]
        # 'href' => [], # [ "<a> の前の文字列", "<a>...</a>の ...", "<a> の後の文字列", .,, ]
        # }
      ]

      # 参考 URL https://kic-yuuki.hatenablog.com/entry/2019/06/18/091451

      blocks.each_with_index do | e1, i1 |    # 一旦ブロック化しておく

        STDERR.puts "DEBUG #{i1} [#{e1}] / #{blocks.size}" if 0 == 1

        name = nil
        href = []
        text = []

        e1.each_with_index do | e2, i2 |

          case e2.name
          when 'a', 'p', 'dir' then name = e2.name
          end

          tmpH = nil
          tmpT = nil

          case e2.name
          when 'a'    then tmpH, tmpT = myGetHtml_A    ( e2 )
          when 'br'   then tmpH, tmpT = myGetHtml_BR   ( e2 )
          when 'p'    then tmpH, tmpT = myGetHtml_P    ( e2 )
          when 'dir'  then tmpH, tmpT = myGetHtml_DIR  ( e2 )
          when 'text' then tmpH, tmpT = myGetHtml_text ( e2 )
          else
            raise "ERROR unknown name -- #{i1} -- #{i2} -- #{e2.name} -- #{e2} --"
          end

          tmpT = myStripSpaces( tmpT )

          href.push( tmpH ) unless tmpH.nil?
          text.push( tmpT ) unless tmpT.nil?
        end # e1.each_with_index  | e2, i2 |

        unless name.nil? && href == [] && text == []
          hash.push( { :name => name, :href => href, :text => text, } )
        end
      end # blocks.each_with_index | e1, i1 |

      (   0 .. hash.size            - 1 ).each do | i1 |    # ブロック毎に
        list = []
        ( 0 .. hash[i1][:href].size - 1 ).each do | i2 |

          name = hash[i1][:name]
          href = hash[i1][:href][i2]
          text = hash[i1][:text][i2]

          href2 = href.kind_of?( String ) ? [ href            ] : href
          text2 = text.kind_of?( String ) ? [ hash[i1][:text] ] : text
          text2 =                           [ hash[i1][:text] ] if name == 'p'

          looptime = href2.size - 1
          looptime = 0 if looptime < 0
          ( 0 .. looptime ).each do | i3 |
            href3 = href2[i3]
            text3 = text2[i3].flatten
            list.push( { :name => name, :href => href3, :text => text3 } )
          end # i3
        end # i2
        @songbookinfolist.push( list )
      end # i1
    end # Nokogiri::HTML( File.read( html )
  end # initializ

  def myGetHtml_A( ee )

    href = ee.attributes['href'] ? ee.attributes['href'].value : nil
    text = ee.children           ? ee.children.to_s            : nil

    href = href.sub( /^[.\/]+\//, '' ) unless href.nil? # <../TEXT/S2093.htm>
    text = myStripSpaces( text )

    [ href, text ]
  end # myGetHtml_A( ee )

  def myGetHtml_B( ee )

    href = []
    text = []

    tmpH = nil
    tmpT = nil
    if ee.children.size > 0
      ee.children.each do | eee |

        case eee.name
        when 'text' then tmpH, tmpT = myGetHtml_text( eee )
        when 'a'    then tmpH, tmpT = myGetHtml_A(    eee )
        else
          raise "ERROR unknown name myGetHtml_B #{ee.name} #{eee.name}"
        end
      end
    else
      tmpH, tmpT = myGetHtml_A( ee )
    end

    tmpH = myStripSpaces( tmpH )
    tmpT = myStripSpaces( tmpT )

    href.push( tmpH ) unless tmpH.nil?
    text.push( tmpT ) unless tmpT.nil?

    [ href, text ]
  end # myGetHtml_B( ee )

  def myGetHtml_BR( ee )

    text = ee.to_s
             .gsub( /<[^<>]+>/, '' )
             .sub(  /^[[:space:]]+/, '' )
             .sub(  /[[:space:]]+$/, '' )
    text = nil if text == ''

    [ nil, text ]
  end # myGetHtml_BR( ee )

  def myGetHtml_P( ee )

    href = []
    text = []

    ee.children.each do | eee |

      tmpH = nil
      tmpT = nil

      case eee.name
      when 'a'    then tmpH, tmpT = myGetHtml_A(    eee )
      when 'b'    then tmpH, tmpT = myGetHtml_B(    eee )
      when 'br'   then tmpH, tmpT = myGetHtml_BR(   eee )
      when 'text' then tmpH, tmpT = myGetHtml_text( eee )
      else
        raise "ERROR unknown name myGetHtml_P #{eee.name}"
      end

      tmpH = myStripSpaces( tmpH )
      tmpT = myStripSpaces( tmpT )

      href.push( tmpH ) unless tmpH.nil?
      text.push( tmpT ) unless tmpT.nil?
    end

    [ href, text ]
  end # myGetHtml_P( ee )

  def myGetHtml_DIR( ee )

    href = []
    text = []
    text2= []
    ee.children.each_with_index do | eee, iii |

      STDERR.puts "DEBUG myGetHtml_DIR #{iii} #{eee.name} #{eee}" if 1 == 0

      tmpH = nil
      tmpT = nil

      case eee.name
      when 'a'    then tmpH, tmpT = myGetHtml_A(    eee )
      when 'br'   then tmpH, tmpT = myGetHtml_BR(   eee )
      when 'text' then tmpH, tmpT = myGetHtml_text( eee )
      when 'p'    then

        tmpH = nil
        tmpT = eee.to_s
                 .gsub( /<[^<>]+>/      , '' )
                 .sub(  /^[[:space:]]+/ , '' )
                 .sub(  /[[:space:]]+$/ , '' )
        tmpT = nil if tmpT == ''
      else
        raise "ERROR unknown name myGetHtml_DIR #{eee.name}"
      end

      tmpH = myStripSpaces( tmpH )
      tmpT = myStripSpaces( tmpT )

      href.push( tmpH ) unless tmpH.nil?
      text.push( tmpT ) unless tmpT.nil?

      case eee.name
      when 'br'    then

        text2.push( text )
        text = []
      end
    end

    text2.push( text ) unless text == []

    [ href, text2 ]
  end # myGetHtml_DIR( ee )

  def myGetHtml_text( ee )

    text = "#{ee.to_s}"
             .gsub( /\n/, "" )
             .sub(  /^[[:space:]]+/, '' )
             .sub(  /[[:space:]]+$/, '' )

    text = nil if text == ""
    [ nil, text ]
  end # myGetHtml_text( ee )

  def myStripSpaces( ee )

    return nil if ee.nil? || ee.empty?

    if ee.kind_of?( String )
      ee = ee.sub( /^[[:space:]]+/, '' )
             .sub( /[[:space:]]+$/, '' )
    end

    if ee.kind_of?( Array )

      ( 0 .. ee.size - 1 ).each do | i |
        if ee[i].kind_of?( String )
          ee[i] = ee[i]
                    .sub( /^[[:space:]]+/, '' )
                    .sub( /[[:space:]]+$/, '' )
        end
      end
    end

    ee
  end # myStripSpaces( ee )

  def songbookinfolist
    @songbookinfolist
  end

  def songbookinfotitle
    @songbookinfotitle
  end

  def songbookinfocomposerinfo
    @songbookinfocomposerinfo
  end
end

if __FILE__ == $0 then
  ARGV.grep( /.htm$/ ).each do | html |
    next nil unless File.exist?( html )

    sbi = MyGetSongbookInfo.new( html )

    puts "\ntitle=>#{sbi.songbookinfotitle}"
    puts "\ncomposerinfo=>#{sbi.songbookinfocomposerinfo}"
    sbi.songbookinfolist.each do | ee |
      ee.each do | eee |

        case eee[:name]
        when 'a', 'p' then puts ""
        end
        puts [
          "name=>#{eee[:name]}",
          "href=>#{eee[:href]}",
          "text=>#{eee[:text]}",
        ].join ( " | " )
      end
    end

  end
end
