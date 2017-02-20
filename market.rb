
require './bitflyer_com'

class Balance
  attr_accessor :jpy, :btc

  def initialize(attributes = nil)
    attributes.each do |k, v|
      send("#{k.to_s}=", v) if respond_to?("#{k.to_s}=")
    end if attributes
    yield self if block_given?
  end

end

class Market

  def cancel!
    @com.cancel!
  end

  def create_order(order_type, rate, amount)
    @com.create_order(order_type, rate, amount)
  end

  def get_board
    @board
  end

  def update_board
    @board = @com.get_board
  end

  def get_balance
    @balance
  end

  def update_balance
    balance = @com.get_balance
    @balance =  balance.nil? ? nil : Balance.new(balance)
  end

  def order_valid?(order_id)
    valid_orders = @com.get_child_orders
    valid_orders.each do |x|
      return true if x["child_order_acceptance_id"] == order_id
    end
    false
  end

  def cancel_order(order_id)
    @com.cancel_order(order_id)
  end

  def name
    @name
  end

end

class Bitflyer < Market

  def initialize
    @com = BitflyerCOM.new
    @name = "bitflyer   "
  end

end


