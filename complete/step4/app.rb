# =====================================================================
# 【step4】届いたメッセージの「種類(タイプ)」を判別するプログラムです。
#
# step3（おみくじ）の続きです。step3 の機能はそのまま残したまま、
# 「文字以外」にも反応できるようにします。
#
# step3 までは「文字(text)」だけを見ていて、画像やスタンプは
# next で読み飛ばしていました。
# step4 では読み飛ばさずに、何が届いたのかを判別して返事をします。
#
#   ・「おみくじ」と送られたら → omikuji の結果を返す  ← step3 から引き継ぎ
#   ・その他の文字が届いたら   → 「文字列です」＋ 内容（オウム返し）
#   ・画像が届いたら           → 「画像です」          ← step4 で追加
#   ・スタンプが届いたら       → 「スタンプです」      ← step4 で追加
#   ・…など
#
# ここで学ぶこと:
#   1. LINE から届くデータ(JSON)には「type」という種類の情報があること
#   2. case / when で、たくさんの場合分けをすっきり書く方法
#   3. Hash（キーと値の組）からデータを取り出す方法
#   4. 場合分けを「大きい分け方 → 細かい分け方」の2段にする考え方
#
# 実行方法（ターミナルで）:
#   cd step4
#   ruby app.rb
#   （すでに別の step のフォルダにいる場合は、先に cd ../../ でルートに戻ってください）
#   → その後、Codespaces で公開されたURLを LINE の Webhook に登録します
#     （くわしくは step4/README.md を参照）
# =====================================================================

# ---- 使う道具（ライブラリ）を読み込みます ----
# 使う道具は step3 とまったく同じです。

# sinatra は、小さな Web サーバーを作るための道具です。
require "sinatra"
# net/http / uri / json は、LINE への送信に使います。
require "net/http"
require "uri"
require "json"
# openssl と base64 は、届いた連絡が本当に LINE からのものか
# 確認する「署名チェック」に使う道具です。
require "openssl"
require "base64"
# dotenv は、.env ファイルを読み込んで ENV に入れてくれます。
# リポジトリルートの .env を直接指定して読み込みます。
require "dotenv"
Dotenv.load(File.expand_path("../../.env", __dir__))

# ---- 秘密の設定を環境変数から取り出します ----

# メッセージを送る（返信する）ための鍵です。
CHANNEL_ACCESS_TOKEN = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
# 届いた連絡が本物か確認するための、もう1つの鍵(シークレット)です。
CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]

# ---- おみくじの中身を用意します（step3 から引き継ぎ） ----

# [ ] で囲んだものを「配列(はいれつ)」と呼びます。
# ここに書いた中から1つが選ばれます。増やしても減らしてもOKです。
OMIKUJI_RESULTS = [
  "大吉",
  "中吉",
  "小吉",
  "吉",
  "末吉",
  "凶",
  "大凶"
]

# ---- サーバーの待ち受け設定 ----

# どのパソコンからの接続も受け付ける、という意味の設定です。
# （Codespaces で外から届くようにするために必要です）
set :bind, "0.0.0.0"
# 待ち受けるポート番号です。4567 は sinatra の初期値です。
set :port, 4567
# どの住所(ホスト名)からのアクセスも許可する、という設定です。
# sinatra は安全のため、初期状態だと localhost 以外を
# 「Host not permitted」と拒否します。Codespaces の公開URL
# （...app.github.dev）で受け取れるように、この制限を外します。
set :host_authorization, { permitted_hosts: [] }

# ---- 動作確認用のページ ----

# ブラウザで「/」を開いたときに表示される簡単な文字です。
# サーバーが動いているかの確認に使えます。
get "/" do
  "おみくじ＋タイプ判別Bot は動いています（step4）"
end

# ---- LINE からの連絡(Webhook)を受け取る入り口 ----

# LINE は「/callback」という住所に POST で連絡してきます。
post "/callback" do
  # 届いた本文（まだ文字のかたまり）を読み取ります。
  body = request.body.read

  # まず、この連絡が本当に LINE からのものかを確認します。
  # にせものを受け付けないための、大切なセキュリティ確認です。
  unless valid_signature?(body, request.env["HTTP_X_LINE_SIGNATURE"])
    halt 400, "署名が正しくありません"
  end

  # 文字のかたまり(JSON)を、Ruby が扱いやすい形に変換します。
  data = JSON.parse(body)

  # 1回の連絡に複数の出来事(events)が入っていることがあるので、
  # each で1つずつ順番に処理します。
  data["events"].each do |event|
    # メッセージ以外の出来事(友だち追加など)は今回は無視します。
    next unless event["type"] == "message"

    # ★step4 の新しいところ★
    # step3 までは、ここに
    #   next unless event["message"]["type"] == "text"
    # と書いて「テキスト以外は無視」していました。
    # step4 ではこの行を消して、画像やスタンプも受け取ります。

    # 返信に必要な「返信用チケット(replyToken)」を取り出します。
    reply_token = event["replyToken"]

    # メッセージの中身（type や text が入っている部分）を取り出します。
    message = event["message"]

    # 返す文章を組み立てます。
    # step3 では「文字」だけを渡していましたが、
    # step4 では種類も見たいので、message ごと渡します。
    reply_text = build_reply(message)

    # 作った返事を送ります。
    reply_message(reply_token, reply_text)
  end

  # LINE には「ちゃんと受け取ったよ」という合図(200)を返します。
  status 200
  "OK"
