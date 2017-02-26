# bitcoin_auto_trade_wall
auto trade by wall watching algorithm by Mr. L

If you use Mac

Install ruby versioned on Gemfile (maybe 2.2.1)

$gem install bundler

$git clone [this repository]

$bundle   #=> install dependancy

$cp password_example.yml password.yml

Replace the API key with yours (You can get API keys from Bitflyer)

Edit the parameter on trade.rb
 WALL_HEIGHT_BTC
 BUY_AMOUNT_BTC ...

$bundle exec ruby trade.rb # => Be careful. Real trade starts.
Ctrl + c will stop the proram.

Enjoy trades.
