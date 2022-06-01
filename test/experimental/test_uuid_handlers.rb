# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')
require_relative('../../lib/ulid/uuid')

class TestUUIDHandlers < Test::Unit::TestCase
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
      Subclass.from_uuidv4(SecureRandom.uuid)
    ].each do |instance|
      assert_not_instance_of(ULID, instance)
      assert_instance_of(Subclass, instance)
      assert_equal(true, ULID === instance)
      assert_boolean(ulid == instance)
      assert_boolean(ulid === instance)
      assert_boolean(ulid.eql?(instance))
      assert_boolean(ulid.equal?(instance))
      assert_equal(true, [0, 1, -1].include?(ulid <=> instance))
    end
  end

  def test_from_uuidv4
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuidv4('urn:uuid:0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))

    # Rough tests
    ulids = 1000.times.map do
      ULID.from_uuidv4(SecureRandom.uuid)
    end
    assert_equal(true, ulids.uniq == ulids)

    # Ensure some invalid patterns (I'd like to add more examples)
    [
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa3', # Shortage
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa390', # Excess
      "0983d0a2-ff15-4d83-8f37-7dd945b5aa39\n", # Line end
      '0983d0a2-ff15-4d83-8f37--7dd945b5aa39' # `-` excess
    ].each do |invalid_uuidv4|
      assert_raises(ULID::ParserError) do
        ULID.from_uuidv4(invalid_uuidv4)
      end
    end

    assert_raises(ArgumentError) do
      ULID.from_uuidv4
    end

    [nil, 42, :'0983d0a2-ff15-4d83-8f37-7dd945b5aa39', BasicObject.new, Object.new, ulids.sample].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_uuidv4(evil)
      end
      assert_equal('ULID.from_uuidv4 takes only strings', err.message)
    end
  end

  def test_from_uuidv4_for_boundary_example
    # This behavior is same as https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1 on CPython 3.9.4
    assert_equal(ULID.parse('00000000008008000000000000'), ULID.from_uuidv4('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ'), ULID.from_uuidv4('ffffffff-ffff-4fff-bfff-ffffffffffff'))

    omit('Below cases might be correct behavior rather than above, to handle the `V4` specifying. Considering in https://github.com/kachick/ruby-ulid/issues/76')
    assert_equal(ULID.min, ULID.from_uuidv4('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.max, ULID.from_uuidv4('ffffffff-ffff-4fff-bfff-ffffffffffff'))
  end

  def test_to_uuidv4_for_typical_example
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    ulid = ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS')
    assert_equal('0983d0a2-ff15-4d83-8f37-7dd945b5aa39', ulid.to_uuidv4)
    assert_equal(ulid.to_uuidv4, ulid.to_uuidv4)
    assert_not_same(ulid.to_uuidv4, ulid.to_uuidv4)
    assert_equal(true, ulid.to_uuidv4.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.to_uuidv4.encoding)
  end

  def test_to_uuidv4_for_boundary_example
    assert_equal('00000000-0000-4000-8000-000000000000', ULID.min.to_uuidv4)
    assert_equal('ffffffff-ffff-4fff-bfff-ffffffffffff', ULID.max.to_uuidv4)

    omit('Below cases might be correct behavior rather than above, to handle the `V4` specifying. Considering in https://github.com/kachick/ruby-ulid/issues/76')
    assert_raises do
      ULID.min.to_uuidv4
    end
    assert_raises do
      ULID.max.to_uuidv4
    end
  end

  def test_uuidv4_compatibility_with_many_random_data
    # Rough tests
    uuids = 10000.times.map do
      SecureRandom.uuid
    end

    assert_equal(true, uuids.uniq.size == 10000)

    ulids = uuids.map do |uuid|
      ULID.from_uuidv4(uuid)
    end

    assert_equal(uuids, ulids.map(&:to_uuidv4))
  end

  def test_to_uuidv4_on_frozen_ulid
    assert_equal('01563e3a-b5d3-4676-8c61-efb99302bd5b', ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').freeze.to_uuidv4)
  end
end
