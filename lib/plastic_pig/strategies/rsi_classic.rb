module PlasticPig
  module Strategies
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
        if EXITS[exit_type].call(day, days_from_entry)
          REASONS[exit_type] + " on #{day.date}"
        end
      end

      def name
      "RSI Classic: #{exit_type}"
      end
    end
  end
end
