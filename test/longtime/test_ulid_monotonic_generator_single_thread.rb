# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDMonotonicGeneratorWithSingleThread < Test::Unit::TestCase
  include ULIDAssertions

  def test_prev_with_many_data
    generator = ULID::MonotonicGenerator.new
    prevs = []

    1.upto(2000).map do |n|
      sleep(0.0042)
      prevs << generator.prev
      generator.generate
    end

    assert_equal(1, prevs.count(nil))
    assert_equal(2000, prevs.size)
    assert_equal(2000, prevs.uniq.size)

    times_count = prevs.compact.count(&:to_time)
    assert do
      420 < times_count
    end
  end

  def test_inspect_with_many_data
    generator = ULID::MonotonicGenerator.new
    prevs = []

    1.upto(2000).map do |n|
      sleep(0.0042)
      prevs << generator.inspect
      generator.generate
    end

    assert_equal(2000, prevs.size)
    assert_equal(2000, prevs.uniq.size)
  end
end
