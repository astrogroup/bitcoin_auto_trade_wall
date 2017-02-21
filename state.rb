
require './market'
require './trade_support'

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

