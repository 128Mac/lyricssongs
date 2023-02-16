#!/usr/bin/env ruby

require 'fileutils'
require 'nokogiri'
require 'open-uri'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGetTomlHash'

def main_myGetHtmlHash
  myGetHtmlHash( myGetTomlHash( ARGV ) ).each_with_index do | ( k, v ), i |
    puts "<#{i}><#{k}><#{v.class}>"
    puts v[0..5].join( ' ' ), [ "...", v[-3..-1]].join( ' ' )
  end
end

def myGetHtmlHash( hash )

  newhash = {}

  hash.each do | url, etc |

    m = url.split( "/" )
    htmlfile = m[-2] + "/" + m[-1]

    next unless File.file?( htmlfile )

    hashkey = File.basename( m[-1], ".htm" )

    array = []
    array.push( htmlfile )

    Nokogiri::HTML.parse(
      File.read( htmlfile ), nil, nil
    ).xpath( '//a' ).each do | node |

      next unless node.first[1] =~ /htm$/

      m = node.first[1].split( "/" )
      array.push( "#{m[-2]}/#{m[-1]}" )
    end

    newhash[hashkey] = array
  end
  newhash
  # "作曲者1" => [ "A.htm", "B.htm", ]
  # "作曲者2" => [ "a.htm", "b.htm", ]
end

if __FILE__ == $0 then main_myGetHtmlHash end
