# coding: us-ascii
# frozen_string_literal: true

require('warning')

# How to use => https://test-unit.github.io/test-unit/en/
require('test/unit')

require('irb')
require('power_assert/colorize')
require('irb/power_assert')

Warning[:deprecated] = true
Warning[:experimental] = true

Warning.process do |_warning|
  :raise
end

require_relative('../lib/ulid')

class Test::Unit::TestCase
  module ULIDHelpers
    def sleeping_time
      # NOTE: `SecureRandom.random_number(0.42..1.42)` made `SIGSEGV` on `ruby 3.0.1p64 (2021-04-05 revision 0fb782ee38) [x86_64-darwin20]`
      SecureRandom.random_number(0.12..0.42)
    end
  end

  module ULIDAssertions
    def assert_acceptable_randomized_string(ulids)
      awesome_randomized_ulids = ulids.select { |ulid|
        (0..3).cover?(ULID::TIMESTAMP_ENCODED_LENGTH - ulid.timestamp.squeeze.size) ||
        (0..3).cover?(ULID::RANDOMNESS_ENCODED_LENGTH - ulid.randomness.squeeze.size) ||
        '000' != ulid.randomness.slice(-3, 3)
      }

      assert_in_epsilon(awesome_randomized_ulids.size, ulids.size, 100/100r)
    end
  end
end
