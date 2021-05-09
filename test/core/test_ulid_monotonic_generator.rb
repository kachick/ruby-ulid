# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDMonotonicGenerator < Test::Unit::TestCase
  def setup
    @generator = ULID::MonotonicGenerator.new
  end

  def test_multiple_instance
    assert_not_same(ULID::MonotonicGenerator.new, ULID::MonotonicGenerator.new)
  end

  def test_interface
    assert_instance_of(ULID::MonotonicGenerator, @generator)
    assert_not_equal(@generator.generate, @generator.generate)
    first = @generator.generate
    second = @generator.generate
    assert_equal(true, second > first)
  end

  def test_many_data
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

  def test_generate_with_no_moment_uses_current_time
    running_at = Time.now
    assert_equal(true, (ULID.floor(running_at)..(running_at + 3)).cover?(@generator.generate.to_time))
  end

  def test_generate_with_negative_moment
    assert_raises(ArgumentError) do
      @generator.generate(moment: -1)
    end
  end

  def test_generate_optionally_take_moment_as_time
    pred = nil
    1.upto(100) do |sec|
      ulid = @generator.generate(moment: Time.at(sec))
      assert_equal(sec, ulid.to_time.to_r)
      if pred
        assert_equal(true, 4200 < (pred.entropy - ulid.entropy).abs) # It is possible to fail Rough test.
      end
      pred = ulid
    end
  end

  def test_generate_optionally_take_moment_as_milliseconds
    pred = nil
    1.upto(100) do |milliseconds|
      ulid = @generator.generate(moment: milliseconds)
      assert_equal(milliseconds, ulid.milliseconds)
      if pred
        assert_equal(true, 4200 < (pred.entropy - ulid.entropy).abs) # It is possible to fail. Rough test.
      end
      pred = ulid
    end
  end

  def test_generate_just_bump_1_when_same_moment
    first = @generator.generate(moment: 42)
    second = @generator.generate(moment: 42)
    assert_equal(second.to_time, first.to_time)
    assert_equal(second.entropy, first.entropy.next)
  end

  def test_generate_ignores_lower_moment_than_latest_is_given
    first = @generator.generate(moment: 42)
    second = @generator.generate(moment: 41)
    assert_equal(second.to_time, first.to_time)
    assert_equal(second.entropy, first.entropy.next)
  end

  def test_generate_raises_overflow_when_called_on_max_entropy
    max_ulid_in_a_milliseconds = ULID.max(moment: 42)

    @generator.latest_milliseconds = max_ulid_in_a_milliseconds.milliseconds
    @generator.latest_entropy = ULID::MAX_ENTROPY.pred

    assert_equal(max_ulid_in_a_milliseconds, @generator.generate(moment: max_ulid_in_a_milliseconds.milliseconds))

    @generator.reset

    @generator.latest_milliseconds = max_ulid_in_a_milliseconds.milliseconds
    @generator.latest_entropy = ULID::MAX_ENTROPY

    assert_raises(ULID::OverflowError) do
      @generator.generate(moment: max_ulid_in_a_milliseconds.milliseconds)
    end
  end

  def test_freeze
    assert_raises(TypeError) do
      @generator.freeze
    end

    assert_equal(false, @generator.frozen?)
  end
end
