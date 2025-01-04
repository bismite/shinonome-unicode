以下、変換作業にあたって調査した内容のメモです。

# 半角・全角が混在するbdfファイル
東雲フォントにはプロポーショナルの shnmk12p.bdf が存在し、
Spacingにもプロポーショナル `P` が存在するので、
bdfファイルにおいて幅は可変でも問題ないようだ。

また、unifont <https://unifoundry.com/unifont/index.html> などは半角・全角が混在している。

## AVERAGE_WIDTH に指定する数値
`AVERAGE_WIDTH` に指定する数値を半角の数値とすべきか `0` にすべきか、
実際の動作を確認した結果、 `0` でないと表示が崩れる場合があった。
結果、以下のようにしておく。

- `AVERAGE_WIDTH` プロパティは `0`
- `SPACING` プロパティは `C`
- `FONTBOUNDINGBOX` は全角と同内容

`FONT` に指定する XLFDも上記のAverage WidthとSpacingを反映したものにしておく。

XLFDについては <https://wiki.archlinux.jp/index.php/X_Logical_Font_Description> や
<https://en.wikipedia.org/wiki/X_logical_font_description> が参考になる。

明確な仕様・情報源が見つからなかったため、正しくない可能性アリ。

## bdfフォントの簡単な動作確認方法
1. bdfファイルの置いてあるディレクトリへ移動
2. `mkfontdir` で `fonts.dir` ファイルを作成
3. `xset +fp $PWD` としてパスを追加、`xset fp rehash` で適用
4. `xfontsel` や `xterm -fn {確認したいフォントのXLFD}` などで確認

終わったら `xset -fp $PWD ; xset fp rehash` でパスから取り除いておく。
また、フォントの内容は `fontforge` で確認することができる。

# unicodeの半角全角について
Unicode には `Halfwidth and Fullwidth Forms` (U+FF00-U+FFEFの範囲) として、半角カタカナや全角英数字などが定義されている。

それ以外の文字の幅については Unicode Standard Annex #11(UAX#11) が参考になる。
例えばポンド記号(`U+00A3`)は `Narrow` であり半角、全角ポンド記号(`U+FFE1`)は `Fullwidth` なので全角が適当となる。
`Ambiguous` とされている文字は、東アジアでは全角、それ以外では半角となる。
`Neutral` はレガシーな文字コードに含まれなかったもので、半角となる。

- 半角となるもの： Halfwidth, Narrow, Neutral
- 全角となるもの： Fullwidth, Wide, Ambiguous

参考：
- <https://ja.wikipedia.org/wiki/東アジアの文字幅>
- <https://www.unicode.org/reports/tr11/>
- <https://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt>
- <https://www.asahi-net.or.jp/~ax2s-kmtn/ref/unicode/uff00.html>

ただし UAX#11 は従来の文字コードとの互換性・相互運用を念頭に定めたもののようで、
一貫性のあるフォントの作成という意味では不適当になりうる。

たとえば `Miscellaneous Symbols` に含まれるトランプのスート♠♣♥♦は、
♠♣♥だけが `Ambiguous` で♦は `Neutral` であるため、素直に実装すると半角と全角が混在してしまう。
（元々は菱形をダイヤに見立てていたため？）

ギリシャ文字やキリル文字も `Ambiguous` と `Neutral` が混在するため、半角になったり全角になったりしてしまう。

文字幅の参考にはなるが、採用するかどうかはケースバイケースというところだろうか。

# フォントの文字コードの変換
オリジナルの東雲フォントには iso8859-1, jisx0201, jisx0208 の3種がある。

jisx0208をUnicodeに直接変換するテーブルは存在したが、すでにOBSOLETEとなっている。
（<https://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0208.TXT>）

EUC-JPやSJISを経由する場合、亜種・派生が多数あり、またそれぞれにUnicodeへの変換表が存在し、変換結果にも違いが生じる。
変換の妥当性についての考察はこちら <https://www.nslabs.jp/round-trip.rhtml> が参考になる。

実際に変換してみたところでは、フォントの変換についても、文字コード変換が妥当であればおおむね妥当な結果になりそう。
個別の対応については以下の通り。

## jisx0208の変換
一部の変換は jisx0208 の波ダッシュを全角チルダに変換してしまう、いわゆる「波ダッシュ問題」を抱えている。
そのため、波ダッシュのグリフは例外的に複製して波ダッシュと全角チルダの両方に登録しておく。

その他、セント記号、ポンド記号、半角￥記号、否定記号などは、
Unicodeの `Halfwidth and Fullwidth Forms` ブロックにある全角版へ割り当てられる。

参考： <https://www.asahi-net.or.jp/~ax2s-kmtn/ref/jisx0208.html>

## jisx0201の変換
jisx0201フォントはチルダがオーバーラインに、バックスラッシュが半角￥に置き換わっている。
これらはそれぞれ `Overline`(`U+203E`) および `Yen Sign`(`U+00A5`) に変換する。

`Overline` は UAX#11 では Ambiguous であり、`Fullwidth Overline` も存在しない。
ただ、jisx0208の全角オーバーラインが `Fullwidth Macron` として変換されるので、
jisx0201版の半角オーバーラインは半角のまま `Overline` として採用する。

参考： <https://ja.wikipedia.org/wiki/JIS_X_0201>

## iso8859-1の変換
変換に問題はない。
ただし、後半部のダイアクリティカルマーク付きアルファベットや記号が Ambiguous を含むため、
半角フォントからの採用は検討の必要があるかもしれない。

参考： <https://ja.wikipedia.org/wiki/ISO/IEC_8859-1>

# jisx0208,jisx0201,iso8859-1の東雲フォントの合成
- jisx0208から 6879文字に波ダッシュを加えて6880文字
- jisx0201から ascii範囲95文字（オーバーラインと半角￥の2文字を含む）と、半角記号・カタカナ63文字、計158文字
- iso8859-1から ascii 95文字 + 後半96文字 (合計191文字)
  - 16px版は後半の NO-BREAK SPACE を含まないため後半95文字、合計190文字

jisx0208とjisx0201に重複は無し。
jisx0201とiso8859-1はasciiの範囲で93文字、また後半部に半角￥を含むため1文字が重複している。
jisx0208とiso8859-1で重複するものは以下の8文字となる。

- `´`(U+00B4) `ACUTE ACCENT`
- `¨`(U+00A8) `DIAERESIS`
- `±`(U+00B1) `PLUS-MINUS SIGN`
- `×`(U+00D7) `MULTIPLICATION SIGN`
- `÷`(U+00F7) `DIVISION SIGN`
- `°`(U+00B0) `DEGREE SIGN`
- `§`(U+00A7) `SECTION SIGN`
- `¶`(U+00B6) `PILCROW SIGN`

結果、12px版は7127文字(6880+2+63+95+96-1-8)となる。
16px版はNO-BREAK SPACEを除いた7126文字となる。

UAX#11の推奨からは外れる部分も出るが、前述の重複を含めて、
iso8859-1範囲の文字は半角のiso8859-1フォントから採用し、半角としておくことにした。
