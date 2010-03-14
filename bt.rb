$: << "lib"
require 'plastic_pig'

BASE_URL = "http://chartapi.finance.yahoo.com/instrument/1.0/%s/chartdata;"

DATA_QUERIES = [
  "type=quote;range=%s/json/",                               # price-data
  "type=macd;range=%s/json?period1=26&period2=12&signal=9",  # divergence = macd - signal, 
                                                             #       macd = MACD(26,12), 
                                                             #     signal = MACD(9)
  "type=rsi;range=%s/json?period=14",                        # rsi    = RSI(14)
  "type=sma;range=%s/json?period=200",                       # sma    = SMA(200)
  "type=stochasticslow;range=%s/json?period=15&dperiod=5",   # signal = %D(5), stochastic = %K(15)
]

URLS = DATA_QUERIES.map{|d| BASE_URL + d }

def help
  puts File.read("README")
  abort
end

help if ARGV.any?{|e|e =~ /^-h$/ }
symbol = ARGV[0] or raise "need symbol"

args = ARGV.join(" ")
max_date = args.select{ |e| e =~ /-m (\d+)/}   && $1
range    = args.select{ |e| e =~ /-r (\d+\w)/} && $1 || "1y"

puts "Fetching ..."

raw_series = URLS.map do |url|
  series = PlasticPig::YahooFetcher.new(url % [symbol, range]).fetch
  type = url.scan(/type=(\w+);/).to_s

  unless type == "quote"
    series.each do |row|
      (row.keys - ["Date", type]).each do |key|
        row["#{type}_#{key}"] = row.delete(key)
      end
    end
  end

  series
end

puts "Normalizing ..."

series = []

# Iterate though one data set, adding data when all series have data for that date.
raw_series.first.each do |row|
  date = row["Date"]

  # Slow.
  all_data_for_date = raw_series.map{|rs| rs.detect{|r| r["Date"] == date } }

  # skip if not all data available for date
  unless all_data_for_date.compact.size == raw_series.size
    puts "skipping incomplete date #{date}"
    next
  end

  # merge array of hashes into one hash
  all_data_for_date = all_data_for_date.inject({}) { |h,e| h.merge(e) }

  series << all_data_for_date
end

series.reject!{|s| s["Date"] > max_date.to_i } if max_date

head = PlasticPig::Structures::DayFactory.build_list(series)

strategies = []
strategies << PlasticPig::Strategies::RsiClassic.new(:rsi_70)
strategies << PlasticPig::Strategies::RsiAgita.new

puts "Backtesting ..."

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

