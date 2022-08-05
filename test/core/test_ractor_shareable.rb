# coding: utf-8
# frozen_string_literal: true

return unless RUBY_VERSION >= '3.0'

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

  def test_signature
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

  def test_instances_are_can_be_shareable
    ulid = ULID.generate
    Ractor.make_shareable(ulid)
    assert_true(Ractor.shareable?(ulid))
  end


  const_name_to_value = ULID.constants.to_h { |const_name| [const_name, ULID.const_get(const_name)] }
  raise unless const_name_to_value.size >= 10
  const_name_to_value.each_pair do |name, value|
    data(name.to_s, value)
  end
  def test_shareable_constants(const_value)
    assert_true(Ractor.shareable?(const_value))

    unless const_value.kind_of?(Module)
      assert_true(const_value.frozen?)
    end
  end

  def teardown
    Warning[:experimental] = @warning_original_experimental
  end
end
