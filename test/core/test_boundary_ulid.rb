# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestBoundaryULID < Test::Unit::TestCase
  def setup
    @min = ULID.min
    @max = ULID.max
    @min_entropy = ULID.parse('01BX5ZZKBK0000000000000000')
    @max_entropy = ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZZ')
  end

  def test_consistency_with_constants
    assert_equal(ULID::MAX_MILLISECONDS, @max.milliseconds)
    assert_equal(ULID::MAX_ENTROPY, @max.entropy)
    assert_equal(ULID::MAX_INTEGER, @max.to_i)
    assert_equal(0, @min.milliseconds)
    assert_equal(0, @min.entropy)
    assert_equal(0, @min.to_i)
  end

  def test_plus
    assert_nil(@max + 1)
    assert_equal(ULID.parse('01BX5ZZKBM0000000000000000'), @max_entropy + 1)
    assert_same(@max, ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZY') + 1)
  end

  def test_minus
    assert_nil(@min - 1)
    assert_equal(ULID.parse('01BX5ZZKBJZZZZZZZZZZZZZZZZ'), @min_entropy - 1)
    assert_same(@min, ULID.parse('00000000000000000000000001') - 1)
  end

  def test_next
    assert_nil(@max.next)
    assert_equal(ULID.parse('01BX5ZZKBM0000000000000000'), @max_entropy.next)
    assert_same(@max, ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZY').next)
  end

  def test_pred
    assert_nil(@min.pred)
    assert_equal(ULID.parse('01BX5ZZKBJZZZZZZZZZZZZZZZZ'), @min_entropy.pred)
    assert_same(@min, ULID.parse('00000000000000000000000001').pred)
  end
end
