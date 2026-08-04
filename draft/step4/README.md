# step4（穴埋め）: メッセージのタイプ判別

**step3（おみくじ）の続き**です。step3 の機能はそのまま残したまま、
**文字以外（画像・スタンプなど）にも反応**できるようにします。

step3 までは文字（text）だけを見て、画像やスタンプは読み飛ばしていました。
step4 では読み飛ばさずに、届いたメッセージの**種類（タイプ）を判別して返事**します。

| 送ったもの | Bot の返事 | |
| --- | --- | --- |
| `おみくじ` | おみくじの結果（大吉〜大凶） | step3 から引き継ぎ |
| その他の文字 | `文字列です。` ＋ 内容と文字数（オウム返し） | step2・step3 から引き継ぎ |
| 画像 | `画像です。` | step4 で追加 |
| 動画 | `動画です。` | step4 で追加 |
| 音声（ボイスメッセージ） | `音声です。` | step4 で追加 |
| ファイル | `ファイルです。` ＋ ファイル名 | step4 で追加 |
| 位置情報 | `位置情報です。` ＋ 住所 | step4 で追加 |
| スタンプ | `スタンプです。` | step4 で追加 |
| 上記以外 | `知らない種類（〇〇）が届きました。` | step4 で追加 |

> 📝 このフォルダの `app.rb` は**未完成**です。
> `______` の所を埋めると動くようになります。
> 答えは [../../complete/step4/app.rb](../../complete/step4/app.rb) にあります。