end

# ---- 【1段目の場合分け】届いたメッセージの種類を判別する ----

# message には、LINE から届いた「メッセージの中身」が入っています。
# 例）文字が届いたとき:
#   { "type" => "text", "id" => "123", "text" => "こんにちは" }
# 例）スタンプが届いたとき:
#   { "type" => "sticker", "id" => "456", "packageId" => "789", ... }
#
# このように、キー（"type" など）と値（"text" など）が
# セットになっている入れ物を Hash（ハッシュ）と呼びます。
# message["type"] と書くと、"type" に対応する値を取り出せます。
def build_reply(message)
  # どの種類のメッセージにも必ず "type" が入っています。
  type = message["type"]

  # case 〜 when 〜 end は、if / elsif をたくさん並べるかわりに
  # 「この値だったらこれ」とすっきり書ける書き方です。
  case type
  when "text"
    # 文字のときだけ、さらに細かい判定（2段目）にわたします。
    # ここで step3 のおみくじ機能につながります。
    reply_for_text(message["text"])
  when "image"
    "画像です。"
  when "video"
    "動画です。"
  when "audio"
    "音声です。"
  when "file"
    # ファイルのときは、ファイル名も届きます。
    "ファイルです。\n\nファイル名: #{message["fileName"]}"
  when "location"
    # 位置情報のときは、住所や緯度経度も届きます。
    "位置情報です。\n\n住所: #{message["address"]}"
  when "sticker"
    "スタンプです。"
  else
    # LINE は将来あたらしい種類を増やすことがあります。
    # 知らない種類が来ても止まらないように、else を用意しておきます。
    "知らない種類（#{type}）が届きました。"
  end
end

# ---- 【2段目の場合分け】文字が届いたときの返事を決める ----

# ここは step3 の build_reply とほとんど同じ中身です。
# 「おみくじ」なら omikuji、それ以外なら中身を返します。
def reply_for_text(text)
  # strip は、前後の余分な空白や改行を取り除いてくれます。
  # 「 おみくじ 」のように空白が入っていても反応できるようにします。
  message = text.strip

  if message == "おみくじ"
    # step3 と同じく、おみくじの結果を返します。
    omikuji
  else
    # step4 では「文字列です」と種類を伝えつつ、
    # step2・step3 のオウム返しも一緒に返します。
    # .length は文字数を数えてくれます。
    "文字列です。\n\n内容: #{text}\n文字数: #{text.length}文字"
  end
end

# ---- おみくじの処理（step3 から引き継ぎ） ----

# 呼び出されるたびに、おみくじの結果を1つ作って返す関数です。
def omikuji
  # 配列.sample は、配列の中からランダムに1つ選んでくれます。
  # （毎回ちがう結果になるのはこのおかげです）
  result = OMIKUJI_RESULTS.sample

  # 返す文章を組み立てます。
  # "#{ }" の中には、変数の中身をそのまま埋め込めます。
  # \n は「ここで改行する」という意味の書き方です。
  "🎋 今日の運勢は…\n\n【 #{result} 】\n\nまた引きたいときは「おみくじ」と送ってね！"
end

# ---- 届いた連絡が本物かを確認する処理 ----

def valid_signature?(body, signature)
  # シークレットが無いと確認できないので、その場合は false を返します。
  return false if CHANNEL_SECRET.nil? || CHANNEL_SECRET.empty?
  return false if signature.nil?

  # シークレットを鍵にして、本文から「正しい署名」を自分で計算します。
  hash = OpenSSL::HMAC.digest("SHA256", CHANNEL_SECRET, body)
  expected = Base64.strict_encode64(hash)

  # LINE から届いた署名と、自分で計算した署名が一致すれば本物です。
  # secure_compare は、安全に文字列を比べるための方法です。
  Rack::Utils.secure_compare(expected, signature)
end

# ---- 返信する処理 ----

def reply_message(reply_token, text)
  # 返信専用の窓口(URL)です。step1 の broadcast とは別の住所です。
  uri = URI.parse("https://api.line.me/v2/bot/message/reply")

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{CHANNEL_ACCESS_TOKEN}"

  # 返信では「どの連絡への返事か(replyToken)」を必ず指定します。
  request.body = {
    replyToken: reply_token,
    messages: [
      { type: "text", text: text }
    ]
  }.to_json

  # 実際に返信を送ります。
  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
end
