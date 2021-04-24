# coding: us-ascii
# frozen_string_literal: true

require_relative 'helper'

class TestULID < Test::Unit::TestCase
  def test_parse
    parsed = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(ULID, parsed)
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', parsed.to_s)
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase).to_s)

    assert_raises(ULID::ParserError) do
      ULID.parse(nil)
    end

    assert_raises(ULID::ParserError) do
      ULID.parse('')
    end

    assert_raises(ULID::ParserError) do
      ULID.parse("01ARZ3NDEKTSV4RRFFQ69G5FAV\n")
    end

    assert_raises(ULID::ParserError) do
      ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAU')
    end
  end

  def test_valid?
    assert_equal(false, ULID.valid?(nil))
    assert_equal(false, ULID.valid?(''))
    assert_equal(false, ULID.valid?("01ARZ3NDEKTSV4RRFFQ69G5FAV\n"))
    assert_equal(false, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAU'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID.valid?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID.valid?('80000000000000000000000000'))
  end

  def test_overflow
    max = ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ')
    assert_equal(ULID::MAX_MILLISECONDS, max.milliseconds)
    assert_equal(ULID::MAX_RANDOMNESS, max.entropy)

    assert_raises(ULID::OverflowError) do
      max.next
    end

    assert_raises(ULID::OverflowError) do
      ULID.parse('80000000000000000000000000')
    end
  end

  def test_generate
    assert_instance_of(ULID, ULID.generate)
    assert_not_equal(ULID.generate, ULID.generate)
  end

  def test_monotonic_generate
    # @TODO: Add tests for same milliseconds
    assert_instance_of(ULID, ULID.monotonic_generate)
    assert_not_equal(ULID.monotonic_generate, ULID.monotonic_generate)
    first = ULID.monotonic_generate
    second = ULID.monotonic_generate
    assert_equal(true, second > first)
  end

  def test_eq
    assert_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_same(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
  end

  def test_sortable
    assert_equal(true, ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ') > ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
  end

  def test_to_s
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ulid.to_s)
    assert_same(ulid.to_s, ulid.to_s)
    assert_equal(true, ulid.to_s.frozen?)
  end

  def test_inspect
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)', ulid.inspect)
    assert_same(ulid.inspect, ulid.inspect)
    assert_equal(true, ulid.inspect.frozen?)
    assert_not_equal(ulid.to_s, ulid.inspect)
  end

  def test_hash_key
    ulid1_1 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid1_2 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid2 =  ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ')

    hash = { 
      ulid1_1 => :ulid1_1,
      ulid1_2 => :ulid1_2,
      ulid2 => :ulid2
    }

    assert_equal([:ulid1_2, :ulid2], hash.values)
  end

  def test_to_time
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(Time.at(0, 1469922850259, :millisecond).utc, ulid.to_time)
    assert_same(ulid.to_time, ulid.to_time)
  end

  def test_next
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(ulid.next.to_i, ulid.to_i + 1)
    assert_instance_of(ULID, ulid.next)
    assert_same(ulid.next, ulid.next)
  end
end
