module PlasticPig
  module Structures
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
        summary = []

        if day
          summary << "Exit at start of day #{day.date} @ $#{day.open};"
        else
          summary << "EXIT NEXT TRADING DAY AT OPEN"
        end

        summary << "Reason: #{reason}"
        summary << "Strategy: #{strategy.respond_to?(:name) ? strategy.name : strategy.class.name}"

        summary << "Profit: $#{profit.places(2)} (#{(profit_percent * 100).places(2)}%)" if day

        summary.map{|s| "\t#{s}"}.join("\n")
      end
    end
  end
end
