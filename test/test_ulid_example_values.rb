# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestULIDWithExampleValues < Test::Unit::TestCase
  def test_oklog_examples
    # https://github.com/oklog/ulid/tree/e7ac4de44d238ff4707cc84b9c98ae471f31e2d1#usage
    assert_equal('0000XSNJG0', ULID.generate(moment: Time.at(1000000)).timestamp)
    time = Time.utc(2019, 3, 31, 3, 51, 23, 536000)
    assert_equal(time, ULID.parse('01D78XZ44G0000000000000000').to_time)
    assert_equal('01D78XZ44G0000000000000000', ULID.min(moment: time).to_s)

    # https://github.com/oklog/ulid/blob/e7ac4de44d238ff4707cc84b9c98ae471f31e2d1/ulid_test.go#L204-L213
    assert_equal('01ARYZ6S410000000000000000', ULID.min(moment: 1469918176385).to_s)

    # https://github.com/oklog/ulid/blob/e7ac4de44d238ff4707cc84b9c98ae471f31e2d1/ulid_test.go#L472-L487
    assert_instance_of(ULID, ULID.parse('00000000000000000000000000'))
    assert_instance_of(ULID, ULID.parse('70000000000000000000000000'))
    assert_instance_of(ULID, ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    # Might be change to ULID::ParserError in this library ref: https://github.com/kachick/ruby-ulid/issues/45
    assert_raises(ULID::OverflowError) do
      ULID.parse('80000000000000000000000000')
    end
    assert_raises(ULID::OverflowError) do
      ULID.parse('80000000000000000000000001')
    end
    assert_raises(ULID::OverflowError) do
      ULID.parse('ZZZZZZZZZZZZZZZZZZZZZZZZZZ')
    end

    # https://github.com/oklog/ulid/blob/e7ac4de44d238ff4707cc84b9c98ae471f31e2d1/ulid_test.go#L690-L712
    assert_instance_of(ULID, ULID.parse('0000XSNJG0MQJHBF4QX1EFD6Y3'))
  end
end
