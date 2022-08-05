# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDInstance < Test::Unit::TestCase
  def setup
    @actual_timezone = ENV.fetch('TZ', nil)
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
    assert_raise(NoMethodError) do
      ULID.sample.to_uuidv4
    end
  end

  def test_exposed_methods
    assert_equal(
      [
        :<=>,
        :==,
        :===,
        :encode,
        :entropy,
        :eql?,
        :hash,
        :inspect,
        :marshal_dump,
        :marshal_load,
        :milliseconds,
        :next,
        :octets,
        :patterns,
        :pred,
        :randomness,
        :randomness_octets, # dislike this name. However providing octets class sounds overdo...
        :timestamp_octets, # dislike this too!
        :succ,
        :timestamp,
        :to_i,
        :to_s,
        :to_time,
        :to_ulid
      ].sort,
      ULID.sample.public_methods(false).sort
    )
  end

  def test_timestamp
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEK', ulid.timestamp)
    assert_instance_of(String, ulid.timestamp)
    assert_not_same(ulid.timestamp, ulid.timestamp)
    assert_equal(ulid.timestamp, ulid.timestamp)
    assert_false(ulid.timestamp.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.timestamp.encoding)
  end

  def test_randomness
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('TSV4RRFFQ69G5FAV', ulid.randomness)
    assert_instance_of(String, ulid.randomness)
    assert_not_same(ulid.randomness, ulid.randomness)
    assert_equal(ulid.randomness, ulid.randomness)
    assert_false(ulid.randomness.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.randomness.encoding)
  end

  def test_patterns
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(Hash, ulid.patterns)
    assert_not_same(ulid.patterns, ulid.patterns)
    assert_false(ulid.patterns.frozen?)
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

  def test_eq
    assert_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_s, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_same(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))

    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', 42, Time.now].each do |not_comparable|
      assert_false(ulid == not_comparable)
    end
  end

  def test_eqq
    typical_string = '01G6Z7Q4RSH97E6QHAC7VK19G2'
    ulid = ULID.parse(typical_string).freeze

    assert_true(ulid === ULID.parse(ulid.to_s))
    assert_true(ulid === ulid.to_s)
    assert_true(ulid === ulid.to_s.downcase)
    assert_true(ulid === [ulid.timestamp, ulid.randomness].join('-'))
    assert_true(ulid === ulid.to_time) # Since 0.4.0

    assert_false(ulid === ulid.pred)
    assert_false(ulid === ulid.next)
    assert_false(ulid === ulid.to_i)
    assert_false(ulid === ulid.timestamp)
    assert_false(ulid === ulid.randomness)
    assert_false(ulid === ulid.milliseconds)
    assert_false(ulid === ulid.entropy)
    assert_false(ulid === ulid.octets)
    assert_false(ulid === ulid.timestamp_octets)
    assert_false(ulid === ulid.randomness_octets)
    assert_false(ulid === ulid.pred.to_s)
    assert_false(ulid === ulid.next.to_s)
    assert_false(ulid === '')
    assert_false(ulid === nil)
    assert_false(ulid === BasicObject.new)

    microseconds = ulid.to_time.to_r * 1000 * 1000
    # Ensure writing correct time handling...
    different_time_even_in_milliseconds_precision = ULID.max(ulid.to_time).succ.to_time
    assert_equal((ulid.to_time.to_r * 1000).to_i + 1, (different_time_even_in_milliseconds_precision.to_r * 1000))
    assert_false(ulid === different_time_even_in_milliseconds_precision)
    assert_equal(ulid.to_time, Time.at(0, microseconds, :microsecond, in: ulid.to_time.zone))
    different_time_however_same_in_milliseconds_precision = Time.at(0, microseconds + 1, :microsecond, in: ulid.to_time.zone)
    assert_not_equal(ulid.to_time, different_time_however_same_in_milliseconds_precision)

    assert_true(ulid === different_time_however_same_in_milliseconds_precision)

    grepped = [
      typical_string,
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
    assert_equal(1, ulid <=> ulid.pred)
    assert_equal(1, ulid <=> ulid.pred.pred.pred)
    assert_equal(0, ulid <=> ULID.parse(ulid.to_s))
    assert_equal(-1, ulid <=> ulid.next)
    assert_equal(-1, ulid <=> ulid.next.next.next)
    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', 42, Time.now].each do |not_comparable|
      assert_nil(ulid <=> not_comparable)
    end
  end

  def test_sortable
    assert_true(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ') > ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
  end

  def test_lexicographically_sortable
    ulids = 10000.times.map do
      ULID.generate
    end
    assert_equal(ulids.map(&:to_s).sort, ulids.sort.map(&:to_s))
  end

  def test_encode
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ulid.encode)
    assert_not_same(ulid.encode, ulid.encode)
    assert_equal(ulid.encode, ulid.encode)
    assert_false(ulid.encode.frozen?)
    assert_not_same(ulid.to_s, ulid.encode)
  end

  def test_to_s
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ulid.to_s)
    assert_not_same(ulid.to_s, ulid.to_s)
    assert_equal(ulid.to_s, ulid.to_s)
    assert_false(ulid.to_s.frozen?)
    assert_not_same(ulid.encode, ulid.to_s)
    assert_equal(ulid.encode, ulid.to_s)
  end

  def test_inspect
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal('ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)', ulid.inspect)
    assert_not_same(ulid.inspect, ulid.inspect)
    assert_equal(ulid.inspect, ulid.inspect)
    assert_false(ulid.inspect.frozen?)
    assert_not_equal(ulid.to_s, ulid.inspect)
    assert_equal(Encoding::US_ASCII, ulid.inspect.encoding)

    # It should keep whole of milliseconds
    assert_equal('ULID(1972-11-26 02:28:08.460 UTC: 002N9NS44C894T5XHJBNDGP6KK)', ULID.parse('002N9NS44C894T5XHJBNDGP6KK').inspect)
  end

  def test_to_i
    assert_equal(1777027686520646174104517696511196507, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_i)
  end

  def test_hash
    ulids = 1000.times.map do
      ULID.generate
    end
    uniq_hashes = ulids.map(&:hash).uniq
    assert_instance_of(Integer, uniq_hashes.first)
    assert_equal(ulids.size, uniq_hashes.size)

    # They should have enough randomness similar as builtin objects. So do not depends int
    based_ints = ulids.map(&:to_i)
    assert do
      (uniq_hashes & based_ints).empty?
    end
    assert do
      (uniq_hashes & based_ints.map(&:hash)).empty?
    end
  end

  def test_hash_key
    ulid1_1 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid1_2 = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    ulid2 = ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ')

    hash = {
      ulid1_1 => :ulid1_1,
      ulid1_2 => :ulid1_2,
      ulid2 => :ulid2
    }

    assert_equal([:ulid1_2, :ulid2], hash.values)
    assert_equal(:ulid1_2, hash.fetch(ulid1_1))
    assert_equal(:ulid2, hash.fetch(ulid2))

    ulid2_hash = ulid2.hash

    having_same_hash = Object.new
    having_same_hash.singleton_class.class_eval do
      define_method(:hash) do
        ulid2_hash
      end
    end
    assert_equal(having_same_hash.hash, ulid2.hash)

    hash[having_same_hash] = :having_same_hash

    assert_equal(
      {
        ulid1_2 => :ulid1_2,
        ulid2 => :ulid2,
        having_same_hash => :having_same_hash
      }, hash)
  end

  def test_dup
    ulid = ULID.sample
    assert_equal(ulid, ulid.dup)
    assert_not_same(ulid, ulid.dup)
    assert_false(ulid.frozen?)
    assert_false(ulid.dup.frozen?)
  end

  def test_clone
    ulid = ULID.sample
    assert_equal(ulid, ulid.clone)
    assert_not_same(ulid, ulid.clone)
    assert_false(ulid.frozen?)
    assert_false(ulid.clone.frozen?)
  end

  def test_instance_variable_set
    ulid = ULID.sample
    int = ulid.to_i
    str = ulid.instance_variable_get(:@encoded)

    assert_raises(NoMethodError) do
      ulid.instance_variable_set(:@integer, int + 42)
    end
    assert_equal(int, ulid.to_i)
    assert_equal(int, ulid.instance_variable_get(:@integer))

    assert_raises(NoMethodError) do
      ulid.instance_variable_set(:@encoded, str.dup.downcase)
    end
    assert_same(str, ulid.instance_variable_get(:@encoded))
  end

  def test_to_ulid
    ulid = ULID.sample
    assert_same(ulid, ulid.to_ulid)
  end

  def test_to_time
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    time = ulid.to_time
    assert_equal(Time.at(0, 1469922850259, :millisecond).utc, time)
    assert_true(time.utc?)
    assert_not_same(ulid.to_time, time)
    assert_equal(ulid.to_time, time)
    assert_false(time.frozen?)
  end

  def test_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([1, 86, 62, 58, 181, 211, 214, 118, 76, 97, 239, 185, 147, 2, 189, 91], ulid.octets)
    assert_not_same(ulid.octets, ulid.octets)
    assert_false(ulid.octets.frozen?)
  end

  def test_timestamp_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([1, 86, 62, 58, 181, 211], ulid.timestamp_octets)
    assert_not_same(ulid.timestamp_octets, ulid.timestamp_octets)
    assert_false(ulid.timestamp_octets.frozen?)
  end

  def test_randomness_octets
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal([214, 118, 76, 97, 239, 185, 147, 2, 189, 91], ulid.randomness_octets)
    assert_not_same(ulid.randomness_octets, ulid.randomness_octets)
    assert_false(ulid.randomness_octets.frozen?)
  end

  def test_next
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(ulid.next.to_i, ulid.to_i + 1)
    assert_instance_of(ULID, ulid.next)
    assert_not_same(ulid.next, ulid.next)

    first = ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRY')
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), first.next)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVS0'), first.next.next)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVS1'), first.next.next.next)
  end

  def test_pred
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_equal(ulid.pred.to_i, ulid.to_i - 1)
    assert_instance_of(ULID, ulid.pred)
    assert_not_same(ulid.pred, ulid.pred)

    first = ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR2')
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR1'), first.pred)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVR0'), first.pred.pred)
    assert_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVQZ'), first.pred.pred.pred)
  end

  def test_freeze
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_false(ulid.frozen?)
    assert_same(ulid, ulid.freeze)
    assert_true(ulid.frozen?)
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
