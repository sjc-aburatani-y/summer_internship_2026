# =====================================================================
# 【step2】LINE と「送受信」するプログラムです。
#
# step1 は送るだけでしたが、step2 では相手から届いたメッセージを
# 受け取り、同じ内容をそのまま返す「オウム返し」をします。
#
# しくみ:
#   1. LINE に誰かがメッセージを送る
#   2. LINE がこのプログラム(Webサーバー)に「届いたよ」と連絡する(Webhook)
#   3. このプログラムが内容を読み取り、返信(reply)する
#
# 実行方法（ターミナルで）:
#   cd step2
#   ruby app.rb
#   → その後、Codespaces で公開されたURLを LINE の Webhook に登録します
#     （くわしくは step2/README.md を参照）
# =====================================================================

# ---- 使う道具（ライブラリ）を読み込みます ----

# sinatra は、小さな Web サーバーを作るための道具です。
require "sinatra"
# net/http / uri / json は、step1 と同じく LINE への送信に使います。
require "net/http"
require "uri"
require "json"
# openssl と base64 は、届いた連絡が本当に LINE からのものか
# 確認する「署名チェック」に使う道具です。
require "openssl"
require "base64"
# dotenv/load は、.env ファイルを読み込んで ENV に入れてくれます。
require "dotenv/load"

# ---- 秘密の設定を環境変数から取り出します ----

# メッセージを送る（返信する）ための鍵です。
CHANNEL_ACCESS_TOKEN = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
# 届いた連絡が本物か確認するための、もう1つの鍵(シークレット)です。
CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]

# ---- サーバーの待ち受け設定 ----

# どのパソコンからの接続も受け付ける、という意味の設定です。
# （Codespaces で外から届くようにするために必要です）
set :bind, "0.0.0.0"
# 待ち受けるポート番号です。4567 は sinatra の初期値です。
set :port, 4567

# ---- 動作確認用のページ ----

# ブラウザで「/」を開いたときに表示される簡単な文字です。
# サーバーが動いているかの確認に使えます。
get "/" do
  "LINE 送受信Bot は動いています（step2）"
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
    # テキスト以外(画像やスタンプ)も今回は無視します。
    next unless event["message"]["type"] == "text"

    # 相手が送ってきた文章を取り出します。
    received_text = event["message"]["text"]
    # 返信に必要な「返信用チケット(replyToken)」を取り出します。
    reply_token = event["replyToken"]

    # 受け取った文章をそのまま返信します（オウム返し）。
    reply_message(reply_token, received_text)
  end

  # LINE には「ちゃんと受け取ったよ」という合図(200)を返します。
  status 200
  "OK"
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
