# =====================================================================
# 【step1】LINE の友だち「全員」に、一方的にメッセージを送るだけの
# プログラムです。（broadcast = 一斉配信 という仕組みを使います）
#
# このステップでは「送るだけ」を学びます。
# 相手からのメッセージを受け取ることはしません。
#
# 実行方法（ターミナルで）:
#   cd step1
#   ruby send_message.rb
#   （すでに別の step のフォルダにいる場合は、先に cd ../../ でルートに戻ってください）
#
# 送るメッセージを変えたいときは、一番下の send_message("...") の
# 文章を書き換えてください。
#
# ★注意★
#   これは「友だち全員」に届きます。テストのつもりでも実際に全員に
#   送られてしまうので、本文の内容には十分に気をつけてください。
# =====================================================================

# ---- 使う道具（ライブラリ）を読み込みます ----

# require は「この道具を使います」という宣言です。

# net/http は、インターネットにデータを送るための標準の道具です。
require "net/http"
# uri は、送り先のURLを扱うための道具です。
require "uri"
# json は、データを LINE が理解できる形（JSON）に変換する道具です。
require "json"
# dotenv は、.env ファイルを読み込んで ENV に入れてくれます。
# リポジトリルートの .env を直接指定して読み込みます。
require "dotenv"
Dotenv.load(File.expand_path("../../.env", __dir__))

# ---- 秘密の設定を環境変数から取り出します ----

# ENV["キー名"] で、.env に書いた値を取り出せます。
# （直接コードに書かないことで、鍵の流出を防ぎます）
# 全員に送る broadcast では「送り先ID」は不要なので、鍵だけを使います。
CHANNEL_ACCESS_TOKEN = ENV["LINE_CHANNEL_ACCESS_TOKEN"]

# ---- メッセージを送る処理を「関数」としてまとめます ----

# def から end までが1つの関数（処理のまとまり）です。
# ここでは text（送りたい文章）を受け取って LINE に送ります。
def send_message(text)
  # 設定が空のままだと送れないので、先にチェックして教えてあげます。
  if CHANNEL_ACCESS_TOKEN.nil? || CHANNEL_ACCESS_TOKEN.empty?
    puts "エラー: LINE_CHANNEL_ACCESS_TOKEN が設定されていません。.env を確認してください。"
    return # ここで処理を中断します
  end

  # 送信先のURL（LINE の「全員に一斉送信する」窓口）です。
  # push（1人に送る）ではなく broadcast（全員に送る）を使います。
  uri = URI.parse("https://api.line.me/v2/bot/message/broadcast")

  # HTTP の POST リクエスト（データを送る依頼書）を作ります。
  request = Net::HTTP::Post.new(uri)

  # ヘッダー（依頼書の付箋）に、送信形式と鍵をセットします。
  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{CHANNEL_ACCESS_TOKEN}"

  # 送る中身（本文）を用意します。
  # broadcast は全員が対象なので「誰に(to)」の指定はいりません。
  # messages（何を送るか）だけを LINE の決まった形で書きます。
  request.body = {
    messages: [
      { type: "text", text: text }
    ]
  }.to_json # Ruby のデータを JSON という文字の形に変換します。

  # 実際にインターネット越しに送信します（https なので use_ssl: true）。
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  # 結果を画面に表示します。
  # code が "200" なら成功です。それ以外は何か問題があります。
  if response.code == "200"
    puts "送信に成功しました！ メッセージ: #{text}"
  else
    puts "送信に失敗しました。ステータス: #{response.code}"
    puts "詳細: #{response.body}"
  end
end

# ---- ここが実際に動き出す部分です ----

# send_message の ( ) の中の文章が、友だち全員に届きます。
# 好きな文章に書き換えて試してみてください。
send_message("こんにちは！これはテスト送信です。")
