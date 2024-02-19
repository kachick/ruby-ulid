# coding: us-ascii
# frozen_string_literal: true

# TODO: Remove this line after #495

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

WARNING_PROCESS = ->_warning_message {
  :raise
}

Warning.process(&WARNING_PROCESS)

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
    raise(ArgumentError, 'should pass block as an warning sandbox') unless block_given?

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

  def allow_warning(pattern, &block)
    # Some errors can not be handled by only path. So covered for internal warnings. See below
    #   - https://github.com/ruby/ruby/pull/6629
    #   - https://github.com/jeremyevans/ruby-warning/blob/eae08ac7b43ae577f86dc29e6629b80694ef96f0/lib/warning.rb#L221-L222
    caller_path = caller_locations.map(&:path).grep_v(%r!/gems/!).last
    path_pattern = Regexp.union(/<internal:\S+?>/, caller_path)
    Warning.clear do
      # Both ignore and process can be passed https://github.com/jeremyevans/ruby-warning/blob/eae08ac7b43ae577f86dc29e6629b80694ef96f0/lib/warning.rb#L219-L267
      Warning.ignore(pattern, path_pattern)
      # Warning.clear is not just a sandbox. It initially clears state in the block https://github.com/jeremyevans/ruby-warning/blob/eae08ac7b43ae577f86dc29e6629b80694ef96f0/lib/warning.rb#L48-L74
      Warning.process(&WARNING_PROCESS)
      block.call
    end
  end
end
