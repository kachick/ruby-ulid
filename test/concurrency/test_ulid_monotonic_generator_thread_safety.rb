# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDMonotonicGeneratorThreadSafety < Test::Unit::TestCase
  def test_thread_safe
    generator = ULID::MonotonicGenerator.new
    thread_count = 5000
    moment = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_time

    ulids = []
    worked_thread_numbers = []

    threads = 1.upto(thread_count).map do |n|
      Thread.start(n) do |tn|
        sleep(rand)
        worked_thread_numbers << tn
        ulids << generator.generate(moment: moment)
      end
    end

    threads.each(&:join)

    assert_equal(thread_count, worked_thread_numbers.uniq.size)
    assert_not_equal(worked_thread_numbers.sort, worked_thread_numbers)

    assert do
      ulids.map(&:to_time).uniq == [moment]
    end

    ulids.sort.each_cons(2) do |pred, succ|
      assert do
        pred.to_i.succ == succ.to_i
      end
    end
  end
end
