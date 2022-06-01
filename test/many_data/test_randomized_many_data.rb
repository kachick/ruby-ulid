# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestManyData < Test::Unit::TestCase
  include(ULIDAssertions)

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
