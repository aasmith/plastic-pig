$: << "lib"
require 'plastic_pig'

RSI_URL = "http://chartapi.finance.yahoo.com/instrument/1.0/%s/chartdata;type=rsi;range=%s/json?period=14"
PRICE_URL = "http://chartapi.finance.yahoo.com/instrument/1.0/%s/chartdata;type=quote;range=%s/json/"

def help
  puts File.read("README")
  abort
end

help if ARGV.any?{|e|e =~ /^-h$/ }
symbol = ARGV[0] or raise "need symbol"

args = ARGV.join(" ")
max_date = args.select{ |e| e =~ /-m (\d+)/}   && $1
range    = args.select{ |e| e =~ /-r (\d+\w)/} && $1 || "1y"

price_series = PlasticPig::YahooFetcher.new(PRICE_URL % [symbol, range]).fetch
rsi_series = PlasticPig::YahooFetcher.new(RSI_URL % [symbol, range]).fetch

series = []

# Load data where data occurs only in both series for a given date.
price_series.each do |price|
  rsi = rsi_series.detect { |rsi| price["Date"] == rsi["Date"] }

  series << price.merge(rsi) if rsi
end

series.reject!{|s| s["Date"] > max_date.to_i } if max_date

head = PlasticPig::Structures::DayFactory.build_list(series)

strategies = []
strategies << PlasticPig::Strategies::RsiClassic.new(:rsi_70)
strategies << PlasticPig::Strategies::RsiAgita.new

bt = PlasticPig::BackTester.new(head, strategies)
entries = bt.run

entries.each { |e| puts "-"*80, e.summary, "" }

puts "="*80
puts "Used data ranging from #{head.date} to #{head.last.date}"

exits = entries.select { |e| e.exit }
puts "Found #{entries.size} entries, with #{exits.size} exits."

# Unique exits are important because it demonstrates how 
# often a strategy is likely to work. If a strategy returns a 
# high number of entries, but a low number of unique exits, then
# it may be a sign that the exit condition may have be fluke, and 
# is unlikely to be reproducable.
uniqs = exits.map{|e|e.exit.day if e.exit}.compact.uniq
puts "There were #{uniqs.size} (#{(uniqs.size / exits.size.to_f * 100).places(2)}%) unique exit dates."

__END__
interesting: 
C     most active
EEM   6 most active, ishares emerging
EDC   3x emerging
QQQQ  nasdaq
QLD   2x nasdaq
TQQQ  3x nasdaq
TNA   3x russ 2000
F

