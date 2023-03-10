#!/usr/bin/env ruby

$LOAD_PATH.push( File.expand_path( __FILE__ ) )

require_relative 'myGlobalValue'
require_relative 'myYomi'

if __FILE__ == $0 then
  $YOMI_DB_CACHE.sort.each do | k, v |
    puts "#{k} => #{v}" unless k =~ /textrm|んんん/
  end
end
