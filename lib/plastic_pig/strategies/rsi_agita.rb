module PlasticPig
  module Strategies
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
end
