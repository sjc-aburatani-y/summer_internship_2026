# =====================================================================
# 【step3】届いた言葉によって「返す内容を変える」プログラムです。
#
# step2 は何を送られても同じ内容を返すだけ（オウム返し）でしたが、
# step3 では中身を見て、返事を切り替えます。
#
#   ・「おみくじ」と送られたら  → omikuji の結果を返す
#   ・それ以外が送られたら      → step2 と同じくオウム返し
#
# ここで学ぶこと:
#   1. if / else で「場合分け」をする
#   2. 自分で def（関数）を作って呼び出す
#   3. 配列と sample でランダムに1つ選ぶ
#
# 実行方法（ターミナルで）:
#   cd step3
#   ruby app.rb
#   → その後、Codespaces で公開されたURLを LINE の Webhook に登録します
#     （くわしくは step3/README.md を参照）
# =====================================================================

# ---- 使う道具（ライブラリ）を読み込みます ----
# 使う道具は step2 とまったく同じです。

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
# dotenv/load は、.env ファイルを読み込んで ENV に入れてくれます。
require "dotenv/load"

# ---- 秘密の設定を環境変数から取り出します ----

# メッセージを送る（返信する）ための鍵です。
CHANNEL_ACCESS_TOKEN = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
# 届いた連絡が本物か確認するための、もう1つの鍵(シークレット)です。
CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]

# ---- おみくじの中身を用意します ----

# [ ] で囲んだものを「配列(はいれつ)」と呼びます。
# たくさんの値を、順番に並べてまとめて持っておける入れ物です。
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
  "おみくじBot は動いています（step3）"
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

    # ★step3 の新しいところ★
    # 返事の内容を、届いた文章によって作り分けます。
    reply_text = build_reply(received_text)

    # 作った返事を送ります。
    reply_message(reply_token, reply_text)
  end

  # LINE には「ちゃんと受け取ったよ」という合図(200)を返します。
  status 200
  "OK"
end

# ---- 返す文章を決める処理（場合分け） ----

# 届いた文章(text)を受け取って、「返す文章」を返す関数です。
def build_reply(text)
  # strip は、前後の余分な空白や改行を取り除いてくれます。
  # 「 おみくじ 」のように空白が入っていても反応できるようにします。
  message = text.strip

  # if 〜 else 〜 end で「場合分け」をします。
  if message == "おみくじ"
    # 「おみくじ」だったら、下で作った omikuji を呼び出します。
    omikuji
  else
    # それ以外は step2 と同じく、届いた文章をそのまま返します。
    text
  end
end

# ---- おみくじの処理 ----

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
