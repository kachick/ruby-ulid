# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDMonotonicGenerator < Test::Unit::TestCase
  def setup
    @generator = ULID::MonotonicGenerator.new
  end

  def test_multiple_instance
    assert_not_same(ULID::MonotonicGenerator.new, ULID::MonotonicGenerator.new)
  end

  def test_interface
    assert_instance_of(ULID::MonotonicGenerator, @generator)
    first = @generator.generate
    assert_instance_of(ULID, first)
    second = @generator.generate
    assert_not_equal(second, first)
    assert_true(second > first)
    third_string = @generator.encode
    assert_instance_of(String, third_string)
    assert_true(ULID.normalized?(third_string))
    fourth_string = @generator.encode
    assert_not_equal(fourth_string, third_string)
    assert_true(fourth_string > third_string)
    assert_equal(
      [first.encode, second.encode, third_string, fourth_string],
      [first.encode, second.encode, third_string, fourth_string].shuffle.sort
    )
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

  def test_generate_ignores_lower_moment_than_prev_is_given
    first = @generator.generate(moment: 42)
    second = @generator.generate(moment: 41)
    assert_equal(second.to_time, first.to_time)
    assert_equal(second.entropy, first.entropy.next)
  end

  def test_generate_raises_overflow_when_called_on_max_entropy
    max_ulid_in_a_milliseconds = ULID.max(Time.now)

    @generator.__send__(:rewind, prev_ulid: max_ulid_in_a_milliseconds.pred)

    assert_equal(max_ulid_in_a_milliseconds, @generator.generate(moment: max_ulid_in_a_milliseconds.milliseconds))

    @generator.__send__(:rewind)

    @generator.__send__(:rewind, prev_ulid: max_ulid_in_a_milliseconds)

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

  def test_prev
    assert_nil(@generator.prev)

    ulid1 = @generator.generate
    assert_equal(ulid1, @generator.prev)
    ulid2 = @generator.generate
    assert_equal(ulid2, @generator.prev)
  end

  def test_inspect
    assert_equal('ULID::MonotonicGenerator(prev: nil)', @generator.inspect)
    assert_not_same(@generator.inspect, @generator.inspect)

    ulid = @generator.generate

    assert_equal("ULID::MonotonicGenerator(prev: #{ulid.inspect})", @generator.inspect)
  end
end
