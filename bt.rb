require 'linked_list'

require 'pp'
require 'open-uri'
require 'rubygems'
require 'json'

module PlasticPig
  RSI_URL = "http://chartapi.finance.yahoo.com/instrument/1.0/%s/chartdata;type=rsi;range=1y/json?period=14"
  PRICE_URL = "http://chartapi.finance.yahoo.com/instrument/1.0/%s/chartdata;type=quote;range=1y/json/"

  class YahooFetcher
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def fetch
      read_json(url)
    end

    def read_json(url)
      JSON.parse(fix_json(open(url).read))['series']
    end

    def fix_json(str)
      str.
        # remove the javascript callback around the json.
        gsub(/.*\( (.*)\)/m, '\1').chomp.

        # Yahoo!'s json has an extra (invalid) comma before the closing bracket in the meta entry.
        gsub(/,\s*\n\s*\}/m, "}")
    end
  end

  class DayFactory
    class << self
      def build_list(hashes)
        head, days = nil

        hashes.each do |h| 
          day = build(h)

          # build list by linking days
          head = day unless head
          days << day if days
          days = day
        end

        head
      end

      def build(hash)
        d = Day.new
        d.date = hash["Date"]

        %w(open high low close volume rsi).each do |a|
          d.send(:"#{a}=", hash[a])
        end

        d
      end
    end
  end

  class Day
    include LinkedList

    VARS = [:date, :open, :high, :low, :close, :volume, :rsi]
    attr_accessor *VARS

    def parsed_date
      @parsed_date ||= Date.parse(date.to_s)
    end

    def inspect
      pairs = VARS.map{|v| "#{v}=#{send(v.to_sym).inspect}" }

      "<Day: #{pairs.join(",")}>"
    end
  end

  class Entry
    attr_accessor :day, :reason, :exits

    def initialize
      @exits = []
    end

    def price
      day.open
    end

    def summary
      summaries = []

      summaries << "Entered at start of day #{day.date} @ $#{day.open}"
      summaries << "Reason: #{reason}"
      summaries << "Entry generated #{exits.size} exits:"
      exits.each { |x| summaries << x.summary }

      summaries.join("\n")
    end
  end

  class Exit
    attr_accessor :day, :reason, :entry

    def price
      day.close
    end

    def profit
      price - entry.price
    end

    def summary
      <<-SUMMARY
        Exit at end of day #{day.date} @ $#{day.close};
         Reason: #{reason}
         Profit: $#{profit}
      SUMMARY
    end
  end
end

symbol = ARGV[0] or raise "need symbol"

price_series = PlasticPig::YahooFetcher.new(PlasticPig::PRICE_URL % symbol).fetch
rsi_series = PlasticPig::YahooFetcher.new(PlasticPig::RSI_URL % symbol).fetch

prices_and_rsi = price_series.zip(rsi_series).map do |price, rsi|
  unless price["Date"] == rsi["Date"]
    raise "Loading error, series do not align on dates."
  end

  price.merge(rsi)
end

head = PlasticPig::DayFactory.build_list(prices_and_rsi)

#head.each { |d| puts d.inspect }

entries = []

head.each do |day|
  if day.previous
    if day.previous.rsi < 55 and day.rsi > 55
      entry = PlasticPig::Entry.new
      entry.reason = "RSI crossed 55 from #{day.previous.rsi} to #{day.rsi} on #{day.date}"
      entry.day = day.next

      entries << entry
    end
  end
end

entries.each do |entry|
  low_rsi, high_rsi = false

  entry.day.each_with_index do |day,i|
    
    # pick off the 3rd, 5th and 10th days
    if [2,4,9].include?(i)
      x = PlasticPig::Exit.new
      x.day = day
      x.reason = "Expired after #{i+1} days"
      x.entry = entry

      entry.exits << x
    end

    # find days when the rsi moved > 70 or < 40.
    if day.rsi < 40 && !low_rsi
      x = PlasticPig::Exit.new
      x.day = day
      x.reason = "RSI dropped to below 40"
      x.entry = entry

      entry.exits << x
      low_rsi = true

    elsif day.rsi > 70 && !high_rsi
      x = PlasticPig::Exit.new
      x.day = day
      x.reason = "RSI rose above 70"
      x.entry = entry

      entry.exits << x
      high_rsi = true
    end

    break if i >= 9 && high_rsi && low_rsi
  end
end

entries.each { |e| puts "="*80, e.summary, "" }

__END__
interesting: 
C     most active
EEM   6 most active, ishares emerging
EDC   3x emerging
QQQQ  nasdaq
TNA   3x russ 2000
F

