
require './config'
require './market'
require './trade_support'
require 'benchmark'
require 'parallel'
require 'yaml'


Config.load


WALL_HEIGHT_BTC = 2 # 単位:BTC これ以上の注文があるとき、壁とみなす
BUY_AMOUNT_BTC= 0.01 # 単位:BTC 壁を発見したときの注文サイズ
BUY_MARGIN_JPY = -501 # 単位:円 壁の上、いくらプラスして買い注文を出すか
SELL_MARGIN_JPY = 1020 #単位: 円 購入した後、購入価格にこのマージンを乗せて売る
LOOK_RANGE = 5 #単位: 板の行数。bitflyerの買い板(Bid)の中から、この数だけ見る。通常ブラウザで６個ぐらい見えてるやつ


# state
#%w(WaitWall WaitBuying WaitSelling).each do |state_class|
#  class state_class
#  end
#end

WAIT_WALL = 1
WAIT_BUYING = 2
WAIT_SELLING = 3


market = Bitflyer.new
state = WAIT_WALL
wall = nil
buying_order = nil
selling_order = nil
complete_buy_list = []
partially_buy_list = []
complete_sell_list = []

begin
  loop do
    begin
      p "current state: #{state}"
      TradeSupport.refresh_balance(market)

      market.update_board
      wall = TradeSupport.search_wall(market, WALL_HEIGHT_BTC)

      case state
      when WAIT_WALL
        next if wall.nil?

        p "wall found: #{wall[:rate]}, #{wall[:amount]}"
        buying_rate = wall[:rate] + BUY_MARGIN_JPY
        buying_order_id = TradeSupport.buy(market, buying_rate, BUY_AMOUNT_BTC)
        buying_order = {id: buying_order_id, rate: buying_rate, amount: BUY_AMOUNT_BTC}
        state = WAIT_BUYING
        p "buying: #{buying_order}"
        p "state changed to WAIT_BUYING"
        next

      when WAIT_BUYING
        if wall.nil? || rand(3) == 1
          p "Wall disappers when buying. The remaining buying order will be canceled."
          market.cancel_order(buying_order[:id])
          partially_buy_list.push(buying_order.dup)
          buying_order = nil
          state = WAIT_WALL
          p "state changed to WAIT_WALL"
          next
        end

        if market.order_valid?(buying_order[:id])
          next
        end

        # wall exist, order finished
        complete_buy_list.push(buying_order)
        selling_order_rate = buying_order[:rate] + SELL_MARGIN_JPY
        selling_order_id = TradeSupport.sell(market, selling_order_rate, BUY_AMOUNT_BTC)
        selling_order = {id: selling_order_id, rate: selling_order_rate, amount: BUY_AMOUNT_BTC}
        state = WAIT_SELLING
        p "selling: #{selling_order}"
        p "state changed to WAIT_SELLING"
        next

      when WAIT_SELLING
        if wall.nil? || rand(3) == 1
          p "Wall disappers when selling. the sell order will remain"
          selling_order = nil # leave the order and forget it.
          state = WAIT_WALL
          p "state changed to WAIT_WALL"
          next
        end

        if market.order_valid?(selling_order[:id])
          next
        end

        # wall exist, order finished
        complete_sell_list.push(selling_order)
        selling_order = nil
        state = WAIT_WALL
        p "state changed to WAIT_WALL"
        next
      end

    rescue => e
      p e.message
      sleep(30)
    end

  end

ensure

  p "-------------------"
  p "completed buy list:"
  sum = 0
  complete_buy_list.each do |x|
    rate = x[:rate].to_i
    amount = x[:amount].to_f
    p "#{rate} #{amount}"
    sum += rate * amount
  end
  p "buy sum jpy = #{sum}"

  p "-------------------"
  p "completed sell list:"
  sum = 0
  complete_sell_list.each do |x|
    rate = x[:rate].to_i
    amount = x[:amount].to_f
    p "#{rate} #{amount}"
    sum += rate * amount
  end
  p "sell sum jpy = #{sum}"

  p "-------------------"
  p "partially done list:"
  partially_buy_list.each do |x|
    p x
  end

end


