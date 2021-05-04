# frozen_string_literal: true

require_relative "callnumber_collation/version"
require_relative 'callnumber_collation/lc'

module CallnumberCollation
  class Error < StandardError; end
  class ParseError < StandardError; end
  # Your code goes here...
end
