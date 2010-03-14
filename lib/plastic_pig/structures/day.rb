module PlasticPig
  module Structures
    class Day
      include LinkedList

      VARS = %w(
        date open high low close volume
        rsi
        sma
        macd macd_divergence macd_signal
        stochasticslow_signal stochasticslow_stochastic
      )
      attr_accessor *VARS

      def parsed_date
        @parsed_date ||= Date.parse(date.to_s)
      end

      def inspect
        pairs = VARS.map{|v| "#{v}=#{send(v.to_sym).inspect}" }

        "<Day: #{pairs.join(",")}>"
      end
    end
  end
end
