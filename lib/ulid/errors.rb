# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

class ULID
  class Error < StandardError; end
  class OverflowError < Error; end
  class ParserError < Error; end
  class UnexpectedError < Error; end
end
