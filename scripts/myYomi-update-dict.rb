#!/usr/bin/env ruby

$LOAD_PATH.push( File.expand_path( __FILE__ ) )

require_relative 'myGlobalValue'
require_relative 'myYomi'

if __FILE__ == $0 then
  File.open( $YOMI_DB_CACHE_FILE, "w")  do | f |
    $YOMI_DB_CACHE.sort.each do | k, v |
      f.puts "#{k} => #{v}" unless k =~ /textrm|んんん/
    end
  end
end
