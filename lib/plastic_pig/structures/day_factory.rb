module PlasticPig
  module Structures
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
  end
end
