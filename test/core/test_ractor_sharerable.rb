# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestRactorSharable < Test::Unit::TestCase
  ULID_CLASS = ULID
  ULID_FROZEN_INSTANCE = ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3').freeze
  ULID_INSTANCE = ULID.parse(ULID_FROZEN_INSTANCE.to_s)
  MONOTONIC_GENERATOR = ULID::MonotonicGenerator.new

  def setup
    @warning_original_experimental = Warning[:experimental]
    Warning[:experimental] = false
  end

  def test_sharerable
    return unless RUBY_VERSION >= '3.0'

    assert_true(Ractor.shareable?(ULID_CLASS))
    assert_false(ULID_CLASS.frozen?)
    assert_true(Ractor.shareable?(ULID_FROZEN_INSTANCE))
    assert_false(Ractor.shareable?(ULID_INSTANCE))
    assert_false(Ractor.shareable?(MONOTONIC_GENERATOR))

    assert_instance_of(ULID, Ractor.new { ULID_CLASS.generate }.take)
    assert_equal('01F4GNAV5ZR6FJQ5SFQC7WDSY3', Ractor.new { ULID_FROZEN_INSTANCE.to_s }.take)

    # FIX ME: Suppress error reports as `#<Thread:0x00007f63ca3d54e8 run> terminated with exception (report_on_exception is true)`...
    #         However I think It can't be suppressed with `report_on_exception=` of inner thread
    assert_raise(Ractor::RemoteError) do
      Ractor.new do
        ULID_INSTANCE.to_s
      end.take
    end

    assert_raise(Ractor::RemoteError) do
      Ractor.new do
        MONOTONIC_GENERATOR.generate
      end.take
    end
  end

  def teardown
    Warning[:experimental] = @warning_original_experimental
  end
end
