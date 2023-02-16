#!/usr/bin/env ruby

require 'fileutils'
require 'tomlrb'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
$TOML_DIRECTORY = "TOML"
$TOML_SUFFIX    = "toml"

def main_myGetTomlHash
  tomlHash = myGetTomlHash( ARGV )
  tomlHash.each_with_index do | (key, val), idx |
    puts "<#{idx}><#{key}>\n   <#{val}>"
  end
end

def myGetTomlHash( array )

  # コマンド引数から
  files = []
  array.grep(/.#{$TOML_SUFFIX}$/).uniq.sort.each do | ee |
    files.push( ee ) if File.file?( ee )
  end
  # コマンド引数に有効な .toml ファイル指定無しの場合
  if files.empty?
    if File.directory?( $TOML_DIRECTORY )
      files.push( Dir.glob( "#{$TOML_DIRECTORY}/*.#{$TOML_SUFFIX}" ) )
    end
  end

  return nil if files.empty?

  hash = {}
  files.flatten.each do | tomlfile |
    next unless File.file?( tomlfile )
    Tomlrb.load_file( tomlfile ).each do | ee |
      next unless ee[0] == 'COMPOSER'
      ee[1].each do | eee |
        hash[eee["url"]] = eee
      end
    end
  end
  hash
end

if __FILE__ == $0 then main_myGetTomlHash end
