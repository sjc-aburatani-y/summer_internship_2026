# step1（穴埋め）: 送信のみ

LINE の友だち**全員に、一方的にメッセージを送るだけ**のステップです。
まずはこの step1 で「LINE に送る」流れを体験しましょう。

> 📝 このフォルダの `send_message.rb` は**未完成**です。
> `______` の所を埋めると動くようになります。
> 答えは [../../complete/step1/send_message.rb](../../complete/step1/send_message.rb)
> にあります（まずは見ずに挑戦してみましょう）。

## 埋めるところ（全部で 4 個）

| TODO | 場所 | 練習する Ruby の基礎 |
| --- | --- | --- |
| TODO(1) | `send_message` の先頭 | `if` と `\|\|`（または）で条件を2つつなげる |
| TODO(2) | `request.body` の中 | 関数の**引数**を使う |
| TODO(3) | 送信のあと | `==` で値をくらべる |
| TODO(4) | 成功したときの `puts` | 文字列に変数を埋め込む `#{ }` |

`require` の行や、`Net::HTTP` で実際に送る部分は**完成済み**です。
書き換えなくて大丈夫です。

## 埋めるためのヒント

### `nil?` と `empty?`

```ruby
name = nil
name.nil?    # => true  （値が入っていない）

name = ""
name.nil?    # => false （値は入っている）
name.empty?  # => true  （でも空っぽ）
```

`||` は「または」です。`A || B` は「A か B のどちらかが成り立つ」。

### `#{ }`（文字列に変数を埋め込む）

```ruby
name = "たろう"
puts "こんにちは、#{name}さん"  # => こんにちは、たろうさん
```

## 使うもの

- `LINE_CHANNEL_ACCESS_TOKEN`（送信用の鍵）

> step1 では受信をしないので、`LINE_CHANNEL_SECRET` は不要です。

## 実行手順

1. リポジトリのルートに `.env` を用意します
   （`.env.example` をコピーしてトークンを記入）。
2. ルートで `bundle install` を実行します（Codespaces では自動）。
3. このフォルダに移動して実行します。

```bash
cd draft/step1
ruby send_message.rb
```

`送信に成功しました！` と表示され、友だち全員に届けば成功です。

## うまく動かないときは

- `syntax error` と出たら → `______` を消し忘れていないか確認しましょう。
- `undefined local variable or method '______'` と出たら
  → その行の `______` がまだ埋まっていません。
- `エラー: LINE_CHANNEL_ACCESS_TOKEN が設定されていません` と出たら
  → `.env` にトークンが入っているか確認しましょう。
  （TODO(1) が正しく埋められている証拠でもあります）

## 送る文章を変えるには

`send_message.rb` の一番下の行を書き換えてください。

```ruby
send_message("こんにちは！これはテスト送信です。")
```

> ⚠️ broadcast は友だち**全員**に届きます。動作確認は、友だちが
> 自分だけの状態で試すのがおすすめです。

## 次のステップ

送るだけでなく「届いたメッセージに返信」したくなったら
[../step2/](../step2/) に進みましょう。
