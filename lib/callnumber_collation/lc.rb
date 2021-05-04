# frozen_string_literal: true

module CallnumberCollation
  class LC

    # We start with a basic regexp to pull out the initial letter/number set

    LETTERS = /\p{L}{1,5}/
    DIGITS = /\d+/
    CUTTER = /\s*\.?(?:\p{L}\d+)/
    CUTTER_DOON = /#{CUTTER}\s+(?:.*?)/

    CUTTER_STUFF = /(?:(?:#{CUTTER}.+?)+#{CUTTER})|(?:#{CUTTER_DOON})/
    # CUTTER_STUFF = /#{CUTTER_DOON}+/
    YEAR = /\d{4}/

    BASE_REGEX = /\A(#{LETTERS})\s*(#{DIGITS})(?:\.(#{DIGITS}))?(#{CUTTER_STUFF})?\s*(#{YEAR})?(.*)/

    attr_accessor :original, :normalized_original, :letters, :digits, :decimal, :cutter_stuff, :year, :rest

    def initialize(lc)
      @original = lc
      @normalized_original = collapse_strip(@original.downcase)
      match = BASE_REGEX.match(@normalized_original)
      if match
        @letters = (match[1] or '').strip
        @digits = (match[2] or '').strip
        @decimal = (match[3] or '').strip
        @cutter_stuff = (match[4] or '').strip
        @year, @rest = self.year_and_rest(match[5], match[6])
        @valid = true
      else
        @valid = false
      end
    end


    # A constructor that throws an error on invalid
    def self.new!(lc)
      callnum = self.new(lc)
      raise CallnumberCollation::ParseError.new(lc) unless callnum.valid?
      callnum
    end

    # If we have something weird where the final cutter includes some
    # extraneous crap, immediately followed by a year, the regex
    # won't assign the year correctly.
    def year_and_rest(year, rest)
      match = /\A\s*(#{YEAR})(.*)/.match(rest)
      return [year, rest] if year or !match
      [match[1], match[2].strip]
    end

    def normalized_number
      return digits unless decimal?
      "#{digits}.#{decimal}"
    end

    def collatable_cutter_stuff
      return '' unless cutter?
      collapse_strip(cutter_stuff.gsub('.', ' '))
    end

    def normalized_cutter_stuff
      return '' unless cutter?
      '.' + collatable_cutter_stuff
    end

    def normalized_rest
      collapse_strip @rest
    end

    def normalized
      if valid?
        collapse_strip "#{letters}#{normalized_number} #{normalized_cutter_stuff} #{year} #{rest}"
      else
        @normalized_original
      end
    end

    def normalized_components
      return ['', '', '', '', @normalized_original] unless valid?
      [letters, normalized_number, normalized_cutter_stuff, year, rest]
    end



    def pretty_print
      if valid?
        %Q{
        letters: #{letters}
        digits: #{digits}
        decimal: #{decimal}
        cutter: #{normalized_cutter_stuff}
        year: #{year}
        rest: #{rest}
        }
      else
        "<invalid #{normalized_original}>"
      end
    end

    def collatable_letters
      letters + (' ' * (5 - letters.size))
    end

    def collatable_digits
      digits.size.to_s + digits
    end

    def collatable_decimal
      return '' unless decimal?
      ".#{decimal}"
    end

    def collation_key_base
      return @normalized_original unless valid?
      "#{collatable_letters}#{collatable_digits}#{collatable_decimal} #{collatable_cutter_stuff} #{year}".strip
    end

    def collation_key
      return @normalized_original unless valid?
      "#{collation_key_base} #{normalized_rest}".strip
    end

    def to_hash
      {letters: letters, number: normalized_number, cutters: collatable_cutter_stuff, year: year, rest: normalized_rest }
    end

    def valid?
      @valid
    end

    def cutter?
      !(cutter_stuff.empty?)
    end

    def decimal?
      !(decimal.empty?)
    end

    private

    def collapse_strip(str)
      str.gsub(/\s+/, ' ').strip
    end

  end
end

__END__
[
"B1190 1951",
"DT423.E26 9th.ed. 2012",
"E505.5 102nd.F57 1999",
"HB3717 1929.E37 2015",
"KBD.G189s",
"N8354.B67 2000x",
"PS634.B4 1958-63",
"PS3557.A28R4 1955",
"PZ8.3.G276Lo 1971",
"PZ73.S758345255 2011 ",
]