# shinonome-unicode

[東雲フォント](http://openlab.ring.gr.jp/efont/shinonome/) Ver0.9.11p1 を
Unicode(ISO10646-1) に変換、１ファイルに合成したものです。

ライセンスは元の東雲フォント同様Public Domainとなります。

サイズは 12px と 16px、ウェイトは Medium と Bold のみです。

それぞれオリジナル東雲フォントの JIS X 0208、JIS X 0201、ISO-8859-1 の内容を合成してあります。

Unicode化と合成の過程で半角・全角が重複した以下のグリフは半角になっています。

- `´`(U+00B4) `ACUTE ACCENT`
- `¨`(U+00A8) `DIAERESIS`
- `±`(U+00B1) `PLUS-MINUS SIGN`
- `×`(U+00D7) `MULTIPLICATION SIGN`
- `÷`(U+00F7) `DIVISION SIGN`
- `°`(U+00B0) `DEGREE SIGN`
- `§`(U+00A7) `SECTION SIGN`
- `¶`(U+00B6) `PILCROW SIGN`

また、波ダッシュ・全角チルダ問題の対応として、波ダッシュのグリフは
波ダッシュ・全角チルダの両方に登録してあります。

`scripts/` 以下の変換・合成・確認用スクリプトもPublic Domainとします。
