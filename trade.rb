
require './config'
require './market'
require './trade_support'
require 'benchmark'
require 'parallel'
require 'yaml'
require 'colorize'

Config.load

WALL_HEIGHT_BTC = 2 # 単位:BTC これ以上の注文があるとき、壁とみなす
BUY_AMOUNT_BTC= 0.001 # 単位:BTC 壁を発見したときの注文サイズ
BUY_MARGIN_JPY = 2 # 単位:円 壁の上、いくらプラスして買い注文を出すか
SELL_MARGIN_JPY = 20 #単位: 円 購入した後、購入価格にこのマージンを乗せて売る
LOOK_RANGE = 10 #単位: 板の行数。bitflyerの買い板(Bid)の中から、この数だけ見る。通常ブラウザで６個ぐらい見えてるやつ


class STATE_WAIT_WALL
  def action(market, wall, buying_order, selling_order, complete_buy_list, complete_sell_list, partially_buy_list)
    return self if wall.nil?
    buying_rate = wall[:rate] + BUY_MARGIN_JPY
    buying_order_id = TradeSupport.buy(market, buying_rate, BUY_AMOUNT_BTC)
    buying_order.merge!({id: buying_order_id, rate: buying_rate, amount: BUY_AMOUNT_BTC})
    state = STATE_WAIT_BUYING.new
    p "buying: #{buying_order}"
    p "state changed to WAIT_BUYING"
    state
  end
end

class STATE_WAIT_BUYING
  def action(market, wall, buying_order, selling_order, complete_buy_list, complete_sell_list, partially_buy_list)
    if wall.nil?
      p "Wall disappers when buying. The remaining buying order will be canceled."
      market.cancel_order(buying_order[:id])
      partially_buy_list.push(buying_order.dup)
      buying_order.clear
      state = STATE_WAIT_WALL.new
      p "state changed to WAIT_WALL"
      return state
    end

    if market.order_valid?(buying_order[:id])
      return self
    end

    # wall exist, order finished
    complete_buy_list.push(buying_order.dup)
    selling_order_rate = buying_order[:rate] + SELL_MARGIN_JPY
    selling_order_id = TradeSupport.sell(market, selling_order_rate, BUY_AMOUNT_BTC)
    selling_order.merge!({id: selling_order_id, rate: selling_order_rate, amount: BUY_AMOUNT_BTC})
    buying_order.clear
    state = STATE_WAIT_SELLING.new
    p "selling: #{selling_order}"
    p "state changed to WAIT_SELLING"
    state
  end
end

class STATE_WAIT_SELLING
  def action(market, wall, buying_order, selling_order, complete_buy_list, complete_sell_list, partially_buy_list)
    if wall.nil?
      p "Wall disappers when selling. the sell order will remain"
      selling_order.clear # leave the order and forget it.
      state = STATE_WAIT_WALL.new
      p "state changed to WAIT_WALL"
      return state
    end

    if market.order_valid?(selling_order[:id])
      return self
    end

    # wall exist, order finished
    complete_sell_list.push(selling_order.dup)
    selling_order.clear
    state = STATE_WAIT_WALL.new
    p "state changed to WAIT_WALL"
    state
  end

end

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


