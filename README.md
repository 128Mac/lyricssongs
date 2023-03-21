
# Table of Contents

1.  [lyricssongs](#orgefcbdca)
    1.  [概要](#orgd48b426)
    2.  [必要なもの](#org19df4ee)
        1.  [git 環境](#orgc7991a2)
        2.  [ruby 環境](#org1ea8d13)
        3.  [JUMAN](#org8095d85)
    3.  [利用方法](#org0d74862)
    4.  [よみ](#org7e35e37)
        1.  [概要](#org8d57e11)
        2.  [yomi.dict の保守](#org7c391a1)
    5.  [TODO](#org97b46b2)



<a id="orgefcbdca"></a>

# lyricssongs


<a id="orgd48b426"></a>

## 概要

[　梅丘歌曲会館 　詩と音楽　](http://www7b.biglobe.ne.jp/~lyricssongs/index.htm)の作曲家別の作品集を latex 化するための　ruby スクリプト


<a id="org19df4ee"></a>

## 必要なもの

-   git 環境
-   ruby 環境
-   JUMAN


<a id="orgc7991a2"></a>

### git 環境

-   これを読めるので基本的な git 環境は OK です

-   スクリプト内部よりローカルな git リポジトリを作成するため、 git
    config で以下の二つを登録
    
        git config --global user.email "you@example.com"
        git config --global user.name "Your Name"


<a id="org1ea8d13"></a>

### ruby 環境

-   html 情報から各種情報を取り出すため ruby nokogiri を利用します
    -   scoop install ruby / brew install ruby / 他
    -   gem install tomlrb nokogiri git
        -   利用する gem パッケージは scripts/Gemfile 参照


<a id="org8095d85"></a>

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


<a id="org0d74862"></a>

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
        
            ruby scripts/21-lyricssongs-tex-gen.rb  COMP/Brahms.htm ...
        
        -   上記の処理で、 作曲家毎に各ディレクトリに LaTeX に必要なものが書き込まれます。
        -   Brams を例にとれば以下のようなものが作成されます。
            -   Brahms.tex
            -   Brahms-hyper-link.tex
            -   Brahms/Brahms-section-nn.tex
            -   Sxxxx.tex
        
        -   廃止(削除ファイル）情報
            -   scripts/20-lyricssongs-tex-gen.rb
            -   scripts/10-lyricssongs-tex-gen.rb
            -   sty/myMacros.sty

-   latex などでビルド
    
        mkdir out
        llmk Brahms/Brahms

-   現在判明していること


<a id="org7e35e37"></a>

## よみ


<a id="org8d57e11"></a>

### 概要

作品タイトル名索引を作成するためには「あいうえお順」になるよう「ひらが
な」にする必要があり、形態要素解析プログラムを今回は juman の出力結果
を利用することとした。

作品情報は「さ-さくいん@索引」のようにひらがなの先頭の一文字を前置する
ように設計したので、以下の点に留意する必要がある。

-   先頭の数文字程度が妥当なひらがなであれば良い
-   先頭の文字が濁点や半濁点などであれば対応の文字を前置する （例「け-げー
    て@ゲーテ」）
-   「第n番」のような作品は 0 を補充して桁合わせするつこと
-   「第１」「第２」「第３」のような場合は「だい1」「だい2」「だい3」の
    ようにするとあいうえお順的に並べることができる

21-lyricssongs-tex-gen.rb は .htm ファイルから .tex ファイルを作成する
際にこの索引情報を生成するが、「よみ」情報を以下のファイルからキャッシュ
として蓄えて利用する。

-   以前 21-lyricssongs-tex-gen.rb で生成した .htm ファイル
-   yomi.dict (ここに登録されたものが有効になる)


<a id="org7c391a1"></a>

### yomi.dict の保守

初回の「よみ」は juman の出力結果で作成される。タイトルだけでは十分な
情報がないため十分な形態要素解析ができず、間違った「よみ」で処理される
ので必要に応じて、修正作業が必要である。

考慮する点は以下のとおおり。

-   先頭数文字が妥当であれば変更不要
-   juman 利用での問題点
    -   「夏」→「か」/「春」→「しゅん」/「花」→「か」のようになることが多い
        -   ある程度はスクリプト内にハードコードして対応はしているが漏れはたくさんある
    -   漢字のままになってしまうケースがあるので 21-lyricssongs-tex-gen.rb
        実行時に以下のような手動編集を促す警告メッセージを表示する
        
            JUMAN （一部）よみ変換できず、要手動編集
            JUMAN よみ 変　換　前 諷刺の歌
            JUMAN よみ 暫定変換後 んんん◆◆のうた
    -   警告メッセージが表示されたものは yomi.dict に「諷刺の歌=>ふうしの
        うた」のように追加登録し、再処理すれば所定の「よみ」が採用される

-   現状の「よみ」情報は、myYomiDictList.rb で表示することができるので
    yomi.dict にリダイレクトしてもよい
-   登録したもののチェックは以下のような方法で確認できる
    
        ruby scripts/myYomi.rb  'ヴェネツィアの歌I' '笑いと涙' 竪琴弾き'


<a id="org97b46b2"></a>

## TODO

-   [X] juman 対応
-   [X] style macro の見直し
-   [X] Op 番号、作品番号の表示が　 Op.Op などとなるなど　とおかしい
    -   Op 番号なしなどがたくさんあるので
    -   他の作者では Op 番号や WoO 番号が無い、あるいはそのほかの記号があるので、対応検討中（アイデア募集）
    -   [X] 整理番号はタイトルの補助的な文字列としスタイルマクロを全面改訂
    -   [X] 作曲者リストの整理番号と作品リストの先頭の文字から各作品の整理番号を合成していたが、
        リンク情報から作品のデータをさらに読み込み、作品整理番号を取得することにした。

-   [X] 予想外のデータ対策（これは当分は終結はしないだろう）
    -   [X] 下線（アンダースコア）のデータあり、暫定で &ensp;で対応
    -   [X] html での &amp; を & に変換するとエラーになるので \\&
    -   [X] Wolf で「>>」&#x2026;「<<」が html encoding された &lt; &gt; になっているので LaTeX エラーが生じている
-   [X] Brahms の 299 ページ目で、原題タイトルが行溢れ
-   [X] Windows 環境で「警告？(guessed encoding: UTF-8 = utf8) 」
    -   [uplatex guess encoding wrong #1137](https://github.com/MiKTeX/miktex/issues/1137)
        [edocevoli commented on Jul 28, 2022](https://github.com/MiKTeX/miktex/issues/1137#issuecomment-1197987983)
        
        This "input encoding" guessing was only implemented on Windows. In
        June, the Windows implementation was ported and is now available
        in the latest pTeX binaries which TeX Live 2022 not yet
        provides. MiKTeX provides the new implementation. Maybe the
        implementation is wrong in some way. I cannot tell. This must be
        fixed upstream.
    
    -   [X] systemu 経由で入手する情報を NKF で UTF-8 化