> 📘 **API ドキュメント**（Webhook の中身・メッセージタイプ一覧・
> 返信 API・署名検証・エラー一覧）は
> [../../complete/step4/README.md の「API ドキュメント」](../../complete/step4/README.md#api-ドキュメント)
> にまとまっています。穴を埋めるときの参考になります。

## step3 から変わったところ

### 1. 「テキスト以外は無視」をやめた

step3 の `post "/callback"` にあったこの行を削除しました。

```ruby
next unless event["message"]["type"] == "text"  # ← step4 では削除
```

これで画像やスタンプも処理に進むようになります。

### 2. 場合分けを「2段」にした

step3 は「おみくじ かどうか」の1段だけでしたが、step4 では
**1段目で種類を分け、文字だったときだけ2段目で step3 の判定**をします。

```
build_reply(message)        ← 1段目: case/when で type を判別
  └─ "text" のとき
       reply_for_text(text) ← 2段目: step3 と同じ「おみくじ？」判定
            └─ omikuji      ← step3 の関数をそのまま利用
```

`omikuji` と `OMIKUJI_RESULTS` は step3 からそのまま持ってきています
（**完成済み**なので、埋める必要はありません）。

## ここで学ぶこと

- LINE から届く JSON には `type` という**種類の情報**が入っていること
- `case` / `when` でたくさんの場合分けをすっきり書く方法
- **Hash**（キーと値の組）からデータを取り出す方法
- 場合分けを「**大きい分け方 → 細かい分け方**」の2段に整理する考え方

## 埋めるところ（全部で 10 個）

| TODO | 場所 | 練習する Ruby の基礎 |
| --- | --- | --- |
| TODO(1) | `post "/callback"` の中 | Hash をまるごと取り出して変数に入れる |
| TODO(2) | `post "/callback"` の中 | Hash を引数として関数にわたす |
| TODO(3) | `build_reply` | Hash から値を取り出す |
| TODO(4) | `build_reply` | `case` で「何を見て分けるか」を指定する |
| TODO(5) | `when "text"` | `when` の中から別の関数を呼ぶ（2段の場合分け） |
| TODO(6) | `when "image"` の下 | `when` を自分で3つ増やす |
| TODO(7) | `when "file"` | Hash の値を文字列に埋め込む |
| TODO(8) | `when "location"` | 同じく、文字列に埋め込む |
| TODO(9) | `else` | どれにも当てはまらないときを受け止める |
| TODO(10) | `reply_for_text` | メソッド `.length` の結果を埋め込む |

`require`・サーバー設定・`OMIKUJI_RESULTS`・`omikuji`・
署名チェック・返信処理は**完成済み**です。

## 埋めるためのヒント

### `case` / `when`

`if` / `elsif` をたくさん並べるかわりに、すっきり書ける書き方です。

```ruby
case fruit
when "りんご"
  "赤いです"
when "ばなな"
  "黄色いです"
else
  "わかりません"      # ← どれにも当てはまらなかったとき
end
```

`case` のうしろに「**何を見て分けるか**」、`when` のうしろに
「**その値だったら**」を書きます。

### 届くメッセージの形（Hash）

種類によって、入っているキーが変わります。

```ruby
# 文字が届いたとき
{ "type" => "text", "id" => "123", "text" => "こんにちは" }

# スタンプが届いたとき
{ "type" => "sticker", "id" => "456", "packageId" => "789", "stickerId" => "52002735" }

# ファイルが届いたとき
{ "type" => "file", "id" => "789", "fileName" => "報告書.pdf", "fileSize" => 1024 }

# 位置情報が届いたとき
{ "type" => "location", "id" => "012", "address" => "東京都新宿区...", "latitude" => 35.6, "longitude" => 139.7 }
```

**どの種類にも必ず `"type"` が入っている**のがポイントです。
まず `"type"` で大きく分けて、それぞれの中で必要なキーを取り出します。

> 全種類の一覧は
> [complete/step4/README.md の「メッセージタイプ一覧」](../../complete/step4/README.md#3-メッセージタイプ一覧eventmessagetype)
> にあります。

### `#{ }` の中には式も書ける

変数だけでなく、`Hash["キー"]` やメソッド呼び出しも書けます。

```ruby
message = { "fileName" => "報告書.pdf" }

"ファイル名: #{message["fileName"]}"   # => ファイル名: 報告書.pdf
"文字数: #{"こんにちは".length}文字"     # => 文字数: 5文字
```

### `.length`（文字数を数える）

```ruby
"こんにちは".length  # => 5
```

## 使うもの

- `LINE_CHANNEL_ACCESS_TOKEN`（返信用の鍵）
- `LINE_CHANNEL_SECRET`（届いた連絡が本物か確認する鍵）

## 実行手順

### 1. サーバーを起動する

step2・step3 のサーバーが動いていたら、先に `Ctrl + C` で止めてください
（同じ `4567` 番ポートを使うためです）。

```bash
cd draft/step4
ruby app.rb
```

> すでに別の step のフォルダにいる場合は、先に `cd ../../` でルートに戻ってください。

### 2. ポートを公開して URL を得る（Codespaces）

1. Codespaces 下部の **「ポート(PORTS)」タブ** を開きます。
2. `4567` のポートを **公開（Public）** に変更します。
3. 表示された URL（`https://....app.github.dev`）をコピーします。

### 3. LINE に Webhook URL を登録する

**Webhook URL** に、コピーした URL の末尾に `/callback` を付けて登録します。

例: `https://xxxx-4567.app.github.dev/callback`

### 4. 試す

自分の LINE から、いろいろな種類を送ってみましょう。

- `おみくじ` と送る → 運勢が返ってくる（step3 の機能がそのまま動きます）
- ふつうの文字を送る → `文字列です。` ＋ 内容と文字数
- カメラロールから画像を送る → `画像です。`
- スタンプを送る → `スタンプです。`
- 位置情報を送る → `位置情報です。` ＋ 住所

## うまく動かないときは

- ブラウザで公開 URL をそのまま開くと
  `おみくじ＋タイプ判別Bot は動いています（step4）` と表示されます。
- 反応しないときは、`ruby app.rb` を実行したターミナルに
  エラーが出ていないか確認してください。
- `undefined local variable or method '______'` と出たら
  → その行の `______` がまだ埋まっていません。
- `syntax error, unexpected ...` と出たら
  → TODO(6) で `______` の行を消し忘れていないか確認しましょう。
- スタンプを送ると `知らない種類（sticker）が届きました。` と返るときは
  → TODO(6) の `when "sticker"` が書けていません。
- 文字を送ると `知らない種類（text）が届きました。` と返るときは
  → TODO(4) の `case` のうしろが正しいか見直してみましょう。

## 全部埋められたら、カスタマイズしてみよう

### 反応するキーワードを増やす

step3 と同じく `reply_for_text` に `elsif` を足します。

```ruby
def reply_for_text(text)
  message = text.strip

  if message == "おみくじ"
    omikuji
  elsif message == "こんにちは"
    "こんにちは！元気ですか？"
  else
    "文字列です。\n\n内容: #{text}\n文字数: #{text.length}文字"
  end
end
```

### スタンプにも中身を出してみる

`build_reply` の `when "sticker"` を書き換えると、
どのスタンプが送られたかも返せます。

```ruby
when "sticker"
  "スタンプです。\n\nスタンプID: #{message["stickerId"]}"
```

## これで完走です

step1 から step4 まで、おつかれさまでした。
完成版のコードや API ドキュメントは
[../../complete/step4/README.md](../../complete/step4/README.md) にあります。
自分が書いたコードと見比べてみましょう。
