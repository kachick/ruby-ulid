# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestManyData < Test::Unit::TestCase
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
      assert_equal(ULID::ENCODED_ID_LENGTH, ulid.to_s.size)
      assert_equal(ULID::ENCODED_ID_LENGTH, ulid.to_s.bytesize)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s).to_s)
      assert_equal(ulid.to_s, ULID.parse(ulid.to_s.downcase).to_s)
    end
  end

  def test_sample
    ulids = ULID.sample(10000)

    # Rough tests for the randomness. But I guess it basically will not fail :)
    assert_equal(ulids, ulids.uniq)
    assert_equal(ulids.size, ulids.group_by(&:timestamp).size)
    assert_equal(ulids.size, ulids.group_by(&:randomness).size)
  end
end
