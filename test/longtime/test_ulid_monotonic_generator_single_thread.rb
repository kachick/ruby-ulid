# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDMonotonicGeneratorWithSingleThread < Test::Unit::TestCase
  include(ULIDAssertions)

  def test_last_with_many_data
    generator = ULID::MonotonicGenerator.new
    lasts = []

    1.upto(2000) do
      sleep(0.0042)
      lasts << generator.last
      generator.generate
    end

    assert_equal(1, lasts.count(nil))
    assert_equal(2000, lasts.size)
    assert_equal(2000, lasts.uniq.size)

    times_count = lasts.compact.count(&:to_time)
    assert do
      420 < times_count
    end
  end

  def test_inspect_with_many_data
    generator = ULID::MonotonicGenerator.new
    lasts = []

    1.upto(2000) do
      sleep(0.0042)
      lasts << generator.inspect
      generator.generate
    end

    assert_equal(2000, lasts.size)
    assert_equal(2000, lasts.uniq.size)
  end
end
