# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

# Just to confirm `current behavior` for some testing reasons. Basically does not support subclass behaviors.
class TestULIDSubClass < Test::Unit::TestCase
  class Subclass < ULID
  end

  def setup
    @actual_timezone = ENV.fetch('TZ', nil)
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
  end

  def test_generators_return_own_instance_and_does_not_raise_in_some_basic_comparison
    ulid = ULID.sample
    [
      Subclass.sample,
      Subclass.generate,
      Subclass.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'),
      Subclass.at(Time.now),
      Subclass.from_integer(42),
      Subclass.scan('01ARZ3NDEKTSV4RRFFQ69G5FAV').first
    ].each do |instance|
      assert_not_instance_of(ULID, instance)
      assert_instance_of(Subclass, instance)
      assert_true(ULID === instance)
      assert_boolean(ulid == instance)
      assert_boolean(ulid === instance)
      assert_boolean(ulid.eql?(instance))
      assert_boolean(ulid.equal?(instance))
      assert_true([0, 1, -1].include?(ulid <=> instance))
    end
  end

  def test_comparisons_do_not_return_true_even_if_same_value_except_object_identifier
    ulid1 = ULID.generate
    ulid2 = ULID.generate
    ulid1_sub = Subclass.parse(ulid1.to_s)

    # This is an exception for comparison. Because same checks different objects
    assert_equal(false, ulid1.equal?(ulid1_sub))
    assert_equal(false, ulid1_sub.equal?(ulid1))

    # This should return false. Because having different value
    assert_equal(false, ulid2 == ulid1_sub)
    assert_equal(false, ulid1_sub == ulid2)
    assert_equal(false, ulid2.eql?(ulid1_sub))
    assert_equal(false, ulid1_sub.eql?(ulid2))

    assert_true(ulid1 == ulid1_sub)
    assert_true(ulid1_sub == ulid1)
    assert_true(ulid1.eql?(ulid1_sub))
    assert_true(ulid1_sub.eql?(ulid1))

    assert_equal(ulid1.hash, ulid1_sub.hash)
    assert_not_equal(ulid2.hash, ulid1_sub.hash)

    hash = {
      ulid1 => :ulid1,
      ulid1_sub => :ulid1_sub,
      ulid2 => :ulid2
    }

    assert_equal([:ulid1_sub, :ulid2], hash.values)
    assert_equal(:ulid1_sub, hash.fetch(ulid1))
    assert_equal(:ulid1_sub, hash.fetch(ulid1_sub))
    assert_equal(:ulid2, hash.fetch(ulid2))
  end

  def test_succ_pred_returns_original_class
    instance = Subclass.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(ULID, instance.succ)
    assert_instance_of(ULID, instance.pred)
  end

  def test_to_ulid
    instance = Subclass.sample
    assert_instance_of(Subclass, instance)
    assert_same(instance, instance.to_ulid)
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
