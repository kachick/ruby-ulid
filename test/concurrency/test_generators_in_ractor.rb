# coding: utf-8
# frozen_string_literal: true

return unless RUBY_VERSION >= '3.0'

require_relative('../helper')

class TestGeneratorsInRactor < Test::Unit::TestCase
  include(ULIDHelpers)
  include(ULIDAssertions)

  MONOTONIC_GENERATOR = ULID::MonotonicGenerator.new

  def test_generators_works_even_in_multiple_ractors
    alllow_warning(/Ractor is experimental, and the behavior may change in future versions of Ruby!/) do
      ractors = 10.times.map do
        Ractor.new do
          [*(Array.new(500) { ULID.generate }), *ULID.sample(500)]
        end
      end
      ulids = ractors.flat_map(&:take)
      assert_equal(10000, ulids.size)
      assert_equal(ulids, ulids.uniq)
      assert_acceptable_randomized_string(ulids)
    end
  end

  def test_monotonic_generator_works_in_single_ractor
    alllow_warning(/Ractor is experimental, and the behavior may change in future versions of Ruby!/) do
      ulids = Ractor.new do
        monotonic_generator = ULID::MonotonicGenerator.new
        Array.new(1000) { monotonic_generator.generate }
      end.take
      assert_equal(1000, ulids.size)
      assert_equal(ulids, ulids.sort.uniq)
      assert_acceptable_randomized_string(ulids)
    end
  end

  def test_ractor_cant_use_outer_monotonic_generator
    alllow_warning(/Ractor is experimental, and the behavior may change in future versions of Ruby!/) do
      assert_instance_of(
        Ractor::IsolationError,
        Ractor.new do
          begin
            MONOTONIC_GENERATOR
          rescue Exception => err
            err
          else
            'should not reach here'
          end
        end.take
      )
    end
  end
end
