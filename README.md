
# Table of Contents

1.  [lyricssongs](#orgc4285bf)
    1.  [概要](#org81da841)
    2.  [必要なもの](#orgfe96458)
        1.  [git 環境](#org1c34dd0)
        2.  [ruby 環境](#org9ef51b3)
        3.  [JUMAN](#org6bcd654)
    3.  [利用方法](#orga5591ab)
    4.  [TODO](#orgda39717)


<a id="orgc4285bf"></a>

# lyricssongs


<a id="org81da841"></a>

## 概要

[　梅丘歌曲会館 　詩と音楽　](http://www7b.biglobe.ne.jp/~lyricssongs/index.htm)の作曲家別の作品集を latex 化するための　ruby スクリプト


<a id="orgfe96458"></a>

## 必要なもの

-   git 環境
-   ruby 環境
-   JUMAN


<a id="org1c34dd0"></a>

### git 環境

-   これを読めるので基本的な git 環境は OK です

-   スクリプト内部よりローカルな git リポジトリを作成するため、 git
    config で以下の二つを登録
    
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"


<a id="org9ef51b3"></a>

### ruby 環境

-   html 情報から各種情報を取り出すため ruby nokogiri を利用します
    -   scoop install ruby / brew install ruby / 他
    -   gem install tomlrb nokogiri git
        -   利用する gem パッケージは scripts/Gemfile 参照


<a id="org6bcd654"></a>

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
    
        C:\Program Files\juman\COPYING
        C:\Program Files\juman\dic
        C:\Program Files\juman\juman.exe
        C:\Program Files\juman\manual.pdf
        C:\Program Files\juman\unins000.dat
        C:\Program Files\juman\unins000.exe


<a id="orga5591ab"></a>

## 利用方法

-   TOML ファイルの用意
    
    TOML ディレクトリのサンプル TOML ファイルを参考に [作曲家リスト（国・
    地域別）](http://www7b.biglobe.ne.jp/~lyricssongs/COMP/CIDX_DE.htm) などから作家情報を作成

-   TOML ファイルを利用して htm ファイルをダウンロード
    
        ruby scripts/00-lyricssongs-download.rb TOML/Brahms.toml ...
    
    -   初回ダウンロード時は一件あたり 5 秒間隔でダウンロード
    
    -   作曲家情報は COMP / 作品情報は TEXT ディレクトリに格納

-   htm ファイルの tex 化と latex によるテスト＆対策
    -   ダウンロードした htm ファイルを tex 化
        
            ruby scripts/20-lyricssongs-tex-gen.rb  TOML/Brahms.toml ...
        
        -   scripts/10-lyricssongs-tex-gen.rb は廃止の予定です
        
        -   上記の処理で、 作曲家毎に各ディレクトリに LaTeX に必要なものが書き込まれます。
        -   Brams を例にとれば以下のようなものが作成されます。
            -   Brahms.tex
            -   Brahms-hyper-link.tex
            -   Bramas-V-001.tex &#x2026;.
            -   Sxxxx.tex &#x2026;  ( 今まで op に置いていたもの )

-   latex などでビルド
    
        mkdir out
        llmk Brahms/Brahms

-   現在判明していること


<a id="orgda39717"></a>

## TODO

-   [X] juman 対応
-   [ ] style macro の見直し
    -   Op 番号なしなどがたくさんあるので
    -   他の作者では Op 番号や WoO 番号が無い、あるいはそのほかの記号があるので、対応検討中（アイデア募集）
-   [ ] 予想外のデータ対策（これは当分は終結はしないだろう）
    -   [ ] 下線（アンダースコア）のデータあり、暫定で &ensp;で対応
-   [ ] Brahms の 299 ページ目で、現代のタイトルが行溢れしています

