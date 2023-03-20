#!/usr/bin/env ruby

$LOAD_PATH.push( File.expand_path( __FILE__ ) )
require_relative 'myGlobalValue'

def myCorrection( str )

  # hash = {'b'=>'B', 'c'=>'C'}
  # p "abcabc".gsub(/[bc]/, hash)     #=> "aBCaBC"

  # hash1 には 部分文字列を再利用しないパターンを登録
  hash1 = {
    'Ⅰ' => ' I', 'Ⅱ' => ' II', 'Ⅲ' => ' III', 'Ⅳ' => ' IV', 'Ⅴ' => ' V', # 要注意順序
    '朊' => '服',  #「朊」は日本語では通常不使用文字、deepl 訳より「服」
    '，，，' =>  '、、、',
    'アンコ-ル' =>  'アンコール',
    '（１８７０年作曲）' => '（1870年作曲）',
  }
  str.gsub!( /#{hash1.keys.join( '|' )}/, hash1 )

  hash2 = {
    # 括弧のペアリング不一致補正
    '(『)([^「」『』]+)(」)' =>  '『\2』',
    '([（])([^()（）]+)([)])' => '（\2）',
    '([(])([^()（）]+)([）])' => '（\2）',

    # glqq grqq 関連
    '(首回し)”(Wendehals”)' => '\1“\2', # 二重引用符オープン

    # ローマ数字関連
    '[[:space:]]*[IＩ]{3}' => ' III', '[[:space:]]*[IＩ]{2}' => ' II', '[[:space:]]*ＩV' => ' IV',# 要注意順序
    '([^ＭＨＬＩI])Ｉ([^IVＩ])' => '\1I\2',
    '[[:blank:]]*([IV]+<)' => ' \1',
    # タイポ
    'WoO[.]７' => 'WoO.7',
    'WoO22'   => 'WoO.22',
    'WoO.0+'  => 'WoO.',
    'WoO +'   => 'WoO.',
    #
    'ニ(人の擲弾兵|紳士|十頭)' => '二\1', # カタカナ「ニ」(x30cb) が混入
    '(　)−(ああ、神父様、後でいらしてくだされ)' => '\1ー\2', # 余分な文字が混入
    '(　)　(娘さんが病んでおられるのなら)' => '\1ー\2', # 原文に合わせる（上記対応で発見）

    # 表記統一
    "([#{$WAJI}]):" => '\1：', # 和字の直後の「:]を「：」
    "([#{$WAJI}])_([#{$WAJI}])" => '\1　\2', # 和字間を「_」で接続しているが空白に変更
    "[[:blank:]]*([^#{$WAJI}])(，)[[:blank:]]*" => '\1, ', # 和字単語以外のところの「読点（，）」「カンマ(,)」に変更
    '([\p{kana}ー])，([\p{kana}ー])' => '\1,\2', # ファミリ、ネームの順の表記統一
    '([\p{kana}ー]+)−([\p{kana}ー]+)' => '\1＝\2', # 個人名表記の統一
    '([曲番集])[[:blank:]]*[「『]([^「」『』]+)[』」]' => '\1「\2」',
    '(第)(\d+)(曲)' => '\1\2番',

    '　(\d+)　' => ' \1 ',
  }
  hash2.each do | k , v | str.gsub!( /#{k}/, "#{v}" ) if str.match( /#{k}/ ) end

  re = [
    " Erwartung",
    "'s",
    "Abendrot",
    "Ach weh!",
    "Ach",
    "Angel",
    "Aug",
    "Augenzelt",
    "Bewegt",
    "Binsefuss",
    "Bis der Sieg gewonnen hiess.",
    "Buhle",
    "Das Rosenma:rchen ist erza:hlt",
    "Der Glückliche",
    "Der Glücksritter",
    "Der Landreiter",
    "Der Reif",
    "Der Scholar",
    "Der Schreckenberger",
    "Der Soldat",
    "Der greise Kopf",
    "Der stürmische Morgen",
    "Der wandernde Musikant",
    "Der wandernde Student",
    "Der zerbrochne Krug",
    "Des Fremdlings Abendlied",
    "Des Wassermanns",
    "Dichter und ihre Gesellen",
    "Die Blumen sind erstorben",
    "Die Freunde",
    "Die Glücksritter",
    "Die Nachtblume",
    "Die Nachtigallen",
    "Doch in der Mitten",
    "Du liebst mich nicht",
    "Elfenkönig",
    "Eller",
    "Erle",
    "Erlkönig",
    "Four Last Songs",
    "Frau",
    "Geh, Geliebter, geh jetzt!",
    "Geh， Geliebter， geh jetzt!",
    "Gruß",
    "Gukuk!",
    "Ha",
    "Heb' auf dein blondes Haupt",
    "Herz",
    "Hop heisa",
    "Hållilå",
    "Ihr Bild",
    "Ja",
    "Keck und verwegen",
    "Kind",
    "Klapper",
    "Knaben（子供、男の子、童）",
    "Komm! Komm!",
    "Krähe",
    "König",
    "Kühl bis an's Herz hinein",
    "Landsknecht",
    "Lebe wohl!",
    "Lotos",
    "Lotosblume",
    "Lotus",
    "Marion",
    "Marioneta",
    "Meerfahrt",
    "Mein Herz",
    "Mermaid",
    "Mut!",
    "Mut",
    "Mutter",
    "Nachtzauber",
    "Nixe",
    "Nixie",
    "Oho, wieso",
    "Op. 4 No 1 (Quartett)",
    "Op. 4 No. 2",
    "Op. 4 No2 (Chor)",
    "Rast",
    "Rebensaft",
    "Rohr",
    "Romeo und Julia",
    "Schilf",
    "Schilfrohr",
    "Schönheit",
    "Seefalk",
    "Songs I Love",
    "Spiegel",
    "Steckbrief",
    "Teufelsmühle",
    "Tod",
    "Unfall",
    "Verbogenheit",
    "Wasserflut",
    "Wendehals",
    "Wetterfahne",
    "Wiederscheine",
    "Wiener seid froh!",
    "Ziemlich geschwind, doch kräftig",
    "Ziemlich geschwind，doch kräftig",
    "an's",
    "anzusaugen",
    "da war's gescheh'n um dich, Gesell.",
    "da war's gescheh'n um dich，Gesell.",
    "der Sturm",
    "der",
    "die Pforten",
    "ein zerbrochner Ring",
    "ein zerbrochner Ring.",
    "ellerkonge",
    "erfroren",
    "erfroren（凍った）",
    "erstorben",
    "erstorben（死んだ）",
    "ferne in ein kühles Grab",
    "gentle",
    "girl",
    "greise",
    "guck'",
    "hey, ho",
    "hey，ho",
    "hinan",
    "hinein",
    "holdes Bescheiden",
    "innen",
    "ins",
    "lange Jahre vor dir stehn!",
    "mattes",
    "mein Kind",
    "mein frommes Kind",
    "mir",
    "nach dem Angel",
    "nach der Angel",
    "nimmersatter Qual",
    "näselnd",
    "rote Feuerflammen",
    "schaudert dich, mein Blut zu sehn?",
    "schaudert dich，mein Blut zu sehn?",
    "sie",
    "so Gold du bist",
    "so hold du bist",
    "verinnen",
    "von deinem Glanz",
    "zerbrochne",
    "zerbrochner",
    "夜",
    "時",

  ].join( '|' )

  str.gsub!( /(”)(#{re})(”)/ , '“\2\3' )

  str
end

if __FILE__ == $0 then puts myCorrection File.read( ARGV[0] ) end
