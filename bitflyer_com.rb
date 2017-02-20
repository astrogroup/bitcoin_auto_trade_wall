
class BitflyerCOM
  require 'net/http'
  require 'uri'
  require 'openssl'
  require 'pry'
  require 'JSON'


  def initialize
    @nonce = Time.now.to_i.to_s
  end

  def get_balance
    uri_base = "https://api.bitflyer.jp"
    uri = URI.parse(uri_base + "/v1/me/getbalance")

    header = create_header(uri.path.to_s, "GET")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    response = https.start {
      https.get(uri.request_uri, header)
    }
    res = JSON.parse(response.body)

    {jpy: search_amount(res, "JPY").to_i, btc: search_amount(res, "BTC").to_f}
  rescue => e
    p e.message
    nil
  end

  def get_board
    uri_base = "https://api.bitflyer.jp"
    uri = URI.parse(uri_base + "/v1/board/")


    header = create_header(uri, "GET")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    response = https.start {
      https.get(uri.request_uri, header)
    }

    order_books = JSON.parse(response.body)

    #board = {
    #  lowest_sell: {rate: order_books["asks"][0]["price"].to_i, amount: order_books["asks"][0]["size"].to_f},
    #  highest_buy: {rate: order_books["bids"][0]["price"].to_i, amount: order_books["bids"][0]["size"].to_f}
    #}
  rescue => e # if there are errors, return nil
    p e.message
    nil
  end

  def create_order(order_type, rate, amount)

    uri_base = "https://api.bitflyer.jp"
    uri = URI.parse(uri_base + "/v1/me/sendchildorder")

    body_json = {
      product_code: "BTC_JPY",
      child_order_type: "LIMIT",
      side: convert_order_type(order_type),
      price: rate,
      size: amount,
      #minute_to_expire: 50000,
      time_in_force: "GTC"
    }.to_json

    header = create_header(uri.path, "POST", body_json)

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path, initheader = header)
    req.body = body_json

    response = https.request(req)

    order_id = JSON.parse(response.body)["child_order_acceptance_id"]

  end

  def get_child_orders
    uri_base = "https://api.bitflyer.jp"
    path = "/v1/me/getchildorders"
    query = "?product_code=BTC_JPY&child_order_state=ACTIVE"
    uri = URI.parse(uri_base + path + query)

    header = create_header(path + query, "GET")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    response = https.start {
      https.get(uri.request_uri, header)
    }
    res = JSON.parse(response.body)

  rescue => e
    p e.message
    {} # empty hash
  end


  def cancel_order(order_id)
    uri_base = "https://api.bitflyer.jp"
    uri = URI.parse(uri_base + "/v1/me/cancelchildorder")

    body_json = {
      product_code: "BTC_JPY",
      child_order_acceptance_id: order_id.to_s
    }.to_json

    header = create_header(uri.path, "POST", body_json)

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path, initheader = header)
    req.body = body_json

    response = https.request(req)

    response.code == "200"
  rescue => e
    p e.message
    nil
  end


  def cancel!

    uri_base = "https://api.bitflyer.jp"
    uri = URI.parse(uri_base + "/v1/me/cancelallchildorders")

    body_json = {
      product_code: "BTC_JPY",
    }.to_json

    header = create_header(uri.path, "POST", body_json)

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Post.new(uri.path, initheader = header)
    req.body = body_json

    response = https.request(req)

    response.code == "200"
  rescue => e
    p e.message
    nil
  end

  def order_empty?
    result = get_opens

    result.each do |order|
      return false if order["child_order_state"] == "ACTIVE"
    end
    true
  rescue => e
    p e.message
    nil
  end

  private
  def create_nonce
    nonce_try = Time.now.to_i.to_s

    while(@nonce == nonce_try)
      sleep(1)
      nonce_try = Time.now.to_i.to_s
    end

    @nonce = nonce_try
  end

  def create_header(path, method, body = "")
    key = $config[:Bitflyer][:key]
    secret = $config[:Bitflyer][:secret]
    nonce = create_nonce
    message = nonce + method.to_s + path.to_s +  body
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, message)
    header = {
      "ACCESS-KEY" => key,
      "ACCESS-TIMESTAMP" => nonce,
      "ACCESS-SIGN" => signature,
      "Content-Type" => 'application/json',
    }
  end

  def search_amount(ary, currency)
    amount = nil
    ary.each do |a|
      if a["currency_code"] == currency.to_s
        amount = a["amount"]
        break
      end
    end

    amount
  end

  def convert_order_type(order_type)
    return "BUY" if order_type == "buy"
    return "SELL" if order_type == "sell"
    raise
  end

  def get_opens
    uri_base = "https://api.bitflyer.jp"
    path = "/v1/me/getchildorders"
    query = "?product_code=BTC_JPY"
    uri = URI.parse(uri_base + path + query)

    header = create_header(path + query, "GET")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    response = https.start {
      https.get(uri.request_uri, header)
    }
    res = JSON.parse(response.body)

  rescue => e
    p e.message
    {} # empty hash
  end

end

