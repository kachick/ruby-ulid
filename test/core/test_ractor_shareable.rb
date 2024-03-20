# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestRactorShareable < Test::Unit::TestCase
  ULID_CLASS = ULID
  ULID_INSTANCE = ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3')
  MONOTONIC_GENERATOR = ULID::MonotonicGenerator.new

  def test_signature
    assert_true(Ractor.shareable?(ULID_CLASS))
    assert_false(ULID_CLASS.frozen?)
    assert_true(Ractor.shareable?(ULID_INSTANCE))
    assert_false(Ractor.shareable?(MONOTONIC_GENERATOR))

    allow_warning(/Ractor is experimental, and the behavior may change in future versions of Ruby!/) do
      assert_equal('01F4GNAV5ZR6FJQ5SFQC7WDSY3', Ractor.new { ULID_INSTANCE.to_s }.take)

      assert_instance_of(ULID, Ractor.new { ULID_CLASS.generate }.take)

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

  def test_instances_are_can_be_shareable
    ulid = ULID.generate
    Ractor.make_shareable(ulid)
    assert_true(Ractor.shareable?(ulid))
  end

  const_name_to_value = ULID.constants.to_h { |const_name| [const_name, ULID.const_get(const_name)] }
  raise unless const_name_to_value.size >= 10

  data(const_name_to_value)
  def test_shareable_constants(const_value)
    assert_true(Ractor.shareable?(const_value))

    unless const_value.kind_of?(Module)
      assert_true(const_value.frozen?)
    end
  end
end
