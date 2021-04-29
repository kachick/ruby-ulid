# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestULIDMonotonicGenerator < Test::Unit::TestCase
  def setup
    @generator = ULID::MonotonicGenerator.new
  end

  def test_multiple_instance
    assert_not_same(ULID::MonotonicGenerator.new, ULID::MonotonicGenerator.new)
  end

  def test_bigdata
    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      @generator.generate
    end

    assert_equal(1000, ulids.map(&:to_s).uniq.size)
    assert_equal(true, (5..50).cover?(ulids.group_by(&:to_time).size))
    assert_equal(ulids, ulids.sort_by(&:to_s))
    assert_equal(ulids, ulids.sort_by(&:to_i))
    assert_equal(ulids, ulids.sort)
  end
end

class TestULIDMonotonicGeneratorOfClassState < Test::Unit::TestCase
  def test_interface
    assert_instance_of(ULID, ULID.monotonic_generate)
    assert_not_equal(ULID.monotonic_generate, ULID.monotonic_generate)
    first = ULID.monotonic_generate
    second = ULID.monotonic_generate
    assert_equal(true, second > first)
  end

  def test_bigdata
    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      ULID.monotonic_generate
    end

    assert_equal(1000, ulids.map(&:to_s).uniq.size)
    assert_equal(true, (5..50).cover?(ulids.group_by(&:to_time).size))
    assert_equal(ulids, ulids.sort_by(&:to_s))
    assert_equal(ulids, ulids.sort_by(&:to_i))
    assert_equal(ulids, ulids.sort)
  end

  def test_freeze
    assert_raises(TypeError) do
      ULID::MONOTONIC_GENERATOR.freeze
    end

    assert_equal(false, ULID::MONOTONIC_GENERATOR.frozen?)
  end

  def test_attributes
    id = BasicObject.new
    assert_nil(ULID::MONOTONIC_GENERATOR.latest_milliseconds)
    assert_nil(ULID::MONOTONIC_GENERATOR.latest_entropy)

    ULID::MONOTONIC_GENERATOR.latest_milliseconds = id
    ULID::MONOTONIC_GENERATOR.latest_entropy = id

    assert_same(id, ULID::MONOTONIC_GENERATOR.latest_milliseconds)
    assert_same(id, ULID::MONOTONIC_GENERATOR.latest_entropy)
  end

  def teardown
    ULID::MONOTONIC_GENERATOR.reset
  end
end
