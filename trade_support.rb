module TradeSupport
  require 'colorize'
  require 'pry'

  class << self

    def buy(market, rate, amount)
      id = market.create_order("buy", rate, amount)
    end

    def sell(market, rate, amount)
      id = market.create_order("sell", rate, amount)
    end

    def refresh_balance(market)
      market.update_balance
      balance = market.get_balance
      p "Balance   : JPY:#{sprintf("%7d", balance.jpy)} BTC:#{sprintf("%3.5f", balance.btc)}"
    end

    def search_wall(market, min_wall_height)
      market.get_board["bids"].each do |x|
        if x["size"].to_f > min_wall_height
          return {rate: x["price"], amount: x["size"]}
        end
      end

      nil

    end

    def print_summary(complete_buy_list, complete_sell_list, partially_buy_list)
      p "                   "
      p "-------------------"
      p "   Trade Summary   "
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

      p "-------------------"
      p "       end         "
      p "-------------------"
    end

  end

end



