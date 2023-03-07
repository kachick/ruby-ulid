# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestMonotonicGeneratorWithNoMomentDependsOnCurrentTime < Test::Unit::TestCase
  def test_monotonic_generator_with_no_moment_depends_on_current_time
    generator = ULID::MonotonicGenerator.new
    starts_at = Time.now

    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      generator.generate
    end

    acceptable_period = ULID.floor(starts_at)..(starts_at + 2)

    assert_equal(1000, ulids.map(&:to_s).uniq.size)

    ulids_by_the_time = ulids.group_by(&:to_time)
    sorted_times = ulids_by_the_time.keys
    assert do
      (10..50).cover?(sorted_times.size)
    end

    sorted_times.each_cons(2) do |pred, succ|
      assert do
        (pred.to_i == succ.to_i) || (pred.to_i.succ == succ.to_i)
      end
    end

    # Ensure the incrementing logic
    ulids_by_the_time.each_pair do |time, ulids_in_the_time|
      assert do
        acceptable_period.cover?(time)
      end

      ulids_in_the_time.each_cons(2) do |pred, succ|
        assert do
          pred.to_i.succ == succ.to_i
        end
      end
    end

    sample_ulids_in_different_time = ulids_by_the_time.values.map(&:first)

    # No reasonable basis for this range!
    acceptable_randomness = 42000000..ULID::MAX_ENTROPY

    sample_ulids_in_different_time.each_cons(2) do |pred, succ|
      assert do
        acceptable_randomness.cover?((pred.entropy - succ.entropy).abs)
      end
    end

    assert_equal(ulids, ulids.sort_by(&:to_s))
    assert_equal(ulids, ulids.sort_by(&:to_i))
    assert_equal(ulids, ulids.sort)
  end
end
