# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestRactorShareable < Test::Unit::TestCase
  ULID_CLASS = ULID
  ULID_FROZEN_INSTANCE = ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3').freeze
  ULID_INSTANCE = ULID.parse(ULID_FROZEN_INSTANCE.to_s)
  MONOTONIC_GENERATOR = ULID::MonotonicGenerator.new

  def setup
    @warning_original_experimental = Warning[:experimental]
    Warning[:experimental] = false
  end

  def test_shareable
    return unless RUBY_VERSION >= '3.0'

    assert_true(Ractor.shareable?(ULID_CLASS))
    assert_false(ULID_CLASS.frozen?)
    assert_false(Ractor.shareable?(ULID_INSTANCE))
    assert_false(Ractor.shareable?(MONOTONIC_GENERATOR))

    if RUBY_VERSION >= '3.1'
      assert_true(Ractor.shareable?(ULID_FROZEN_INSTANCE))
      assert_equal('01F4GNAV5ZR6FJQ5SFQC7WDSY3', Ractor.new { ULID_FROZEN_INSTANCE.to_s }.take)
    else
      assert_false(Ractor.shareable?(ULID_FROZEN_INSTANCE))
    end

    assert_instance_of(ULID, Ractor.new { ULID_CLASS.generate }.take)

    assert_instance_of(
      Ractor::IsolationError,
      Ractor.new do
        begin
          ULID_INSTANCE
        rescue Exception => err
          err
        else
          'should not reach here'
        end
      end.take
    )

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

  def teardown
    Warning[:experimental] = @warning_original_experimental
  end
end
