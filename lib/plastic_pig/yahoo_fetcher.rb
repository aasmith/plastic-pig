module PlasticPig
  class YahooFetcher
    attr_reader :url

    def initialize(url)
      @url = url
    end

    def fetch
      read_json(url)
    end

    def read_json(url)
      JSON.parse(fix_json(open(url).read))['series']
    end

    def fix_json(str)
      str.
        # remove the javascript callback around the json.
        gsub(/.*\( (.*)\)/m, '\1').chomp.

        # Yahoo!'s json has an extra (invalid) comma before the closing bracket in the meta entry.
        gsub(/,\s*\n\s*\}/m, "}")
    end
  end
end
