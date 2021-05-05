# frozen_string_literal: true

require 'json'

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

    # Letters are already alphabetized. So do nothing.
    def collatable_letters
      letters
    end

    # For the initial digits (before the decimal), we prepend the length of the string of digits.
    # Thus all 4-digit numbers come before all 3-digit numbers, and the rest of the numerals
    # alphabetize as you'd expect
    def collatable_digits
      digits.size.to_s + digits
    end

    # We can leave decimals alone (since they'll alphabetize fine), only adding a decimal point back if need be
    def collatable_decimal
      return '' unless decimal?
      ".#{decimal}"
    end

    # Cutters sometimes have too many spaces, 2rd or 3rd cutters that start with
    # dots, etc. We just eliminate all the dots and collapse the whitespace
    # to make them all uniform
    def collatable_cutter_stuff
      return '' unless cutter?
      collapse_strip(cutter_stuff.gsub('.', ' '))
    end

    # For the "rest", turn all punctuation into spaces before collapsing
    def collatable_rest
      collapse_strip rest.gsub(/\p{Punct}/, ' ')
    end

    # The "base" attempts to remove everything after the year, but of course if the cutters didn't parse
    # correctly this won't work.
    def collation_key_base
      return @normalized_original unless valid?
      "#{collatable_letters}#{collatable_digits}#{collatable_decimal} #{collatable_cutter_stuff} #{year}".strip
    end

    # Slam it all back together into something that will alphabetize
    def collation_key
      return @normalized_original unless valid?
      "#{collation_key_base} #{collatable_rest}".strip
    end

    # Normalize the number by putting it back together with a decimal point
    def normalized_number
      return digits unless decimal?
      "#{digits}.#{decimal}"
    end

    # The collation method for cutters does most of the heavy lifting.
    # For normalization, we add a '.' before the first cutter
    def normalized_cutter_stuff
      return '' unless cutter?
      '.' + collatable_cutter_stuff
    end

    # For the "rest" just collapse/strip whitespace
    def normalized_rest
      collapse_strip @rest
    end

    # The normalized version of an LC number has no spaces between the letters and numbers
    # and a dot before only the first cutter
    def normalized
      if valid?
        collapse_strip "#{letters}#{normalized_number} #{normalized_cutter_stuff} #{year} #{rest}"
      else
        @normalized_original
      end
    end



    def to_s
      if valid?
        "<#{self.class} " + {
          letters: letters,
          digits: digits,
          decimal: decimal,
          cutter: normalized_cutter_stuff,
          year: year,
          rest: rest
        }.to_s + ">"
      else
        "<invalid #{normalized_original}>"
      end
    end

    def pretty_print(pp)
      pp.text(to_s)
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

    # Hash representation, for easier jsonification
    def to_hash
      { letters: letters, number: normalized_number, cutters: collatable_cutter_stuff, year: year, rest: normalized_rest }
    end

    def to_json
      to_hash.to_json
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