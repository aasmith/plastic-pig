module PlasticPig
  module Structures
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
  end
end
