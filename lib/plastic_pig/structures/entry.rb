module PlasticPig
  module Structures
    class Entry
      attr_accessor :day, :reason, :exit, :strategy

      def price
        day.open
      end

      def summary
        summaries = []

        if day
          summaries << "Entered at start of day #{day.date} @ $#{day.open}"
        else
          summaries << "ENTER NEXT TRADING DAY AT OPEN"
        end

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
  end
end
