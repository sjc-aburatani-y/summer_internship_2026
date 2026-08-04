# step4: メッセージのタイプ判別

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

`omikuji` と `OMIKUJI_RESULTS` は step3 からそのまま持ってきています。

## ここで学ぶこと

- LINE から届く JSON には `type` という**種類の情報**が入っていること
- `case` / `when` でたくさんの場合分けをすっきり書く方法
- **Hash**（キーと値の組）からデータを取り出す方法
- 場合分けを「**大きい分け方 → 細かい分け方**」の2段に整理する考え方

## 使うもの

- `LINE_CHANNEL_ACCESS_TOKEN`（返信用の鍵）
- `LINE_CHANNEL_SECRET`（届いた連絡が本物か確認する鍵）

## 実行手順

### 1. サーバーを起動する

step2・step3 のサーバーが動いていたら、先に `Ctrl + C` で止めてください
（同じ `4567` 番ポートを使うためです）。

```bash
cd complete/step4
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

## カスタマイズしてみよう

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

どんなキーが使えるかは、下の
[メッセージタイプ一覧](#3-メッセージタイプ一覧eventmessagetype) を見てください。

---

# API ドキュメント

ここからは、このプロジェクトで使っている **LINE Messaging API** と、
**自分たちで作ったサーバー（app.rb）** の仕様をまとめたものです。

## 1. このアプリが公開しているエンドポイント

サーバー（`app.rb`）が受け付ける「窓口」の一覧です。

| メソッド | パス | 用途 | 呼ぶ人 |
| --- | --- | --- | --- |
| `GET` | `/` | 動作確認（起動しているかを見る） | 自分（ブラウザ） |
| `POST` | `/callback` | LINE からの Webhook を受け取る | LINE のサーバー |

### `GET /`

- **リクエスト**: なし
- **レスポンス**: `200 OK` / `text/html`
  ```
  おみくじ＋タイプ判別Bot は動いています（step4）
  ```

### `POST /callback`

LINE でメッセージが送られたときに、LINE のサーバーから呼ばれます。

**リクエストヘッダー**

| ヘッダー | 説明 |
| --- | --- |
| `Content-Type` | `application/json` |
| `X-Line-Signature` | 本文の署名。本物の LINE からか確認するために使う |

**リクエストボディ（例: 文字が届いたとき）**

```json
{
  "destination": "Uxxxxxxxxxxxxxxxxxxxxxxxx",
  "events": [
    {
      "type": "message",
      "replyToken": "0f3779fba3b349968c5d07db31eab56f",
      "timestamp": 1735689600000,
      "source": { "type": "user", "userId": "Uxxxxxxxxxxxxxxxxxxxxxxxx" },
      "message": {
        "id": "444573844083572737",
        "type": "text",
        "text": "こんにちは"
      }
    }
  ]
}
```

**レスポンス**

| ステータス | 意味 |
| --- | --- |
| `200 OK` | 正常に受け取った（本文は `OK`） |
| `400 Bad Request` | 署名が正しくない（本文は `署名が正しくありません`） |

> LINE は `200` 以外が返ると「失敗」とみなします。
> 返信の中身に関係なく、受け取れたら必ず `200` を返すのが基本です。

## 2. Webhook イベントの構造

`events` は**配列**です。1回の連絡に複数のイベントが入ることがあるので、
`each` で1つずつ処理します。

### 主なイベントタイプ（`event["type"]`）

| 値 | いつ来るか |
| --- | --- |
| `message` | メッセージが送られたとき（このアプリが扱うのはこれ） |
| `follow` | 友だち追加・ブロック解除されたとき |
| `unfollow` | ブロックされたとき（`replyToken` なし＝返信できない） |
| `join` / `leave` | グループへの参加・退出 |
| `postback` | ボタンなどが押されたとき |

### イベント共通のフィールド

| キー | 型 | 説明 |
| --- | --- | --- |
| `type` | string | イベントの種類（上の表） |
| `replyToken` | string | 返信用のチケット。**1回だけ・約1分以内**に使う |
| `timestamp` | number | 発生時刻（ミリ秒） |
| `source.type` | string | `user` / `group` / `room` |
| `source.userId` | string | 送った人の ID |

## 3. メッセージタイプ一覧（`event["message"]["type"]`）

step4 で判別しているのが、この `type` です。

| `type` | 意味 | 特徴的なキー |
| --- | --- | --- |
| `text` | 文字 | `text`（本文）, `emojis` |
| `image` | 画像 | `contentProvider` |
| `video` | 動画 | `duration`, `contentProvider` |
| `audio` | 音声 | `duration`, `contentProvider` |
| `file` | ファイル | `fileName`, `fileSize` |
| `location` | 位置情報 | `title`, `address`, `latitude`, `longitude` |
| `sticker` | スタンプ | `packageId`, `stickerId`, `stickerResourceType` |

どのタイプにも共通で `id`（メッセージID）が入ります。
画像・動画・音声・ファイルの**中身そのもの**は Webhook には含まれず、
別途 `GET /v2/bot/message/{messageId}/content` で取得します。

**例: スタンプが届いたときの `message`**

```json
{
  "id": "444573844083572737",
  "type": "sticker",
  "packageId": "446",
  "stickerId": "1988",
  "stickerResourceType": "STATIC"
}
```

**例: 位置情報が届いたときの `message`**

```json
{
  "id": "444573844083572737",
  "type": "location",
  "title": "会社",
  "address": "東京都千代田区...",
  "latitude": 35.6812,
  "longitude": 139.7671
}
```

## 4. このプロジェクトが呼び出す LINE API

### 返信する（step2・step3・step4）

```
POST https://api.line.me/v2/bot/message/reply
```

| ヘッダー | 値 |
| --- | --- |
| `Content-Type` | `application/json` |
| `Authorization` | `Bearer {チャネルアクセストークン}` |

**ボディ**

```json
{
  "replyToken": "0f3779fba3b349968c5d07db31eab56f",
  "messages": [
    { "type": "text", "text": "文字列です。" }
  ]
}
```

| キー | 必須 | 説明 |
| --- | --- | --- |
| `replyToken` | ○ | Webhook で受け取ったトークン。**使い回し不可** |
| `messages` | ○ | 送るメッセージの配列（**最大5件**） |

- 返信は**無料**です（push と違って通数にカウントされません）。
- テキスト1件は**最大5000文字**です。

### 全員に送る（step1）

```
POST https://api.line.me/v2/bot/message/broadcast
```

**ボディ**

```json
{
  "messages": [
    { "type": "text", "text": "こんにちは！" }
  ]
}
```

`replyToken` は不要です。友だち**全員**に届くので取り扱い注意です。

### 主なエラーレスポンス

| ステータス | 原因 | 対処 |
| --- | --- | --- |
| `400` | ボディの形が不正 / `replyToken` が無効・期限切れ | JSON の形とトークンを確認 |
| `401` | アクセストークンが違う・空 | `.env` の `LINE_CHANNEL_ACCESS_TOKEN` を確認 |
| `403` | プランや権限が足りない | チャネル設定を確認 |
| `429` | 送りすぎ（レート制限） | しばらく待つ |

エラー時のボディ例:

```json
{
  "message": "Invalid reply token"
}
```

## 5. 署名検証（`X-Line-Signature`）

`/callback` は世界中から呼べる URL なので、**本当に LINE からの連絡か**を
必ず確認します（`app.rb` の `valid_signature?`）。

手順は3つです。

1. **チャネルシークレット**を鍵にして、リクエストボディの
   HMAC-SHA256 ダイジェストを計算する
2. それを Base64 でエンコードする
3. `X-Line-Signature` ヘッダーの値と一致するか比べる

```ruby
hash = OpenSSL::HMAC.digest("SHA256", CHANNEL_SECRET, body)
expected = Base64.strict_encode64(hash)
Rack::Utils.secure_compare(expected, signature)
```

> `==` ではなく `secure_compare` を使うのは、比較にかかる時間の差から
> 正解を推測される攻撃（タイミング攻撃）を防ぐためです。

## 6. 公式ドキュメント

| 内容 | URL |
| --- | --- |
| Messaging API リファレンス | https://developers.line.biz/ja/reference/messaging-api/ |
| Webhook イベントオブジェクト | https://developers.line.biz/ja/reference/messaging-api/#webhook-event-objects |
| メッセージオブジェクト | https://developers.line.biz/ja/reference/messaging-api/#message-objects |
| 署名の検証 | https://developers.line.biz/ja/docs/messaging-api/receiving-messages/#verify-signature |

---

## 動作確認のヒント

- ブラウザで公開 URL をそのまま開くと
  `おみくじ＋タイプ判別Bot は動いています（step4）` と表示されます。
- 反応しないときは、`ruby app.rb` を実行したターミナルに
  エラーが出ていないか確認してください。
- 「おみくじ」は step3 と同じく**完全に一致**したときだけ反応します。
- 届いた JSON をそのまま見たいときは、`post "/callback"` の中に
  `puts body` を1行足すとターミナルに表示されます。
  上の「API ドキュメント」と見比べてみましょう。
