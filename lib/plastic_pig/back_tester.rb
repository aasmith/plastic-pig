module PlasticPig
  class BackTester
    attr_accessor :series, :strategies

    def initialize(series, strategies)
      @series = series
      @strategies = strategies
    end

    def run
      entries = find_entries
      find_exits(entries) # Adds exits to entries.
      entries
    end

    def find_entries
      entries = []

      series.each do |day|
        if day.previous
          strategies.each do |strategy|
            reason = strategy.enter?(day)

            if reason
              entry = PlasticPig::Structures::Entry.new
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

    def find_exits(entries)
      entries.each do |entry|
        next unless entry.day

        entry.day.each_with_index do |day, i|
          strategies.each do |strategy|
            reason = entry.strategy == strategy && strategy.exit?(day, i + 1)

            if reason
              x = PlasticPig::Structures::Exit.new
              x.strategy = strategy
              x.reason = reason
              x.entry = entry
              x.day = day.next

              entry.exit = x
            end
          end

          break if entry.exit
        end
      end
    end
  end
end
