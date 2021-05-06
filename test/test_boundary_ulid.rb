# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestBoundaryULID < Test::Unit::TestCase
  def setup
    @min = ULID.min
    @max = ULID.max
    @min_entropy = ULID.parse('01BX5ZZKBK0000000000000000')
    @max_entropy = ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZZ')
  end

  def test_constants
    assert_equal(ULID::MAX_MILLISECONDS, @max.milliseconds)
    assert_equal(ULID::MAX_ENTROPY, @max.entropy)
    assert_equal(ULID::MAX_INTEGER, @max.to_i)
  end

  def test_next
    assert_nil(@max.next)
    assert_equal(ULID.parse('01BX5ZZKBM0000000000000000'), @max_entropy.next)
  end

  def test_pred
    assert_nil(@min.pred)
    assert_equal(ULID.parse('01BX5ZZKBJZZZZZZZZZZZZZZZZ'), @min_entropy.pred)
  end

  def test_octets
    assert_equal([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], @min.octets)
    assert_equal([255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255], @max.octets)
  end
end
