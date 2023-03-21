#!/usr/bin/env ruby -

$LOAD_PATH.push( File.expand_path( __FILE__ ) )

$WAJI = [
  '\p{hani}\p{hira}\p{kana}ー' , # 所謂日本語漢字、ひらがな、カタカナ
  '「」『』（）' , # 括弧類
  '．，。、' , # 句読点
  '：・' , # 記号類
  '０-９' ,
].join

$COMPOSERTEMPLATE2 = "sty/lieder-template2.tex"

$YOMI_DB_CACHE_FILE= "yomi.dict"
