# =====================================================================
# 【step2・穴埋め版】LINE と「送受信」するプログラムです。
#
# step1 は送るだけでしたが、step2 では相手から届いたメッセージを
# 受け取り、同じ内容をそのまま返す「オウム返し」をします。
#
# ★このファイルは未完成です★
#   ______ となっている所を Ruby のコードで埋めると動きます。
#   TODO は全部で 6 個あります。上から順番に埋めていきましょう。
#   穴はすべて post "/callback" の中にあります。
#
# このステップで練習する Ruby の基礎:
#   TODO(1) Hash から値を取り出す ＋ each でくり返す
#   TODO(2) 取り出した値を == でくらべる（next unless で読み飛ばす）
#   TODO(3) Hash の中の Hash から値を取り出す
#   TODO(4) 取り出した値を変数に入れる
#   TODO(5) 同じく、変数に入れる
#   TODO(6) 自分で作った関数を、引数をわたして呼び出す
#
# しくみ:
#   1. LINE に誰かがメッセージを送る
#   2. LINE がこのプログラム(Webサーバー)に「届いたよ」と連絡する(Webhook)
#   3. このプログラムが内容を読み取り、返信(reply)する
#
# 実行方法（ターミナルで）:
#   cd draft/step2
#   ruby app.rb
#   （すでに別の step のフォルダにいる場合は、先に cd ../../ でルートに戻ってください）
#   → その後、Codespaces で公開されたURLを LINE の Webhook に登録します
#     （くわしくは draft/step2/README.md を参照）
#
# 答えを見たいときは ../../complete/step2/app.rb を開いてください。
# =====================================================================

# ---- 使う道具（ライブラリ）を読み込みます ----
# ここは完成済みです。書き換えなくて大丈夫です。

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
# dotenv は、.env ファイルを読み込んで ENV に入れてくれます。
# リポジトリルートの .env を直接指定して読み込みます。
require "dotenv"
Dotenv.load(File.expand_path("../../.env", __dir__))

# ---- 秘密の設定を環境変数から取り出します ----
# ここも完成済みです。

# メッセージを送る（返信する）ための鍵です。
CHANNEL_ACCESS_TOKEN = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
# 届いた連絡が本物か確認するための、もう1つの鍵(シークレット)です。
CHANNEL_SECRET = ENV["LINE_CHANNEL_SECRET"]

# ---- サーバーの待ち受け設定 ----
# ここも完成済みです。おまじないだと思って先に進みましょう。

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
  "LINE 送受信Bot は動いています（step2）"
end

# ---- LINE からの連絡(Webhook)を受け取る入り口 ----
# ★ここから下が、あなたが埋める部分です★

# LINE は「/callback」という住所に POST で連絡してきます。
post "/callback" do
  # 届いた本文（まだ文字のかたまり）を読み取ります。
  body = request.body.read

  # まず、この連絡が本当に LINE からのものかを確認します。
  # にせものを受け付けないための、大切なセキュリティ確認です。
  # （valid_signature? の中身は完成済みです。下の方にあります）
  unless valid_signature?(body, request.env["HTTP_X_LINE_SIGNATURE"])
    halt 400, "署名が正しくありません"
  end

  # 文字のかたまり(JSON)を、Ruby が扱いやすい形に変換します。
  # これで data は Hash（キーと値の組）になります。
  data = JSON.parse(body)

  # --------------------------------------------------------------------
  # TODO(1) 届いた「出来事」を1つずつ順番に処理します。
  #
  #   data の中身は、こんな形の Hash です。
  #     {
  #       "destination" => "Uxxxx",
  #       "events" => [ {1つ目の出来事}, {2つ目の出来事} ]
  #     }
  #
  #   1回の連絡に複数の出来事が入っていることがあるので、
  #   "events" の配列を取り出して、each で1つずつ処理します。
  #
  #   ヒント:
  #     ・Hash から値を取り出す → data["キー名"]
  #     ・取り出したいキー名は "events" です
  # --------------------------------------------------------------------
  data[______].each do |event|
    # ------------------------------------------------------------------
    # TODO(2) メッセージ以外の出来事(友だち追加など)は今回は無視します。
    #
    #   event["type"] には、出来事の種類が文字で入っています。
    #     ・メッセージが届いた   → "message"
    #     ・友だち追加された     → "follow"
    #
    #   next unless 〇〇 は「〇〇でなければ、次のくり返しへ飛ばす」
    #   という書き方です。つまり「〇〇のときだけ先に進む」となります。
    #
    #   ヒント: event["type"] が "message" と同じかを == でくらべます
    # ------------------------------------------------------------------
    next unless ______

    # ------------------------------------------------------------------
    # TODO(3) テキスト以外(画像やスタンプ)も今回は無視します。
    #
    #   event の中の "message" は、さらに Hash になっています。
    #     event = {
    #       "type" => "message",
    #       "replyToken" => "abcd1234",
    #       "message" => { "type" => "text", "text" => "こんにちは" }
    #     }
    #
    #   Hash の中の Hash は [ ] を2回つなげて取り出せます。
    #     event["message"]["type"]  ← メッセージの種類が入っています
    #
    #   これが "text" のときだけ先に進むようにしてください。
    #   （画像やスタンプにも反応させるのは step4 でやります）
    # ------------------------------------------------------------------
    next unless ______

    # ------------------------------------------------------------------
    # TODO(4) 相手が送ってきた文章を取り出して、変数に入れてください。
    #
    #   ヒント: TODO(3) と同じ形で、"type" のかわりに "text" を使います
    # ------------------------------------------------------------------
    received_text = ______

    # ------------------------------------------------------------------
    # TODO(5) 返信に必要な「返信用チケット(replyToken)」を
    #         取り出して、変数に入れてください。
    #
    #   replyToken は message の中ではなく、event の直下にあります。
    #   TODO(3) の例をもう一度見てみましょう。
    #
    #   ヒント: [ ] は1回だけで取り出せます
    # ------------------------------------------------------------------
    reply_token = ______

    # ------------------------------------------------------------------
    # TODO(6) 受け取った文章をそのまま返信します（オウム返し）。
    #
    #   このファイルの下の方に、返信用の関数が用意してあります。
    #     def reply_message(reply_token, text)
    #
    #   この関数を呼び出してください。( ) の中には、上で作った
    #   2つの変数を「,」で区切って、定義と同じ順番でわたします。
    #
    #   ヒント: 関数名(1つ目の変数, 2つ目の変数) という形で書きます
    # ------------------------------------------------------------------
    ______
  end

  # LINE には「ちゃんと受け取ったよ」という合図(200)を返します。
  status 200
  "OK"
end

# ---- 届いた連絡が本物かを確認する処理 ----
# ここは完成済みです。中身がむずかしいので、今は読まなくて大丈夫です。

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
# ここも完成済みです。TODO(6) から呼び出してください。

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
