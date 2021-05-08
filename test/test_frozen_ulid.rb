# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestFrozenULID < Test::Unit::TestCase
  def setup
    @string = '01ARZ3NDEKTSV4RRFFQ69G5FAV'
    @ulid = ULID.parse(@string)
    @ulid.freeze
    @min = ULID.min.freeze
    @max = ULID.max.freeze
  end

  def test_instance_variables
    @ulid.instance_variables.each do |name|
      ivar = @ulid.instance_variable_get(name)
      assert_equal(true, !!ivar, "#{name} is still falsy: #{ivar.inspect}")
      assert_equal(true, ivar.frozen?, "#{name} is not frozen")
    end
  end

  def test_inspect
    assert_equal('ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)', @ulid.inspect)
  end

  def test_to_i
    assert_equal(1777027686520646174104517696511196507, @ulid.to_i)
  end

  def test_to_time
    assert_equal(Time.at(0, 1469922850259, :millisecond).utc, @ulid.to_time)
  end

  def test_octets
    assert_equal([1, 86, 62, 58, 181, 211, 214, 118, 76, 97, 239, 185, 147, 2, 189, 91], @ulid.octets)
  end

  def test_next
    assert_equal(true, @ulid < @ulid.next)
    assert_nil(@max.next)
  end

  def test_succ
    assert_equal(true, @ulid < @ulid.succ)
    assert_nil(@max.succ)
  end

  def test_pred
    assert_equal(true, @ulid > @ulid.pred)
    assert_nil(@min.pred)
  end

  def test_timestamp
    assert_equal('01ARZ3NDEK', @ulid.timestamp)
  end

  def test_randomness
    assert_equal('TSV4RRFFQ69G5FAV', @ulid.randomness)
  end

  def test_patterns
    assert_instance_of(Hash, @ulid.patterns)
  end
end
