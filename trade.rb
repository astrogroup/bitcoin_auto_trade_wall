
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
BUY_AMOUNT_BTC= 0.01 # 単位:BTC 壁を発見したときの注文サイズ
BUY_MARGIN_JPY = 5# 単位:円 壁の上、いくらプラスして買い注文を出すか
SELL_MARGIN_JPY = 40 #単位: 円 購入した後、購入価格にこのマージンを乗せて売る
LOOK_RANGE = 10 #単位: 板の行数。bitflyerの買い板(Bid)の中から、この数だけ見る。通常ブラウザで６個ぐらい見えてるやつ

class Wall
  attr_accessor :current_walls, :previous_wall
  def initialize
    @current_walls = []
    @previous_wall = nil
  end

  def update_walls(market, min_wall_height)
    @current_walls = []
    market.get_board["bids"].each_with_index do |x, idx|
      if x["size"].to_f > min_wall_height
        @current_walls.push({rate: x["price"], amount: x["size"]})
      end
      break if idx > LOOK_RANGE
    end
  end

  def previous_wall_exist?
    return false if @previous_wall.nil?

    search_result = @current_walls.find{|x| x[:rate] == @previous_wall[:rate]}
    #p @current_walls
    #p @previous_wall
    #p search_result
    if search_result.nil?
      false
    else
      true
    end
  end

  def clear
    @current_walls = []
    @previous_wall = nil
  end

end

market = Bitflyer.new
state = STATE_WAIT_WALL.new
wall = Wall.new
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
      wall.update_walls(market, WALL_HEIGHT_BTC)
      state = state.action(market, wall, buying_order, selling_order, complete_buy_list, complete_sell_list, partially_buy_list)

    rescue => e
      p e.message
      sleep(30)
    end

  end

ensure
  TradeSupport.print_summary(complete_buy_list, complete_sell_list, partially_buy_list)
end


