module PlasticPig
  module Strategies
    class SimpleMacd
      def enter?(day)
        "div rose above 0" if (day.previous.macd_divergence..day.macd_divergence).crossed_above?(0)
      end

      def exit?(day, days_from_entry)
        "bored" if days_from_entry >= 3
      end
    end
  end
end
