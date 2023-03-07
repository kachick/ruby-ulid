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
    assert_true((5..50).cover?(ulids.group_by(&:to_time).size))
    assert_not_equal(ulids, ulids.sort_by(&:to_s))
  end

  def test_encode
    ulid_strings = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      ULID.encode
    end

    assert_equal(1000, ulid_strings.uniq.size)
    assert_true((5..50).cover?(ulid_strings.map { |str| ULID.parse(str) }.group_by(&:to_time).size))
    assert_not_equal(ulid_strings, ulid_strings.sort)
  end

  def test_string_format_and_reversible
    ULID.sample(10000).each do |ulid|
      assert_equal(ULID::ENCODED_LENGTH, ulid.to_s.size)
      assert_equal(ULID::ENCODED_LENGTH, ulid.to_s.bytesize)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s).to_s)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s.downcase).to_s)
      assert_equal(ULID.parse(ulid.to_s).to_time, ULID.decode_time(ulid.to_s))
      assert_equal(ULID.parse(ulid.to_s).to_time, ULID.decode_time(ulid.to_s.downcase))
    end
  end

  def test_octets
    ULID.sample(10000).each do |ulid|
      assert_instance_of(Array, ulid.octets)
      assert(ulid.octets.all?(Integer))
      assert_equal(ULID.const_get(:OCTETS_LENGTH), ulid.octets.size)
      assert_not_same(ulid.octets, ulid.octets)
      assert_false(ulid.octets.frozen?)
    end
  end
end
