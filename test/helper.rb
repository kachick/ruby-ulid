# coding: us-ascii
# frozen_string_literal: true

# How to use: https://github.com/jeremyevans/ruby-warning
require('warning')

# How to use: https://test-unit.github.io/test-unit/en/
require('test/unit')

require('irb')
require('power_assert/colorize')
require('irb/power_assert')

require 'stringio'

Warning[:deprecated] = true
Warning[:experimental] = true

Warning.process do |_warning_message|
  :raise
end

require_relative('../lib/ulid')

class Test::Unit::TestCase
  module ULIDHelpers
    def sleeping_time
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

      assert_in_epsilon(awesome_randomized_ulids.size, ulids.size, (5/100r).to_f)
    end
  end

  def assert_warning(pattern, &block)
    org_stderr = $stderr
    $stderr = fake_io = StringIO.new(+'', 'r+')

    Warning.clear do
      begin
        block.call
        fake_io.rewind
        assert_match(pattern, fake_io.read)
      ensure
        $stderr = org_stderr
      end
    end
  end
end
