#!/usr/bin/env ruby -

require "date"
require 'fileutils'
require 'nkf'
require 'nokogiri'
require 'open-uri'
require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGit'
require_relative 'myCorrection'

def main

  tomlfile = []
  ARGV.each do | av |
    next unless File.exist?( av )
    next unless av.match( /.toml$/i )
    tomlfile.push( av )
  end

  return if tomlfile.flatten.uniq.size < 1

  myGit( "COMP", "!*.htm", "!*.htm.orig") # TODO

  urllist = []
  tomlfile
    .flatten
    .uniq.sort.each do | url |
    urllist.push( read_toml_file( url ) )
  end

  return if urllist.flatten.uniq.size < 1

  myGit( "TEXT", "!*.htm", "!*.htm.orig") # TODO
  urlhtmhash = {}
  estimatedSEC = 0
  urllist.flatten.uniq.sort.each do | url |

    m1 = url.split( "/" )

    htm = [ m1[-2], m1[-1] ].join( '/' )
    htmorig = "#{htm}.orig"

    if File.exist?( htmorig )
      urlhtmhash[ htm ] = 0.1
      estimatedSEC += 0.1
    else
      urlhtmhash[ url ] = 5
      estimatedSEC += 5
    end
  end

  ttl = urlhtmhash.size
  urlhtmhash.sort.each_with_index  do | ( urlhtm, sec ), cnt |

    remain = []
    remain.push( sprintf( "%02d:", ( estimatedSEC / 3600      ).to_i ) ) if estimatedSEC >= 3600
    remain.push( sprintf( "%02d:", ( estimatedSEC % 3600 / 60 ).to_i ) ) if estimatedSEC >=   60
    remain.push( sprintf( "%02d" , ( estimatedSEC        % 60 ).to_i ) )
    estimatedSEC -= sec

    msg = sprintf( "%*d / %*d ( %s ) %s %s",
                   ttl.to_s.size,       ( cnt + 1 ),
                   ttl.to_s.size, ttl - ( cnt + 1 ),
                   remain.join.sub( /^0(\d:\d)/, '\1' ),
                   DateTime.now.strftime( "%F %T" ),
                   urlhtm )
    puts "#{msg}"
    read_html_image_url_or_html_file( urlhtm )
    sleep ( rand( 10 ) ) if ( urlhtm.match( /^http:/ ) )

  end
  return
end

def read_html_image_url_or_html_file(url)

  m = url.split( "/" )
  iofile = m[-2] + "/" + m[-1]
  directoty = m[-2]
  orig = "#{iofile}.orig"

  unless File.file?( orig )
    unless File.directory?( directoty )
      FileUtils.mkdir_p directoty
    end

    inhtml = URI.open( url )
    othtml = NKF
               .nkf( '-w', inhtml.read )
               .sub( /(charset)=shift_jis/, "" )

    charset = nil
    File.open( orig, "w" ) do | f |
      f.puts Nokogiri::HTML.parse( othtml, nil, charset )
    end
  end

  outhtml = myCorrection( File.read( orig ) )

  charset = nil
  File.open( iofile, "w" ) do | f |
    f.puts Nokogiri::HTML.parse( outhtml, nil, charset )
  end

  charset = nil
  Nokogiri::HTML.parse( File.read(iofile), nil, charset )
end

def read_toml_file( tomlfile )

  urllist = []
  if File.file?( tomlfile )

    Tomlrb.load_file( tomlfile )['COMPOSER'].each do | composer |

      read_html_image_url_or_html_file( composer['url'] ).xpath( '//a' ).each do | node |

        next unless node.first[1] =~ /htm$/

        m1     = composer['url'].split( "/" )
        m2     =   node.first[1].split( "/" )
        m1[-2] = m2[-2]
        m1[-1] = m2[-1]

        urllist.push( m1.join( '/' ) )
      end
    end
  end
  urllist
end


if __FILE__ == $0 then main end
