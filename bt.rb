require 'linked_list'

require 'pp'
require 'open-uri'
require 'rubygems'
require 'json'

class ::Range
  def crossed_below?(n)
    first > n and last < n
  end

  def crossed_above?(n)
    first < n and last > n
  end
end

class Float
  def places(n=2)
    n = 10 ** n.to_f
    (self * n).truncate / n
  end
end

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
    attr_accessor :day, :reason, :exit, :strategy

    def price
      day.open
    end

    def summary
      summaries = []

      summaries << "Entered at start of day #{day.date} @ $#{day.open}"
      summaries << "Reason: #{reason}"
      summaries << "Strategy: #{strategy.respond_to?(:name) ? strategy.name : strategy.class.name}"

      if exit
        summaries << "Exit Summary:"
        summaries << exit.summary
      else
        summaries << "No exit was generated."
      end

      summaries.join("\n")
    end
  end

  class Exit
    attr_accessor :day, :reason, :entry, :strategy

    def price
      day.close
    end

    def profit
      price - entry.price
    end

    def profit_percent
      profit.to_f / entry.price
    end

    def summary
      <<-SUMMARY
        Exit at end of day #{day.date} @ $#{day.close};
         Reason: #{reason}
         Strategy: #{strategy.respond_to?(:name) ? strategy.name : strategy.class.name}
         Profit: $#{profit.places(2)} (#{(profit_percent * 100).places(2)}%)
      SUMMARY
    end
  end

  # Strategies

  class RsiClassic
    attr_accessor :exit_type

    EXITS = {
      :exp_3  => lambda { |day, days_from_entry| days_from_entry == 3 },
      :exp_5  => lambda { |day, days_from_entry| days_from_entry == 5 },
      :exp_10 => lambda { |day, days_from_entry| days_from_entry == 10 },
      :rsi_70 => lambda { |day, days_from_entry| (day.previous.rsi..day.rsi).crossed_above?(70) },
      :rsi_40 => lambda { |day, days_from_entry| (day.previous.rsi..day.rsi).crossed_below?(40) }
    }

    REASONS = {
      :exp_3  => "Expired after 3 days.",
      :exp_5  => "Expired after 5 days.",
      :exp_10 => "Expired after 10 days.",
      :rsi_70 => "RSI crossed above 70",
      :rsi_40 => "RSI dropped below 40."
    }

    def initialize(exit_type)
      raise "invalid exit_type #{exit_type.inspect}" unless EXITS.include?(exit_type)

      @exit_type = exit_type
    end

    def enter?(day)
      if day.previous.rsi < 55 and day.rsi > 55
        "RSI crossed above 55 from #{day.previous.rsi} to #{day.rsi} on #{day.date}"
      end
    end

    def exit?(day, days_from_entry)
      REASONS[exit_type] if EXITS[exit_type].call(day, days_from_entry)
    end

    def name
      "RSI Classic: #{exit_type}"
    end
  end

  class RsiAgita
    ENTER_RSI = [5,10,15,20,25,30,35,40]

    def enter?(day)
      rsi = ENTER_RSI.detect { |n| (day.previous.rsi..day.rsi).crossed_below?(n) }

      if rsi
        "RSI crossed below #{rsi} from #{day.previous.rsi} to #{day.rsi} on #{day.date}"
      end
    end

    def exit?(day, days_from_entry)
      x = (day.previous.rsi..day.rsi).crossed_above?(65)

      if x
        "RSI crossed above 65 from #{day.previous.rsi} to #{day.rsi} on #{day.date}"
      end
    end
  end
end

symbol = ARGV[0] or raise "need symbol"
max_date = ARGV[1]

price_series = PlasticPig::YahooFetcher.new(PlasticPig::PRICE_URL % symbol).fetch
rsi_series = PlasticPig::YahooFetcher.new(PlasticPig::RSI_URL % symbol).fetch

if max_date
  [rsi_series, price_series].each{ |a| a.reject!{|s| s["Date"] > max_date.to_i } }
end

prices_and_rsi = price_series.zip(rsi_series).map do |price, rsi|
  if max_date
    next if !price || !rsi
  else
    unless price["Date"] == rsi["Date"]
      raise "Loading error, series do not align on dates. #{price["Date"]} v #{rsi["Date"]}"
    end
  end

  price.merge(rsi)
end.compact

head = PlasticPig::DayFactory.build_list(prices_and_rsi)

def find_entries(head, strategies)
  entries = []

  head.each do |day|
    if day.previous
      strategies.each do |strategy|
        reason = strategy.enter?(day)

        if reason
          entry = PlasticPig::Entry.new
          entry.strategy = strategy
          entry.reason = reason
          entry.day = day.next

          entries << entry
        end
      end
    end
  end

  entries
end

def find_exits(entries, strategies)
  entries.each do |entry|
    entry.day.each_with_index do |day, i|
      strategies.each do |strategy|
        reason = entry.strategy == strategy && strategy.exit?(day, i + 1)

        if reason
          x = PlasticPig::Exit.new
          x.strategy = strategy
          x.reason = reason
          x.entry = entry
          x.day = day

          entry.exit = x
        end
      end

      break if entry.exit
    end
  end
end

strategies = []
strategies << PlasticPig::RsiClassic.new(:rsi_70)
strategies << PlasticPig::RsiAgita.new

entries = find_entries(head, strategies)
find_exits(entries, strategies)

entries.each { |e| puts "="*80, e.summary, "" }

__END__
interesting: 
C     most active
EEM   6 most active, ishares emerging
EDC   3x emerging
QQQQ  nasdaq
TNA   3x russ 2000
F

