
# Table of Contents

1.  [lyricssongs](#org2ac988b)
    1.  [概要](#org8f2e41f)
    2.  [必要なもの](#orga604d8b)
        1.  [git 環境](#orgc569a4c)
        2.  [ruby 環境](#org25b95fd)
        3.  [JUMAN](#org6e4b527)
    3.  [利用方法](#orgccf1afb)
    4.  [TODO](#org9212ff5)


<a id="org2ac988b"></a>

# lyricssongs


<a id="org8f2e41f"></a>

## 概要

[　梅丘歌曲会館 　詩と音楽　](http://www7b.biglobe.ne.jp/~lyricssongs/index.htm)の作曲家別の作品集を latex 化するための　ruby スクリプト


<a id="orga604d8b"></a>

## 必要なもの

-   git 環境
-   ruby 環境
-   JUMAN


<a id="orgc569a4c"></a>

### git 環境

-   これを読めるので基本的な git 環境は OK です

-   スクリプト内部よりローカルな git リポジトリを作成するため、 git
    config で以下の二つを登録
    
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"


<a id="org25b95fd"></a>

### ruby 環境

-   html 情報から各種情報を取り出すため ruby nokogiri を利用します
    -   scoop install ruby / brew install ruby / 他
    -   gem install tomlrb nokogiri git
        -   利用する gem パッケージは scripts/Gemfile 参照


<a id="org6e4b527"></a>

### JUMAN

-   邦訳された作品タイトル名の索引情報作成に、その「ひらがな化」が必要
-   和文の形態要素解析プログラムは、漢字の「よみ」も生成するのでこれを利用
-   mecab juman jumanpp などがあるが windows macOS ともにプリコンパイル
    されたものが存在する juman を使うことにした
    -   ただし開発当初は jumanpp を利用していたが、リリースに間に合わないので
        「よみ」情報を手動でキャッシュとして蓄えて利用する

-   URL [ 日本語形態素解析システム JUMAN ](https://nlp.ist.i.kyoto-u.ac.jp/?JUMAN)

-   インストール
    -   [ ] [JUMAN 開発版](https://github.com/ku-nlp/juman) (at GitHub)
    -   [ ] [JUMAN  Ver.7.01](https://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=https://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.01.tar.bz2&name=juman-7.01.tar.bz2) (bzip2圧縮; 4,286,891 bytes)
    -   [ ] [JUMAN  Ver.7.0 (Windows 32bit版)](https://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=https://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.0-x86-installer.exe&name=juman-7.0-x86-installer.exe) (インストーラ付; 8,276,060 bytes)
    -   [X] [JUMAN  Ver.7.0 (Windows 64bit版)](https://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=https://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.0-x64-installer.exe&name=juman-7.0-x64-installer.exe) (インストーラ付; 8,330,604 bytes)
    -   [ ] [JUMAN/KNPのチュートリアルのスライド](https://nlp.ist.i.kyoto-u.ac.jp/DLcounter/lime.cgi?down=https://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/20090930-juman-knp.ppt&name=20090930-juman-knp.ppt)
        (京都大学学術情報メディアセンター, メディア情報処理専修コース「自然言語処理技術」, 2009/09/30)
-   PATH に「 C:\Program Files (x86)\juman 」を追記しリブート
    
        C:\Program Files (x86)\juman\COPYING
        C:\Program Files (x86)\juman\dic
        C:\Program Files (x86)\juman\juman.exe
        C:\Program Files (x86)\juman\manual.pdf
        C:\Program Files (x86)\juman\unins000.dat
        C:\Program Files (x86)\juman\unins000.exe


<a id="orgccf1afb"></a>

## 利用方法

-   TOML ファイルの用意
    
    TOML ディレクトリのサンプル TOML ファイルを参考に [作曲家リスト（国・
    地域別）](http://www7b.biglobe.ne.jp/~lyricssongs/COMP/CIDX_DE.htm) などから作家情報を作成

-   TOML ファイルを利用して htm ファイルをダウンロード
    
        ruby scripts/00-lyricssongs-tex-gen.rb TOML/Brahms.toml ...
    
    -   初回ダウンロード時は一件あたり 5 秒間隔でダウンロード
    
    -   作曲家情報は COMP / 作品情報は TEXT ディレクトリに格納

-   htm ファイルの tex 化と latex によるテスト＆対策
    -   ダウンロードした htm ファイルを tex 化
        
            ruby scripts/10-lyricssongs-tex-gen.rb COMP/*.htm TEXT/*.htm
        
        -   上記の処理で、各作品は op に、それらを tex で纏めるためのるもの
            が Brahms dディレクトリに格納される
        -   同時に Brahms.tex や Brahms-hyper-link.tex も作成される
    
    -   latex などでビルドしデバッグ
        
            llmk Brahms
    
    -   対策


<a id="org9212ff5"></a>

## TODO

-   [ ] juman 対応
-   [ ] style macro の見直し
    -   Op 番号なしなどがたくさんあるので
-   [ ] 予想外のデータ対策（これは当分は終結はしないだろう）

