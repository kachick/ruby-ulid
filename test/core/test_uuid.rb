# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestUUID < Test::Unit::TestCase
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
      assert_true(ULID === instance)
      assert_boolean(ulid == instance)
      assert_boolean(ulid === instance)
      assert_boolean(ulid.eql?(instance))
      assert_boolean(ulid.equal?(instance))
      assert_true([0, 1, -1].include?(ulid <=> instance))
    end
  end

  def test_from_uuidish
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuidish('0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuidish('urn:uuid:0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))

    # UUIDv3, v5
    assert_equal(ULID.parse('3BMYW117DD278R1D00R17X8C68'), ULID.from_uuidish('6ba7b810-9dad-11d1-80b4-00c04fd430c8'))

    # Rough tests
    ulids = 1000.times.map do
      ULID.from_uuidish(SecureRandom.uuid)
    end
    assert_true(ulids.uniq == ulids)

    # Ensure some invalid patterns (I'd like to add more examples)
    [
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa3', # Shortage
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa390', # Excess
      "0983d0a2-ff15-4d83-8f37-7dd945b5aa39\n", # Line end
      '0983d0a2-ff15-4d83-8f37--7dd945b5aa39' # `-` excess
    ].each do |invalid_uuid|
      assert_raises(ULID::ParserError) do
        ULID.from_uuidish(invalid_uuid)
      end
    end

    assert_raises(ArgumentError) do
      ULID.from_uuidish
    end

    [nil, 42, :'0983d0a2-ff15-4d83-8f37-7dd945b5aa39', BasicObject.new, Object.new, ulids.sample].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_uuidish(evil)
      end
      assert_equal('ULID.from_uuidish takes only strings', err.message)
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
    assert_true(ulids.uniq == ulids)

    # Ensure some invalid patterns (I'd like to add more examples)
    [
      '6ba7b810-9dad-11d1-80b4-00c04fd430c8', # UUIDv3, v5
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

  def test_uuid_parser_for_boundary_example
    # This behavior is same as https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1 on CPython 3.9.4
    assert_equal(ULID.parse('00000000008008000000000000'), ULID.from_uuidv4('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ'), ULID.from_uuidv4('ffffffff-ffff-4fff-bfff-ffffffffffff'))

    # Also uuidish can load as same
    assert_equal(ULID.parse('00000000008008000000000000'), ULID.from_uuidish('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ'), ULID.from_uuidish('ffffffff-ffff-4fff-bfff-ffffffffffff'))

    # Just ensuring
    assert_not_equal(ULID.min, ULID.from_uuidv4('00000000-0000-4000-8000-000000000000'))
    assert_not_equal(ULID.max, ULID.from_uuidv4('ffffffff-ffff-4fff-bfff-ffffffffffff'))

    # Min and Max values does not have version and variants, so failed in v4 parser
    assert_raises(ULID::ParserError) do
      ULID.from_uuidv4('00000000-0000-0000-0000-000000000000')
    end
    assert_raises(ULID::ParserError) do
      ULID.from_uuidv4('ffffffff-ffff-ffff-ffff-ffffffffffff')
    end

    # But relaxed parser parsed it with ignoring the version and variants specs
    assert_equal(ULID.min, ULID.from_uuidish('00000000-0000-0000-0000-000000000000'))
    assert_equal(ULID.max, ULID.from_uuidish('ffffffff-ffff-ffff-ffff-ffffffffffff'))
  end

  def test_to_uuidv4_for_typical_example
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    ulid = ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS')
    assert_equal('0983d0a2-ff15-4d83-8f37-7dd945b5aa39', ulid.to_uuidv4)
    assert_equal('0983d0a2-ff15-4d83-8f37-7dd945b5aa39', ulid.to_uuidv4(ignore_reversible: false))
    assert_equal(ulid.to_uuidv4, ulid.to_uuidv4)
    assert_not_same(ulid.to_uuidv4, ulid.to_uuidv4)
    assert_true(ulid.to_uuidv4.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.to_uuidv4.encoding)
  end

  def test_to_uuidv4_for_boundary_example
    assert_equal('00000000-0000-4000-8000-000000000000', ULID.min.to_uuidv4(ignore_reversible: true))
    assert_equal('ffffffff-ffff-4fff-bfff-ffffffffffff', ULID.max.to_uuidv4(ignore_reversible: true))

    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.min.to_uuidv4
    end
    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.max.to_uuidv4
    end
  end

  def test_uuidv4_compatibility_with_many_random_data
    # Rough tests
    uuids = 10000.times.map do
      SecureRandom.uuid
    end

    assert_true(uuids.uniq.size == 10000)

    ulids = uuids.map do |uuid|
      ULID.from_uuidv4(uuid)
    end

    assert_equal(uuids, ulids.map(&:to_uuidv4))
  end

  def test_to_uuidv4_on_frozen_ulid
    assert_equal('01563e3a-b5d3-4676-8c61-efb99302bd5b', ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').freeze.to_uuidv4(ignore_reversible: true))
  end
end
