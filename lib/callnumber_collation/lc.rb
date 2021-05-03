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

    attr_accessor :original, :letters, :digits, :decimal, :cutter_stuff, :year, :rest

    def initialize(lc)
      @original = lc.strip.downcase
      match = BASE_REGEX.match(@original)
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

    # If we have something weird where the final cutter includes some
    # extraneous crap, immediately followed by a year, the regex
    # won't assign the year correctly.
    def year_and_rest(year, rest)
      match = /\A\s*(#{YEAR})(.*)/.match(rest)
      return [year, rest] if year or !match
      puts "Fixing!"
      [match[1], match[2].strip]
    end

    def normalized_number
      if decimal == ''
        digits
      else
        "#{digits}.#{decimal}"
      end
    end

    def collatable_cutter_stuff
      return '' if cutter_stuff == ''
      cutter_stuff.gsub('.', ' ').gsub(/\s+/, ' ').strip
    end

    def normalized_cutter_stuff
      return '' if cutter_stuff == ''
      '.' + collatable_cutter_stuff
    end

    def normalized_rest
      rest.gsub(/\s+/, ' ').strip
    end

    def normalized
      return @original unless valid?
      "#{letters}#{normalized_number} #{normalized_cutter_stuff} #{year} #{rest}".gsub(/\s+/, ' ').strip
    end

    def normalized_components
      return '' unless valid?
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
        "<invalid>"
      end
    end

    def collatable_letters
      letters + (' ' * (5 - letters.size))
    end

    def collatable_digits
      digits.size.to_s + digits
    end

    def collatable_decimal
      if decimal == ''
        ''
      else
        ".#{decimal}"
      end
    end

    def collation_key_base
      return @original unless valid?
      "#{collatable_letters}#{collatable_digits}#{collatable_decimal} #{collatable_cutter_stuff} #{year}".strip
    end

    def collation_key
      return @original unless valid?
      "#{collation_key_base} #{rest}".strip
    end

    def valid?
      @valid
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