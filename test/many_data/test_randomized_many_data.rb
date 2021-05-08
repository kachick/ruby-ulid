# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestManyData < Test::Unit::TestCase
  include ULIDAssertions

  def test_generate
    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      ULID.generate
    end

    assert_equal(1000, ulids.map(&:to_s).uniq.size)
    assert_equal(true, (5..50).cover?(ulids.group_by(&:to_time).size))
    assert_not_equal(ulids, ulids.sort_by(&:to_s))
  end

  def test_string_format_and_reversible
    ULID.sample(10000).each do |ulid|
      assert_equal(ULID::ENCODED_LENGTH, ulid.to_s.size)
      assert_equal(ULID::ENCODED_LENGTH, ulid.to_s.bytesize)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s).to_s)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s.downcase).to_s)
    end
  end

  def test_sample
    ulids = ULID.sample(10000)

    # Rough tests for the randomness. But I guess it basically will not fail :)
    assert_equal(ulids, ulids.uniq)
    timestamps = ulids.map(&:timestamp)
    assert_equal(ulids.size, timestamps.uniq.size)
    randomnesses = ulids.map(&:randomness)
    assert_equal(ulids.size, randomnesses.uniq.size)
    timestamps.shuffle.each_cons(2) do |a, b|
      assert_acceptable_timestamp_string(a, b)
    end
    randomnesses.shuffle.each_cons(2) do |a, b|
      assert_acceptable_randomness_string(a, b)
    end

    first = Time.at(1619676780123456789/1000000000r).utc #=> 2021-04-29 06:13:00.123456789 UTC
    last = Time.at(1620345540123456789/1000000000r).utc #=> 2021-05-06 23:59:00.123456789 UTC
    exclude_end = first...last
    ranged_ulids = ULID.sample(10000, period: exclude_end)
    assert_equal(10000, ranged_ulids.size)
    assert_nil(ranged_ulids.uniq!)
    moments = ranged_ulids.map(&:to_time)
    assert((9000..10000).cover?(moments.uniq.size))
    ranged_ulids.shuffle.each_cons(2) do |ulid1, ulid2|
      assert_acceptable_randomness_string(ulid1.randomness, ulid2.randomness)
    end
  end

  def test_octets
    ULID.sample(10000).each do |ulid|
      assert_instance_of(Array, ulid.octets)
      assert(ulid.octets.all?(Integer))
      assert_equal(ULID::OCTETS_LENGTH, ulid.octets.size)
      assert_not_same(ulid.octets, ulid.octets)
      assert_equal(false, ulid.octets.frozen?)

      assert_instance_of(Array, ulid.timestamp_octets)
      assert(ulid.timestamp_octets.all?(Integer))
      assert_equal(ULID::TIMESTAMP_OCTETS_LENGTH, ulid.timestamp_octets.size)
      assert_not_same(ulid.timestamp_octets, ulid.timestamp_octets)
      assert_equal(false, ulid.timestamp_octets.frozen?)

      assert_instance_of(Array, ulid.randomness_octets)
      assert(ulid.randomness_octets.all?(Integer))
      assert_equal(ULID::RANDOMNESS_OCTETS_LENGTH, ulid.randomness_octets.size)
      assert_not_same(ulid.randomness_octets, ulid.randomness_octets)
      assert_equal(false, ulid.randomness_octets.frozen?)

      assert_equal(ulid.octets, ulid.timestamp_octets + ulid.randomness_octets)
    end
  end
end
