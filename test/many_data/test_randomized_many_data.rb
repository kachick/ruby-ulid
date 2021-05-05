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

  def test_parse_reversible
    10000.times do
      ulid_string = ULID.from_integer(SecureRandom.random_number(ULID::MAX_INTEGER)).to_s
      assert_equal(ulid_string, ULID.parse(ulid_string).to_s)
    end
  end
end
