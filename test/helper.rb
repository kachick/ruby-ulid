# coding: us-ascii
# frozen_string_literal: true

require 'warning'

# How to use => https://test-unit.github.io/test-unit/en/
require 'test/unit'

require 'irb'
require 'power_assert/colorize'

if Warning.respond_to?(:[]=) # @TODO Removable this guard after dropped ruby 2.6
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

Warning.process do |_warning|
  :raise
end

require_relative '../lib/ulid'

class Test::Unit::TestCase
  module ULIDAssertions
    def assert_acceptable_randomized_string(ulid)
      assert do
        (0..4).cover?(ULID::TIMESTAMP_ENCODED_LENGTH - ulid.timestamp.squeeze.size)
      end

      assert do
        (0..5).cover?(ULID::RANDOMNESS_ENCODED_LENGTH - ulid.randomness.squeeze.size)
      end

      assert do
        '000' != ulid.randomness.slice(-3, 3)
      end
    end
  end
end
