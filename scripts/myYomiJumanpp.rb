#!/usr/bin/env ruby

require 'jumanpp_ruby'

def myYomiJumanpp( text )
     yomi = []
     jumanpp = JumanppRuby::Juman.new( force_single_path: :true )
     jumanpp.parse( text ) do | part |
        yomi.push( part[1] )
     end
     yomi.join
end

if __FILE__ == $0 then
  ARGV.each do | argv | puts myYomiJumanpp( argv ) end
end

# Windows 版で jumanpp のプリコンパイルなものが入手可能になったら利用を考えるため残しておく
