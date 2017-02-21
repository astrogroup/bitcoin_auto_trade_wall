
require './config'
require './market'
require './trade_support'
require 'benchmark'
require 'parallel'
require 'yaml'
require 'colorize'
require './state'

Config.load

WALL_HEIGHT_BTC = 2 # 単位:BTC これ以上の注文があるとき、壁とみなす
BUY_AMOUNT_BTC= 0.001 # 単位:BTC 壁を発見したときの注文サイズ
BUY_MARGIN_JPY = 2 # 単位:円 壁の上、いくらプラスして買い注文を出すか
SELL_MARGIN_JPY = 20 #単位: 円 購入した後、購入価格にこのマージンを乗せて売る
LOOK_RANGE = 10 #単位: 板の行数。bitflyerの買い板(Bid)の中から、この数だけ見る。通常ブラウザで６個ぐらい見えてるやつ


market = Bitflyer.new
state = STATE_WAIT_WALL.new
wall = nil
buying_order = {}
selling_order = {}
complete_buy_list = []
partially_buy_list = []
complete_sell_list = []


begin
  loop do
    begin
      p "---------------------------------"
      p "State     : #{state.class.name}"
      TradeSupport.refresh_balance(market)

      market.update_board
      wall = TradeSupport.search_wall(market, WALL_HEIGHT_BTC)
      if !wall.nil?
        p "Wall found: #{wall[:rate]}, #{wall[:amount]}"
      else
        p "Wall not found"
      end
      state = state.action(market, wall, buying_order, selling_order, complete_buy_list, complete_sell_list, partially_buy_list)

    rescue => e
      p e.message
      sleep(30)
    end

  end

ensure
  TradeSupport.print_summary(complete_buy_list, complete_sell_list, partially_buy_list)
end


