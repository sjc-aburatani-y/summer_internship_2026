# LINE Bot 学習プロジェクト（step1 → step4）

LINE Bot を4つのステップで少しずつ学ぶための教材プロジェクトです。

- **step1: 送信のみ** … LINE の友だち全員へ一方的に送る
- **step2: 送受信** … 届いたメッセージを受け取って返信する（オウム返し）
- **step3: おみくじ** … 届いた言葉によって返事を変える
- **step4: タイプ判別** … step3 に加えて、文字・画像・スタンプなど届いた種類を判別する

技術スタック:

- 言語: Ruby 4
- 開発環境: GitHub Codespaces（`.devcontainer` で自動構築）
- 機密情報: 環境変数（`.env` / Codespaces Secrets）で管理

---

## 2種類のフォルダ（draft と complete）

同じ step1〜step4 が、**2つの形**で入っています。

| フォルダ | 中身 | 使い方 |
| --- | --- | --- |
| [draft/](draft/) | **穴埋め版**（`______` を自分で埋める） | 👈 **こちらで進めます** |
| [complete/](complete/) | **完成版**（そのまま動く） | 答え合わせ・詰まったときに見る |

**基本の流れ**

1. `draft/step1/` を開き、`______` の所を埋める
2. 動かしてみる → 動いたら次の step へ
3. どうしても分からないときは `complete/` の同じファイルを見る

`draft/` の各 `README.md` に「埋めるところの一覧」と
「埋めるためのヒント」を書いてあります。まずそこを読んでから始めましょう。

> 穴になっているのは **Ruby の基礎**にあたる部分だけです。
> `require` の行や、LINE へ送る通信の処理、署名チェックなどは
> `draft/` でも完成させてあるので、書き換える必要はありません。

---

## ステップ一覧

| ステップ | 内容 | 穴埋め版 | 完成版 |
| --- | --- | --- | --- |
| step1 | 送信のみ（全員へ一斉送信） | [draft/step1/](draft/step1/) | [complete/step1/](complete/step1/) |
| step2 | 送受信（受信して返信） | [draft/step2/](draft/step2/) | [complete/step2/](complete/step2/) |
| step3 | おみくじ（届いた言葉で返事を変える） | [draft/step3/](draft/step3/) | [complete/step3/](complete/step3/) |
| step4 | メッセージのタイプ判別（step3 ＋ 画像・スタンプ対応） | [draft/step4/](draft/step4/) | [complete/step4/](complete/step4/) |

まず step1 から進めるのがおすすめです。各フォルダの `README.md` に
そのステップの詳しい手順を書いています。

### 各ステップで練習する Ruby の基礎

| ステップ | 穴の数 | 練習する内容 |
| --- | --- | --- |
| step1 | 4 個 | `if` と `\|\|`、関数の引数、`==` での比較、`#{ }` での埋め込み |
| step2 | 6 個 | Hash からの取り出し、`each`、`next unless`、関数の呼び出し |
| step3 | 8 個 | 配列、`.sample`、`.strip`、`if` / `else`、関数の返り値 |
| step4 | 10 個 | `case` / `when`、`else`、Hash の使い分け、`.length` |

> 📘 **API ドキュメント**（Webhook の中身・メッセージタイプ一覧・
> 返信 API・署名検証・エラー一覧）は
> [complete/step4/README.md の「API ドキュメント」](complete/step4/README.md#api-ドキュメント)
> にまとめています。

> step2 以降はどれも `4567` 番ポートでサーバーを起動します。
> 別のステップを試すときは、前のサーバーを `Ctrl + C` で止めてください。
> （`draft` と `complete` を同時に起動することもできません）

---

## 最初の準備（共通）

### 1. LINE 側の準備

1. [LINE Developers コンソール](https://developers.line.biz/) にログインします。
2. 新しい **Messaging API チャネル** を作成します。
3. 「Messaging API」タブから **チャネルアクセストークン（長期）** を発行します。
   → `LINE_CHANNEL_ACCESS_TOKEN`
4. 「チャネル基本設定」から **チャネルシークレット** を確認します。
   → `LINE_CHANNEL_SECRET`（step2 で使います）
5. 作成した Bot を、自分の LINE で**友だち追加**します。

### 2. 環境変数の設定

#### Codespaces で動かす場合（おすすめ）

リポジトリの **Settings → Secrets and variables → Codespaces** から登録します。

| 名前 | 使うステップ |
| --- | --- |
| `LINE_CHANNEL_ACCESS_TOKEN` | step1・step2・step3・step4 |
| `LINE_CHANNEL_SECRET` | step2・step3・step4 |

#### 手元のパソコンで動かす場合

`.env.example` をコピーして `.env` を作り、値を書き換えます。

```bash
cp .env.example .env
```

> `.env` は `.gitignore` で除外済みなので、GitHub には上がりません。

### 3. gem のインストール

Codespaces では起動時に `bundle install` が自動実行されます。
手元の場合は、ルートで一度だけ実行してください。

```bash
bundle install
```

---

## ファイル構成

`draft/` と `complete/` の中身は同じ構成です。
`.env` や `Gemfile` はルートに1つだけあり、どちらからでも使えます。

```
.
├── .devcontainer/
│   └── devcontainer.json  … Codespaces の環境設定（Ruby 4）
├── .env.example           … 環境変数の見本
├── .gitignore             … .env などをアップロードしない設定
├── Gemfile                … 使う gem 一覧（dotenv / sinatra / puma）
├── README.md              … このファイル（全体ガイド）
│
├── draft/                 … 【穴埋め版】ここで進めます
│   ├── step1/             … 送信のみ
│   │   ├── send_message.rb   … ______ を4個埋める
│   │   └── README.md
│   ├── step2/             … 送受信（オウム返し）
│   │   ├── app.rb            … ______ を6個埋める
│   │   └── README.md
│   ├── step3/             … おみくじ
│   │   ├── app.rb            … ______ を8個埋める
│   │   └── README.md
│   └── step4/             … タイプ判別
│       ├── app.rb            … ______ を10個埋める
│       └── README.md
│
└── complete/              … 【完成版】答え合わせ用
    ├── step1/
    │   ├── send_message.rb
    │   └── README.md
    ├── step2/
    │   ├── app.rb
    │   └── README.md
    ├── step3/
    │   ├── app.rb
    │   └── README.md
    └── step4/             … ＋ API ドキュメント
        ├── app.rb
        └── README.md
```
