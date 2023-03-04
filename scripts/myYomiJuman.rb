#!/usr/bin/env ruby

require 'systemu'
require 'nkf'

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGlobalValue'
require_relative 'myYomiJuman'

#     require 'systemu'
#     date = %q( ruby -e"  t = Time.now; STDOUT.puts t; STDERR.puts t  " )
#     status, stdout, stderr = systemu date
#     p [ status, stdout, stderr ]
#     # => [#<Process::Status: pid 50931 exit 0>, "2011-12-11 22:07:30 -0700\n", "2011-12-11 22:07:30 -0700\n"]

def myYomiJuman( text )
  ss = NKF
         .nkf( "-w ", text)
         .gsub( /[(]/ , "（" )
         .gsub( /[)]/ , "）" )

  array= []
  if ss =~ /[\p{hani}]/
    status, stdout, stderr = systemu [
                      "echo #{ss}" ,
                      "juman -b"   , # -b 複数読みがあった場合の処置
                    ].join( ' | ')

    if status == 0
      stdout
        .force_encoding( 'UTF-8' )
        .sub(   /EOS$/, '' )
        .gsub(  /\\/  , '' )
        .split( "\n" )
        .each do | e |
        array.push( e.split( " " )[1] )  # 各行の2番目を取り出す
      end
    else
      array.push( "juman error", text )
    end
  else
    array.push( ss )
  end

  yomi = array.join

  if yomi =~ /[\p{hani}]/
    yomi =
      NKF.nkf( "-w --hiragana", yomi )
        .gsub( /[\p{hani}]/, "◆" )
        .sub(  /^/         , 'んんん' )
    STDERR.puts [ "",
                  "JUMAN （一部）よみ変換できず、要手動編集",
                  "JUMAN よみ 変　換　前 #{text}",
                  "JUMAN よみ 暫定変換後 #{yomi}",
                ].join( "\n" )
  end

  yomi
end

if __FILE__ == $0 then
  ARGV.each do | argv | puts myYomiJuman( argv ) end
end

######################################################
# 'https://qiita.com/tyabe/items/56c9fa81ca89088c5627'

# posted at 2012-09-04
# updated at 2015-12-27

#                | stdin | stdout | stderr | status
# Kernel.#system | NG    | NG     | NG     | OK(*1)
# backquate      | NG    | OK     | NG     | OK(*1)
# IO.popen       | OK    | OK     | OK(*2) | OK(*1)
# Open3.capture3 | OK    | OK     | OK     | OK
# Open3.popen3   | OK    | OK     | OK     | OK
# systemu        | OK    | OK     | OK     | OK
# (*1) $? で参照
# (*2) 実行できなかった場合は Errno::EXXX が発生する

################
# Kernel.#system
################
# サクッと実行したい場合に便利
# 実行結果(true, false, nil)が返却される

#     system('mkdir hoge') # => true

################
# バッククォート
################
# サクッと実行して、標準出力の内容だけ取れればOKな場合に便利
# 標準出力が返却される

#     `date` # => "2012年 9月 3日 月曜日 23時59分17秒 JST\n"
#     # %x[ date ] でも同じ

##########
# IO.popen
##########
# 標準入力にデータを渡して標準出力から受け取りたい場合に使う
# IOオブジェクトが返却される
# 実行できなかった場合は Errno::EXXX が発生する

#     p IO.popen("cat", "r+") {|io|
#       io.puts "foo"
#       io.close_write
#       io.gets
#     }
#     # => "foo\n"

################
# Open3.capture3
################
# 標準入出力を使ったデータのやりとりを簡単に使いたい場合に便利
# 標準出力, 標準エラー, 終了ステータスが返却される
# 実行できなかった場合は Errno::EXXX が発生する

#     require "open3"

#     o, e, s = Open3.capture3("echo a; sort >&2", :stdin_data=>"foo\nbar\nbaz\n")
#     p o #=> "a\n"
#     p e #=> "bar\nbaz\nfoo\n"
#     p s #=> #<Process::Status: pid 32682 exit 0>

##############
# Open3.popen3
##############
# 実行中プロセスの標準出力、標準エラー出力をリアルタイムに扱いたい場合に便利
# ブロックを渡すことで、実行中プロセスの標準出力、標準エラー出力を扱える

#     require "open3"

#     Open3.popen3("echo a; sleep 1; echo b; sort >&2; sleep 3") do |i, o, e, w|
#       i.write "foo\nbar\nbaz\n"
#       i.close
#       o.each do |line| p line end #=> "a\n",  "b\n"
#       e.each do |line| p line end #=> "bar\n", "baz\n", "foo\n"
#       p w.value #=> #<Process::Status: pid 32682 exit 0>
#     end

#########
# systemu
#########
# ブロック渡すとバックグラウンド実行してくれたりして色々便利
# 終了ステータス, 標準出力, 標準エラーが返却される

#     require 'systemu'
#     date = %q( ruby -e"  t = Time.now; STDOUT.puts t; STDERR.puts t  " )
#     status, stdout, stderr = systemu date
#     p [ status, stdout, stderr ]
#     # => [#<Process::Status: pid 50931 exit 0>, "2011-12-11 22:07:30 -0700\n", "2011-12-11 22:07:30 -0700\n"]

######
# 参考
######
# http://doc.ruby-lang.org/ja/1.9.3/doc/method/Kernel/m/system
# http://doc.ruby-lang.org/ja/1.9.3/doc/spec=2fliteral.html#command
# http://doc.ruby-lang.org/ja/1.9.3/method/IO/s/popen.html
# http://doc.ruby-lang.org/ja/1.9.3/method/Open3/m/capture3.html
# http://doc.ruby-lang.org/ja/1.9.3/method/Open3/m/popen3.html
# https://github.com/ahoward/systemu
# http://d.hatena.ne.jp/ursm/20090625/1245947107
