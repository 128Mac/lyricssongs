#!/usr/bin/env ruby

require 'juman'

def myYomiJumanDeprecated( text )
   yomi = []
   juman = Juman.new
   pp juman.analyze( text )
   juman.analyze( text ).each do | ee |
      pp ee
      #yomi.push( ee.pronunciation )
   end
   yomi.join
end

if __FILE__ == $0 then 
  ARGV.each do | argv | puts myYomiJuman( argv ) end
end

#  myYomiJumanDeprecated( '歌' ) でエラーになってしまうので利用中止
#利用中止
# rbenv/versions/3.2.1/lib/ruby/gems/3.2.0/gems/juman-0.0.2/lib/juman/morpheme.rb:28:
#  in `eval': (eval):1: syntax error, unexpected string literal, expecting end-of-input (SyntaxError)
#  原因は「歌」や「春」のように複数の読み候補がある場合の配慮が足りないあるいは設定不足だろう
#  echo 歌 | juman
#  歌 うた 歌 名詞 6 普通名詞 1 * 0 * 0 "代表表記:歌/うた 漢字読み:訓 カテゴリ:抽象物 ドメイン:文化・芸術;レクリエーション"
#  @ 歌 か 歌 名詞 6 普通名詞 1 * 0 * 0 "代表表記:歌/か 漢字読み:音 カテゴリ:抽象物 ドメイン:文化・芸術"
#  EOS
#  echo 春 | juman
#  春 しゅん 春 名詞 6 時相名詞 10 * 0 * 0 "代表表記:春/しゅん 漢字読み:音 カテゴリ:時間"
#  @ 春 はる 春 名詞 6 時相名詞 10 * 0 * 0 "代表表記:春/はる 漢字読み:訓 カテゴリ:時間"
#  EOS
