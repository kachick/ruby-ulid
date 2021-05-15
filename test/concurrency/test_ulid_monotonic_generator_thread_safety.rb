# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDMonotonicGeneratorThreadSafety < Test::Unit::TestCase
  include ULIDAssertions

  def sleeping_time
    SecureRandom.random_number(0.42..1.42)
  end

  def test_thread_safe_without_arguments
    generator = ULID::MonotonicGenerator.new
    thread_count = 2000
    starts_at = Time.now

    ulids = []
    worked_thread_numbers = []

    threads = 1.upto(thread_count).map do |n|
      Thread.start(n) do |thread_number|
        sleep(sleeping_time)
        worked_thread_numbers << thread_number
        ulids << generator.generate
      end
    end

    threads.each(&:join)

    possible_period = ULID.floor(starts_at)...Time.now

    assert_equal(thread_count, worked_thread_numbers.uniq.size)
    assert_not_equal(worked_thread_numbers.sort, worked_thread_numbers)

    ulids_by_the_time = ulids.group_by(&:to_time)

    # I don't know thw `42` is reasonable or not :yum:
    assert(ulids_by_the_time.size > 42)

    assert do
      ulids_by_the_time.keys.all?(possible_period)
    end

    ulids_by_the_time.sort.each do |_time, ulids|
      ulids.sort.each_cons(2) do |pred, succ|
        assert do
          pred.to_i.succ == succ.to_i
        end
      end
    end
  end

  def test_thread_safe_with_fixed_times
    generator = ULID::MonotonicGenerator.new
    thread_count = 2000
    moment = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_time

    ulids = []
    worked_thread_numbers = []

    threads = 1.upto(thread_count).map do |n|
      Thread.start(n) do |thread_number|
        sleep(sleeping_time)
        worked_thread_numbers << thread_number
        ulids << generator.generate(moment: moment)
      end
    end

    threads.each(&:join)

    assert_equal(thread_count, worked_thread_numbers.uniq.size)
    assert_not_equal(worked_thread_numbers.sort, worked_thread_numbers)

    assert_equal([moment], ulids.map(&:to_time).uniq)

    ulids.sort.each_cons(2) do |pred, succ|
      assert do
        pred.to_i.succ == succ.to_i
      end
    end
  end

  # I don't have confident for this test is the reasonable one... Concurrency is hard to human. :cry:
  def test_thread_safe_with_randomized_time
    generator = ULID::MonotonicGenerator.new
    thread_count = 3000
    initial_and_median = ULID.generate

    generator.instance_exec do
      @prev = initial_and_median
    end

    # Given smaller than initial should not be happened... But addeed for ensuring https://github.com/kachick/ruby-ulid/issues/56
    sample_1000_times_before_median = ULID.sample(1000, period: (initial_and_median.to_time - 999999)..initial_and_median.to_time).map(&:to_time)
    sample_2000_times_after_median = ULID.sample(2000, period: initial_and_median.to_time..(initial_and_median.to_time + 999999)).map(&:to_time)

    sample_times = sample_1000_times_before_median + sample_2000_times_after_median
    assert_equal(thread_count, sample_times.uniq.size)

    sample_times.shuffle!
    basically_random_but_contain_same_1000_times = sample_times.take(2000) + sample_times.take(1000)
    assert_equal(thread_count, basically_random_but_contain_same_1000_times.size)
    assert_equal(2000, basically_random_but_contain_same_1000_times.uniq.size)
    assert(basically_random_but_contain_same_1000_times.none?(initial_and_median.to_time))

    # Might be flaky...
    later_than_initial_and_median_count = basically_random_but_contain_same_1000_times.count{ |time| time > initial_and_median.to_time }
    assert do
      1500 < later_than_initial_and_median_count
    end

    ulids = []

    # Depend on `OrderedHash`
    time_by_thread_number = {}
    offset = 1
    threads = basically_random_but_contain_same_1000_times.shuffle.each_with_index.map do |time, index|
      Thread.start(time, index + offset) do |time_in_thread, thread_number|
        sleep(sleeping_time)
        time_by_thread_number[thread_number] = time_in_thread
        ulids << generator.generate(moment: time_in_thread)
      end
    end

    threads.each(&:join)

    # This block just ensuring obvious behavior. If failed, bug exists in this test.
    assert_equal(thread_count, ulids.uniq.size)
    worked_thread_numbers = time_by_thread_number.keys
    given_times = time_by_thread_number.values
    assert_equal(thread_count, worked_thread_numbers.uniq.size)
    assert_not_equal(worked_thread_numbers.sort, worked_thread_numbers)
    assert_equal(2000, given_times.uniq.size)
    assert_equal(later_than_initial_and_median_count, given_times.count{ |time| time > initial_and_median.to_time })

    ulids_by_time = ulids.group_by(&:to_time)
    uniq_times = ulids_by_time.keys

    # Really? I have a feeling it should get much greater...
    acceptable_same_timestamp_count = 3
    assert do
      uniq_times.size >= acceptable_same_timestamp_count
    end

    # This is a crucial spec. ref: https://github.com/kachick/ruby-ulid/issues/56
    assert do
      uniq_times.all? { |time| time >= initial_and_median.to_time }
    end

    bumped_timestamp_count = 0

    ulids.sort.each_cons(2) do |pred, succ|
      case
      when pred.to_time < succ.to_time
        bumped_timestamp_count += 1

        # This is a crucial spec. But I don't know the 420000 is reasonable or not...
        assert do
          (pred.entropy -  succ.entropy).abs > 420000
        end
        assert_acceptable_randomized_string(pred)
      when pred.to_time == succ.to_time
        # This is a crucial spec.
        assert do
          pred.to_i.succ == succ.to_i
        end
      else
        # Intentional comment!
        # binding.irb
        raise 'Should not reach here!'
      end
    end

    assert do
      (bumped_timestamp_count <= uniq_times.size) && (bumped_timestamp_count >= (uniq_times.size - 1))
    end
  end
end
