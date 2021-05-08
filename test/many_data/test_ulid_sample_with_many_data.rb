# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDSampleWithManyData < Test::Unit::TestCase
  def test_sample
    ulids = ULID.sample(10000)

    # Rough tests for the randomness. But I guess it basically will not fail :)
    assert_equal(ulids, ulids.uniq)
    timestamps = ulids.map(&:timestamp)
    assert_equal(ulids.size, timestamps.uniq.size)
    randomnesses = ulids.map(&:randomness)
    assert_equal(ulids.size, randomnesses.uniq.size)

    first = Time.at(1619676780123456789/1000000000r).utc #=> 2021-04-29 06:13:00.123456789 UTC
    last = Time.at(1620345540123456789/1000000000r).utc #=> 2021-05-06 23:59:00.123456789 UTC
    exclude_end = first...last
    ranged_ulids = ULID.sample(10000, period: exclude_end)
    assert_equal(10000, ranged_ulids.size)
    assert_nil(ranged_ulids.uniq!)
    moments = ranged_ulids.map(&:to_time)
    assert((9000..10000).cover?(moments.uniq.size))
  end
end
