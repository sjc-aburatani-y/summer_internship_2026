# step2（穴埋め）: 送受信（受信して返信）

相手から届いたメッセージを**受け取って、同じ内容を返信（オウム返し）**する
ステップです。step1 の「送るだけ」から一歩進みます。

> 📝 このフォルダの `app.rb` は**未完成**です。
> `______` の所を埋めると動くようになります。
> 答えは [../../complete/step2/app.rb](../../complete/step2/app.rb) にあります。

## しくみ

1. LINE に誰かがメッセージを送る
2. LINE がこのプログラム（Webサーバー）に「届いたよ」と連絡する（Webhook）
3. このプログラムが内容を読み取り、返信する

受信するには「LINE から連絡を受け取る住所（URL）」が必要です。
Codespaces のポート公開機能を使って、その URL を用意します。

## 埋めるところ（全部で 6 個）

穴はすべて `post "/callback" do` 〜 `end` の中にあります。

| TODO | 練習する Ruby の基礎 |
| --- | --- |
| TODO(1) | Hash から値を取り出す ＋ `each` でくり返す |
| TODO(2) | 取り出した値を `==` でくらべる |
| TODO(3) | Hash の中の Hash から値を取り出す |
| TODO(4) | 取り出した値を変数に入れる |
| TODO(5) | 同じく、変数に入れる |
| TODO(6) | 自分で作った関数を、引数をわたして呼び出す |

`require` の行、サーバー設定、署名チェック（`valid_signature?`）、
返信処理（`reply_message`）は**完成済み**です。書き換えなくて大丈夫です。

## 埋めるためのヒント

### 届く JSON の形

LINE からは、こんな形のデータが届きます。

```ruby
{
  "destination" => "Uxxxxxxxx",
  "events" => [
    {
      "type" => "message",
      "replyToken" => "abcd1234",
      "message" => { "type" => "text", "text" => "こんにちは" }
    }
  ]
}
```

キーと値の組になっている入れ物を **Hash（ハッシュ）** と呼びます。

### Hash から値を取り出す

```ruby
event = { "type" => "message", "replyToken" => "abcd1234" }

event["type"]        # => "message"
event["replyToken"]  # => "abcd1234"
```

Hash の中の Hash は `[ ]` を2回つなげます。

```ruby
event["message"]["text"]  # => "こんにちは"
```

### `each` でくり返す

```ruby
["あか", "あお"].each do |color|
  puts color   # あか → あお の順に表示される
end
```

### `next unless`

```ruby
next unless event["type"] == "message"
```

「`event["type"]` が `"message"` **でなければ**、次のくり返しへ飛ばす」
＝「`"message"` のときだけ先に進む」という意味です。

## 使うもの

- `LINE_CHANNEL_ACCESS_TOKEN`（返信用の鍵）
- `LINE_CHANNEL_SECRET`（届いた連絡が本物か確認する鍵）

## 実行手順

### 1. サーバーを起動する

ルートで `bundle install` 済みであることを確認し、このフォルダで起動します。

```bash
cd draft/step2
ruby app.rb
```

`4567` 番ポートでサーバーが立ち上がります。

### 2. ポートを公開して URL を得る（Codespaces）

1. Codespaces 下部の **「ポート(PORTS)」タブ** を開きます。
2. `4567` のポートを **公開（Public）** に変更します。
3. 表示された URL（`https://....app.github.dev`）をコピーします。

### 3. LINE に Webhook URL を登録する

1. LINE Developers コンソールのチャネル「Messaging API」設定を開きます。
2. **Webhook URL** に、コピーした URL の末尾に `/callback` を付けて登録します。
   例: `https://xxxx-4567.app.github.dev/callback`
3. **「Webhookの利用」をオン**にします。
4. 自動応答メッセージ（あいさつ・応答）は必要に応じてオフにします。

### 4. 試す

自分の LINE から Bot にメッセージを送ると、同じ内容が返ってくれば成功です。

## うまく動かないときは

- ブラウザで公開 URL をそのまま開くと
  `LINE 送受信Bot は動いています（step2）` と表示され、
  サーバーが動いているか確認できます。
  （この表示は穴を埋める前から出ます）
- 返信が来ないときは、`ruby app.rb` を実行したターミナルに
  エラーが出ていないか確認してください。
- `undefined local variable or method '______'` と出たら
  → その行の `______` がまだ埋まっていません。
- `署名が正しくありません` と返るときは
  → `LINE_CHANNEL_SECRET` が正しいか確認しましょう（穴埋めとは別の原因です）。
- `undefined method '[]' for nil` と出たら
  → TODO(1) のキー名や、TODO(3)〜(5) の `[ ]` の数を見直してみましょう。

## 次のステップ

同じ返事ではなく「届いた言葉によって返事を変える」ようにしたくなったら
[../step3/](../step3/) に進みましょう。
