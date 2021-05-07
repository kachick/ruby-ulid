# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestULIDInstance < Test::Unit::TestCase
  def setup
    @actual_timezone = ENV['TZ']
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
    assert_raise(NoMethodError) do
      ULID.sample.to_uuidv4
    end
  end

  def test_timestamp
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEK', ulid.timestamp)
    assert_instance_of(String, ulid.timestamp)
    assert_same(ulid.timestamp, ulid.timestamp)
    assert_equal(true, ulid.timestamp.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.timestamp.encoding)
  end

  def test_randomness
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('TSV4RRFFQ69G5FAV', ulid.randomness)
    assert_instance_of(String, ulid.randomness)
    assert_same(ulid.randomness, ulid.randomness)
    assert_equal(true, ulid.randomness.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.randomness.encoding)
  end

  def test_patterns
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(Hash, ulid.patterns)
    assert_not_same(ulid.patterns, ulid.patterns)
    assert_equal(false, ulid.patterns.frozen?)
    ulid.patterns.each_pair do |key, pattern|
      assert_equal(Encoding::US_ASCII, pattern.encoding)
      assert_instance_of(Symbol, key)
      assert_instance_of(Regexp, pattern) #=> Might be added String pattern
    end
    assert_equal(
      {
        named_captures: /(?<timestamp>01ARZ3NDEK)(?<randomness>TSV4RRFFQ69G5FAV)/i,
        strict_named_captures: /\A(?<timestamp>01ARZ3NDEK)(?<randomness>TSV4RRFFQ69G5FAV)\z/i
      },
      ulid.patterns
    )
  end

  def test_pattern
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(Regexp, ulid.pattern)
    assert_not_same(ulid.pattern, ulid.pattern)
    assert_equal(true, ulid.pattern.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.pattern.encoding)
    assert_equal(true, ulid.pattern.casefold?)
    assert_equal(true, ulid.pattern.match?(ulid.to_s))
    assert_equal(true, ulid.pattern.match?(ulid.to_s + "\n"))
    assert_equal(true, ulid.pattern.match?(ulid.to_s.downcase))
    assert_equal(false, ulid.pattern.match?(ulid.next.to_s))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ulid.pattern.match(ulid.to_s + "\n").named_captures)
  end

  def test_strict_pattern
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(Regexp, ulid.strict_pattern)
    assert_not_same(ulid.strict_pattern, ulid.strict_pattern)
    assert_equal(true, ulid.strict_pattern.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.strict_pattern.encoding)
    assert_equal(true, ulid.strict_pattern.casefold?)
    assert_equal(true, ulid.strict_pattern.match?(ulid.to_s))
    assert_equal(false, ulid.strict_pattern.match?(ulid.to_s + "\n"))
    assert_equal(true, ulid.strict_pattern.match?(ulid.to_s.downcase))
    assert_equal(false, ulid.strict_pattern.match?(ulid.next.to_s))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ulid.strict_pattern.match(ulid.to_s).named_captures)
  end

  def test_eq
    assert_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_s, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_same(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))

    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', 42, Time.now].each do |not_comparable|
      assert_equal(false, ulid == not_comparable)
    end
  end

  def test_eqq
    assert_equal(true, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(false, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').next)
    assert_equal(true, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === '01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(true, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === '01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase)
    assert_equal(false, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').next.to_s)
    assert_equal(false, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === '')
    assert_equal(false, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === nil)
    assert_equal(false, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV') === BasicObject.new)

    grepped = [
      typical_string = '01ARZ3NDEKTSV4RRFFQ69G5FAV',
      downcased_string = typical_string.downcase,
      typical_object = ULID.parse(typical_string),
      ULID.parse(typical_string).next,
      '',
      nil
    ].grep(ULID.parse(typical_string))
    assert_equal(
      [
        typical_string,
        downcased_string,
        typical_object
      ],
      grepped
    )
  end

  def test_cmp
    ulid = ULID.sample
    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', 42, Time.now].each do |not_comparable|
      assert_nil(ulid <=> not_comparable)
    end
  end

  def test_sortable
    assert_equal(true, ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ') > ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
  end

  def test_lexicographically_sortable
    ulids = 10000.times.map do
      ULID.generate
    end
    assert_equal(ulids.map(&:to_s).sort, ulids.sort.map(&:to_s))
  end

  def test_to_s
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ulid.to_s)
    assert_same(ulid.to_s, ulid.to_s)
    assert_equal(true, ulid.to_s.frozen?)
  end

  def test_inspect
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)', ulid.inspect)
    assert_same(ulid.inspect, ulid.inspect)
    assert_equal(true, ulid.inspect.frozen?)
    assert_not_equal(ulid.to_s, ulid.inspect)
    assert_equal(Encoding::US_ASCII, ulid.inspect.encoding)
  end

  def test_to_i
    assert_equal(1777027686520646174104517696511196507, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_i)
  end

  def test_hash_key
    ulid1_1 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid1_2 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid2 =  ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ')

    hash = { 
      ulid1_1 => :ulid1_1,
      ulid1_2 => :ulid1_2,
      ulid2 => :ulid2
    }

    assert_equal([:ulid1_2, :ulid2], hash.values)
    assert_equal(:ulid1_2, hash.fetch(ulid1_1))
    assert_equal(:ulid2, hash.fetch(ulid2))
  end

  def test_to_time
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    time = ulid.to_time
    assert_equal(Time.at(0, 1469922850259, :millisecond).utc, time)
    assert_equal(true, time.utc?)
    assert_same(ulid.to_time, time)
    assert_equal(true, time.frozen?)

    assert_raises(FrozenError) do
      time.localtime(time.utc_offset.succ)
    end
  end

  def test_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([1, 86, 62, 58, 181, 211, 214, 118, 76, 97, 239, 185, 147, 2, 189, 91], ulid.octets)
    assert_same(ulid.octets, ulid.octets)
    assert_equal(true, ulid.octets.frozen?)
  end

  def test_timestamp_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([1, 86, 62, 58, 181, 211], ulid.timestamp_octets)
    assert_same(ulid.timestamp_octets, ulid.timestamp_octets)
    assert_equal(true, ulid.timestamp_octets.frozen?)
  end

  def test_randomness_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([214, 118, 76, 97, 239, 185, 147, 2, 189, 91], ulid.randomness_octets)
    assert_same(ulid.randomness_octets, ulid.randomness_octets)
    assert_equal(true, ulid.randomness_octets.frozen?)
  end

  def test_next
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(ulid.next.to_i, ulid.to_i + 1)
    assert_instance_of(ULID, ulid.next)
    assert_same(ulid.next, ulid.next)

    first = ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRY')
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), first.next)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVS0'), first.next.next)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVS1'), first.next.next.next)
  end

  def test_pred
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(ulid.pred.to_i, ulid.to_i - 1)
    assert_instance_of(ULID, ulid.pred)
    assert_same(ulid.pred, ulid.pred)

    first = ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR2')
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR1'), first.pred)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR0'), first.pred.pred)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVQZ'), first.pred.pred.pred)
  end

  def test_freeze
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(false, ulid.frozen?)
    assert_same(ulid, ulid.freeze)
    assert_equal(true, ulid.frozen?)
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
