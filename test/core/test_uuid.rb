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
      Subclass.from_uuid_v4(SecureRandom.uuid_v4)
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

    # UUIDv3, v5 - Not officially supported in this gem, but I expect it also works
    assert_equal(ULID.parse('3BMYW117DD278R1D00R17X8C68'), ULID.from_uuidish('6ba7b810-9dad-11d1-80b4-00c04fd430c8'))

    # UUID v7
    assert_equal(ULID.parse('01JHQSXFTRFFHRZN260SG6P1DA'), ULID.from_uuidish('01946f9e-bf58-7be3-8fd4-4606606b05aa'))

    # Rough tests
    ulids = 1000.times.map do
      [
        ULID.from_uuidish(SecureRandom.uuid_v4),
        ULID.from_uuidish(SecureRandom.uuid_v7)
      ]
    end.flatten
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
      assert_equal('should pass a string for UUID parser', err.message)
    end
  end

  def test_from_uuid_v4
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuid_v4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))
    assert_equal(ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS'), ULID.from_uuid_v4('urn:uuid:0983d0a2-ff15-4d83-8f37-7dd945b5aa39'))

    # Rough tests
    ulids = 1000.times.map do
      ULID.from_uuid_v4(SecureRandom.uuid_v4)
    end
    assert_true(ulids.uniq == ulids)

    # Ensure some invalid patterns
    [
      '6ba7b810-9dad-11d1-80b4-00c04fd430c8', # UUIDv3, v5
      '01946f9e-bf58-7be3-8fd4-4606606b05aa', # UUIDv7
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa3', # Shortage
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa390', # Excess
      "0983d0a2-ff15-4d83-8f37-7dd945b5aa39\n", # Line end
      '0983d0a2-ff15-4d83-8f37--7dd945b5aa39' # `-` excess
    ].each do |invalid_uuidv4|
      assert_raises(ULID::ParserError) do
        ULID.from_uuid_v4(invalid_uuidv4)
      end
    end

    assert_raises(ArgumentError) do
      ULID.from_uuid_v4
    end

    [nil, 42, :'0983d0a2-ff15-4d83-8f37-7dd945b5aa39', BasicObject.new, Object.new, ulids.sample].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_uuid_v4(evil)
      end
      assert_equal('should pass a string for UUID parser', err.message)
    end
  end

  def test_from_uuid_v7
    assert_equal(ULID.parse('01JHQSXFTRFFHRZN260SG6P1DA'), ULID.from_uuid_v7('01946f9e-bf58-7be3-8fd4-4606606b05aa'))
    assert_equal(ULID.parse('01JHQSXFTRFFHRZN260SG6P1DA'), ULID.from_uuid_v7('urn:uuid:01946f9e-bf58-7be3-8fd4-4606606b05aa'))

    # Rough tests
    ulids = 1000.times.map do
      ULID.from_uuid_v7(SecureRandom.uuid_v7)
    end
    assert_true(ulids.uniq == ulids)

    # Ensure some invalid patterns
    [
      '6ba7b810-9dad-11d1-80b4-00c04fd430c8', # UUIDv3, v5
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa39', # UUIDv4
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa3', # Shortage
      '0983d0a2-ff15-4d83-8f37-7dd945b5aa390', # Excess
      "0983d0a2-ff15-4d83-8f37-7dd945b5aa39\n", # Line end
      '0983d0a2-ff15-4d83-8f37--7dd945b5aa39' # `-` excess
    ].each do |invalid_uuidv7|
      assert_raises(ULID::ParserError) do
        ULID.from_uuid_v7(invalid_uuidv7)
      end
    end

    assert_raises(ArgumentError) do
      ULID.from_uuid_v7
    end

    [nil, 42, :'0983d0a2-ff15-4d83-8f37-7dd945b5aa39', BasicObject.new, Object.new, ulids.sample].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_uuid_v7(evil)
      end
      assert_equal('should pass a string for UUID parser', err.message)
    end
  end

  def test_uuid_parser_for_boundary_example
    # This behavior is same as https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1 on CPython 3.9.4
    assert_equal(ULID.parse('00000000008008000000000000'), ULID.from_uuid_v4('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ'), ULID.from_uuid_v4('ffffffff-ffff-4fff-bfff-ffffffffffff'))

    # v7
    assert_equal(ULID.parse('0000000000E008000000000000'), ULID.from_uuid_v7('00000000-0000-7000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZFZZVZZZZZZZZZZZZ'), ULID.from_uuid_v7('ffffffff-ffff-7fff-bfff-ffffffffffff'))

    # Also uuidish can load as same as versioned methods
    assert_equal(ULID.parse('00000000008008000000000000'), ULID.from_uuidish('00000000-0000-4000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZ9ZZVZZZZZZZZZZZZ'), ULID.from_uuidish('ffffffff-ffff-4fff-bfff-ffffffffffff'))
    assert_equal(ULID.parse('0000000000E008000000000000'), ULID.from_uuidish('00000000-0000-7000-8000-000000000000'))
    assert_equal(ULID.parse('7ZZZZZZZZZFZZVZZZZZZZZZZZZ'), ULID.from_uuidish('ffffffff-ffff-7fff-bfff-ffffffffffff'))

    # Just ensuring
    assert_not_equal(ULID.min, ULID.from_uuid_v4('00000000-0000-4000-8000-000000000000'))
    assert_not_equal(ULID.min, ULID.from_uuid_v7('00000000-0000-7000-8000-000000000000'))
    assert_not_equal(ULID.max, ULID.from_uuid_v4('ffffffff-ffff-4fff-bfff-ffffffffffff'))
    assert_not_equal(ULID.max, ULID.from_uuid_v7('ffffffff-ffff-7fff-bfff-ffffffffffff'))

    # Min and Max values does not have version and variants, so failed in v4 and v7 parser
    assert_raises(ULID::ParserError) do
      ULID.from_uuid_v4('00000000-0000-0000-0000-000000000000')
    end
    assert_raises(ULID::ParserError) do
      ULID.from_uuid_v7('00000000-0000-0000-0000-000000000000')
    end
    assert_raises(ULID::ParserError) do
      ULID.from_uuid_v4('ffffffff-ffff-ffff-ffff-ffffffffffff')
    end
    assert_raises(ULID::ParserError) do
      ULID.from_uuid_v7('ffffffff-ffff-ffff-ffff-ffffffffffff')
    end

    # But relaxed parser parsed it with ignoring the version and variants specs
    assert_equal(ULID.min, ULID.from_uuidish('00000000-0000-0000-0000-000000000000'))
    assert_equal(ULID.max, ULID.from_uuidish('ffffffff-ffff-ffff-ffff-ffffffffffff'))
  end

  def test_to_uuid_v4_for_typical_example
    # The example value was taken from https://github.com/ahawker/ulid/tree/96bdb1daad7ce96f6db8c91ac0410b66d2e1c4c1#usage
    ulid = ULID.parse('09GF8A5ZRN9P1RYDVXV52VBAHS')
    assert_equal('0983d0a2-ff15-4d83-8f37-7dd945b5aa39', ulid.to_uuid_v4)
    assert_equal('0983d0a2-ff15-4d83-8f37-7dd945b5aa39', ulid.to_uuid_v4(force: false))
    assert_equal(ulid.to_uuid_v4, ulid.to_uuid_v4)
    assert_not_same(ulid.to_uuid_v4, ulid.to_uuid_v4)
    assert_true(ulid.to_uuid_v4.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.to_uuid_v4.encoding)
  end

  # @see https://github.com/kachick/ruby-ulid/issues/76 for further detail
  def test_v4compatible_or_not
    ulid = ULID.parse('2E63N1RV0MW8XNHAFCPQ1Z8E88')
    assert_equal('4e30ea1c-6c14-e23b-58a9-ecb5c3f43908', ulid.to_uuidish)
    assert_equal(ulid, ULID.from_uuidish(ulid.to_uuidish))

    assert_raises(ULID::ParserError) do
      ULID.from_uuid_v4(ulid.to_uuidish)
    end

    assert_raises(ULID::IrreversibleUUIDError) do
      ulid.to_uuid_v4
    end

    assert_equal('4e30ea1c-6c14-423b-98a9-ecb5c3f43908', ulid.to_uuid_v4(force: true))
    assert_equal(ULID.parse('2E63N1RV0M88XSHAFCPQ1Z8E88'), ULID.from_uuid_v4(ulid.to_uuid_v4(force: true)))
    assert_equal(ULID.from_uuidish(ulid.to_uuid_v4(force: true)), ULID.from_uuid_v4(ulid.to_uuid_v4(force: true)))
  end

  def test_to_uuid_v4_for_boundary_example
    assert_equal('00000000-0000-4000-8000-000000000000', ULID.min.to_uuid_v4(force: true))
    assert_equal('ffffffff-ffff-4fff-bfff-ffffffffffff', ULID.max.to_uuid_v4(force: true))

    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.min.to_uuid_v4
    end
    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.max.to_uuid_v4
    end
  end

  def test_to_uuid_v7_for_boundary_example
    assert_equal('00000000-0000-7000-8000-000000000000', ULID.min.to_uuid_v7(force: true))
    assert_equal('ffffffff-ffff-7fff-bfff-ffffffffffff', ULID.max.to_uuid_v7(force: true))

    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.min.to_uuid_v7
    end
    assert_raises(ULID::IrreversibleUUIDError) do
      ULID.max.to_uuid_v7
    end
  end

  def test_uuidv4_compatibility_with_many_random_data
    uuids = 1000.times.map do
      SecureRandom.uuid_v4
    end

    assert_true(uuids.uniq.size == 1000)

    ulids = uuids.map do |uuid|
      ULID.from_uuid_v4(uuid)
    end

    assert_equal(uuids, ulids.map(&:to_uuid_v4))
  end

  def test_uuidv7_compatibility_with_many_random_data
    uuids = 1000.times.map do
      SecureRandom.uuid_v7
    end

    assert_true(uuids.uniq.size == 1000)

    ulids = uuids.map do |uuid|
      ULID.from_uuid_v7(uuid)
    end

    assert_equal(uuids, ulids.map(&:to_uuid_v7))
  end

  # Copied from https://github.com/ruby/securerandom/pull/19/files#diff-02b5465398080c82bddc01774e0d92850f3f39e53b5a79e0706ae12a4ccb4343R113-R124 for testing purpose
  # These feature should be useful for the ID users, however having it is not a role of this gem.
  def get_uuid7_time(uuid, extra_timestamp_bits: 0)
    denominator     = (1 << extra_timestamp_bits) * 1000r
    extra_chars     = extra_timestamp_bits / 4
    last_char_bits  = extra_timestamp_bits % 4
    extra_chars    += 1 if last_char_bits != 0
    timestamp_re    = /\A(\h{8})-(\h{4})-7(\h{#{extra_chars}})/
    timestamp_chars = uuid.match(timestamp_re).captures.join
    timestamp       = timestamp_chars.to_i(16)
    timestamp     >>= 4 - last_char_bits unless last_char_bits == 0
    timestamp      /= denominator
    Time.at(timestamp, in: '+00:00')
  end

  def test_decode_v7_timestamp_typical
    v7 = '01946f9e-bf58-7be3-8fd4-4606606b05aa'
    ulid = ULID.from_uuid_v7(v7)
    assert_equal(get_uuid7_time(v7), ulid.to_time)
  end

  def test_decode_v7_timestamp_for_many
    1000.times do
      v7 = SecureRandom.uuid_v7
      ulid = ULID.from_uuid_v7(v7)
      assert_equal(get_uuid7_time(v7), ulid.to_time)
    end
  end
end
