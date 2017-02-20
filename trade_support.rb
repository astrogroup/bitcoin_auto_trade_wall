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
      p "#{market.name} JPY:#{sprintf("%7d", balance.jpy)} BTC:#{sprintf("%3.5f", balance.btc)}"
    end

    def search_wall(market, min_wall_height)
      market.get_board["bids"].each do |x|
        if x["size"].to_f > min_wall_height
          return {rate: x["price"], amount: x["size"]}
        end
      end

      nil

    end

  end

end



