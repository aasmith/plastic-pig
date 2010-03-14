# http://www.investopedia.com/articles/trading/08/macd-stochastic-double-cross.asp
module PlasticPig
  module Strategies
    class DoubleCross
      def enter?(day)
        days = [day.previous, day]

        return false unless days.all?

        pd = day.previous.stochasticslow_signal
        pk = day.previous.stochasticslow_stochastic

        d = day.stochasticslow_signal
        k = day.stochasticslow_stochastic

        # does k cross over d ?
        a = !(pk > d) && (k > d)

        # k less than 50
        b = k < 50

        # macd div > 0 and macd > sig
        #c = days.any?{|d| d.macd_divergence > 0 }
        #d = days.any?{|d| d.macd > d.macd_signal }

        # price above sma?
        e = day.close > day.sma

        if a and b and e
          "double cross met"
        end
      end

      def exit?(day, days_from_entry)
        "getting old" if days_from_entry >= 5
      end
    end
  end
end
