# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestULID < Test::Unit::TestCase
  def setup
    @actual_timezone = ENV['TZ']
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
  end

  def test_constants
    assert_equal(true, ULID::VERSION.frozen?)
  end

  def test_parse
    parsed = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(ULID, parsed)
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', parsed.to_s)
    assert_equal('01ARZ3NDEKTSV4RRFFQ69G5FAV', ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase).to_s)

    assert_raises(ULID::ParserError) do
      ULID.parse(nil)
    end

    assert_raises(ULID::ParserError) do
      ULID.parse('')
    end

    assert_raises(ULID::ParserError) do
      ULID.parse("01ARZ3NDEKTSV4RRFFQ69G5FAV\n")
    end

    assert_raises(ULID::ParserError) do
      ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAU')
    end

    err = assert_raises(ULID::ParserError) do
      ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FA')
    end

    assert_match(/parsing failure as.+parsable string must be 26 characters, but actually given 25 characters.+01ARZ3NDEKTSV4RRFFQ69G5FA/, err.message)
  end

  def test_new
    assert_equal(ULID.parse('00000000000000000000000000'), ULID.new(milliseconds: 0, entropy: 0))

    err = assert_raises(ArgumentError) do
      ULID.new(milliseconds: -1, entropy: 0)
    end
    assert_match('milliseconds and entropy should not be negative', err.message)

    err = assert_raises(ArgumentError) do
      ULID.new(milliseconds: 0, entropy: -1)
    end
    assert_match('milliseconds and entropy should not be negative', err.message)

    assert_raises do
      ULID.new(milliseconds: nil, entropy: 0)
    end

    assert_raises do
      ULID.new(milliseconds: 0, entropy: nil)
    end
  end

  def test_valid?
    assert_equal(false, ULID.valid?(nil))
    assert_equal(false, ULID.valid?(''))
    assert_equal(false, ULID.valid?("01ARZ3NDEKTSV4RRFFQ69G5FAV\n"))
    assert_equal(false, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAU'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID.valid?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID.valid?('80000000000000000000000000'))
  end

  def test_range
    time_has_more_value_than_milliseconds1 = Time.at(946684800, Rational('123456.789')) # 2000-01-01 00:00:00.123456789 UTC
    time_has_more_value_than_milliseconds2 = Time.at(1620045632, Rational('123456.789')) # 2021-05-03 12:40:32.123456789 UTC
    include_end = time_has_more_value_than_milliseconds1..time_has_more_value_than_milliseconds2
    exclude_end = time_has_more_value_than_milliseconds1...time_has_more_value_than_milliseconds2

    assert_equal(
      ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max(moment: ULID.floor(time_has_more_value_than_milliseconds2)),
      ULID.range(include_end)
    )

    assert_equal(
      ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))...ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds2)),
      ULID.range(exclude_end)
    )

    include_end_and_nil_end = time_has_more_value_than_milliseconds1..nil
    exclude_end_and_nil_end = time_has_more_value_than_milliseconds1...nil

    assert_equal(
      ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max,
      ULID.range(include_end_and_nil_end)
    )

    # The end should be max and include end, because nil end means to cover endless ULIDs until the limit
    assert_equal(
      ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max,
      ULID.range(exclude_end_and_nil_end)
    )

    if RUBY_VERSION >= '2.7'
      assert_equal(
        ULID.min..ULID.max(moment: ULID.floor(time_has_more_value_than_milliseconds2)),
        ULID.range(nil..time_has_more_value_than_milliseconds2)
      )
      assert_equal(
        ULID.min...ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds2)),
        ULID.range(nil...time_has_more_value_than_milliseconds2)
      )
      assert_equal(
        ULID.min..ULID.max,
        ULID.range(nil..nil)
      )
      assert_equal(
        ULID.min..ULID.max, # Intentional to return `include_end` for `exclude_end` Range.
        ULID.range(nil...nil)
      )
    end

    assert_raises(ArgumentError) do
      ULID.range(nil)
    end
    assert_raises(ArgumentError) do
      ULID.range(0..42)
    end
    assert_raises(ArgumentError) do
      ULID.range('01ARZ3NDEKTSV4RRFFQ69G5FAV'..'7ZZZZZZZZZZZZZZZZZZZZZZZZZ')
    end

    # Currently I do not determine which behaviors will be best for below pattern, so temporary preventing accidents
    # ref: https://github.com/kachick/ruby-ulid/issues/74
    err = assert_raises(NotImplementedError) do
      ULID.range(time_has_more_value_than_milliseconds1..time_has_more_value_than_milliseconds1)
    end
    assert_equal(true, err.message.include?('https://github.com/kachick/ruby-ulid/issues/74'))
    err = assert_raises(NotImplementedError) do
      ULID.range(time_has_more_value_than_milliseconds2..time_has_more_value_than_milliseconds1)
    end
    assert_equal(true, err.message.include?('https://github.com/kachick/ruby-ulid/issues/74'))
  end

  def test_floor
    time_has_more_value_than_milliseconds = Time.at(946684800, Rational('123456.789'))
    assert_equal('EST', time_has_more_value_than_milliseconds.zone)
    ulid = ULID.generate(moment: time_has_more_value_than_milliseconds)
    assert_equal(123456789, time_has_more_value_than_milliseconds.nsec)
    floored = ULID.floor(time_has_more_value_than_milliseconds)
    assert_instance_of(Time, floored)
    assert_equal(123000000, floored.nsec)
    assert_equal(ulid.to_time, floored)
    assert_equal('EST', floored.zone)
  end

  def test_scan
    json_string = "{\n  \"id\": \"01F4GNAV5ZR6FJQ5SFQC7WDSY3\",\n  \"author\": {\n    \"id\": \"01F4GNBXW1AM2KWW52PVT3ZY9X\",\n    \"name\": \"kachick\"\n  },\n  \"title\": \"My awesome blog post\",\n  \"comments\": [\n    {\n      \"id\": \"01F4GNCNC3CH0BCRZBPPDEKBKS\",\n      \"commenter\": {\n        \"id\": \"01F4GNBXW1AM2KWW52PVT3ZY9X\",\n        \"name\": \"kachick\"\n      }\n    },\n    {\n      \"id\": \"01F4GNCXAMXQ1SGBH5XCR6ZH0M\",\n      \"commenter\": {\n        \"id\": \"01F4GND4RYYSKNAADHQ9BNXAWJ\",\n        \"name\": \"pankona\"\n      }\n    }\n  ]\n}\n"

    enum = ULID.scan(json_string)
    assert_instance_of(Enumerator, enum)
    assert_nil(enum.size)

    yielded = []
    assert_same(ULID, ULID.scan(json_string) do |ulid|
      yielded << ulid
    end)

    assert_equal(true, yielded.all? { |ulid| ulid.instance_of?(ULID) })
    assert_equal(enum.to_a, yielded)

    expectation = [
      ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3'),
      ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X'),
      ULID.parse('01F4GNCNC3CH0BCRZBPPDEKBKS'),
      ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X'),
      ULID.parse('01F4GNCXAMXQ1SGBH5XCR6ZH0M'),
      ULID.parse('01F4GND4RYYSKNAADHQ9BNXAWJ'),
    ]
    assert_equal(expectation, yielded)
    assert_equal(2, expectation.count(ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X')))
  end

  def test_constant_regexp
    assert_equal(true, ULID::PATTERN.casefold?)
    assert_equal(Encoding::US_ASCII, ULID::PATTERN.encoding)
    assert_equal(true, ULID::PATTERN.frozen?)
    assert_equal(true, ULID::PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID::PATTERN.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n"))
    assert_equal(false, ULID::PATTERN.match?(''))
    assert_equal(true, ULID::PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID::PATTERN.match?('00000000000000000000000000'))
    assert_equal(true, ULID::PATTERN.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID::PATTERN.match?('80000000000000000000000000'))

    assert_equal(true, ULID::STRICT_PATTERN.casefold?)
    assert_equal(Encoding::US_ASCII, ULID::STRICT_PATTERN.encoding)
    assert_equal(true, ULID::STRICT_PATTERN.frozen?)
    assert_equal(true, ULID::STRICT_PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(false, ULID::STRICT_PATTERN.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n"))
    assert_equal(false, ULID::STRICT_PATTERN.match?(''))
    assert_equal(true, ULID::STRICT_PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID::STRICT_PATTERN.match?('00000000000000000000000000'))
    assert_equal(true, ULID::STRICT_PATTERN.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID::STRICT_PATTERN.match?('80000000000000000000000000'))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ULID::STRICT_PATTERN.match('01ARZ3NDEKTSV4RRFFQ69G5FAV').named_captures)
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

  def test_pattern
    ulid = ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV')
    assert_instance_of(Regexp, ulid.pattern)
    assert_same(ulid.pattern, ulid.pattern)
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
    assert_same(ulid.strict_pattern, ulid.strict_pattern)
    assert_equal(true, ulid.strict_pattern.frozen?)
    assert_equal(Encoding::US_ASCII, ulid.strict_pattern.encoding)
    assert_equal(true, ulid.strict_pattern.casefold?)
    assert_equal(true, ulid.strict_pattern.match?(ulid.to_s))
    assert_equal(false, ulid.strict_pattern.match?(ulid.to_s + "\n"))
    assert_equal(true, ulid.strict_pattern.match?(ulid.to_s.downcase))
    assert_equal(false, ulid.strict_pattern.match?(ulid.next.to_s))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ulid.strict_pattern.match(ulid.to_s).named_captures)
  end

  def test_overflow
    assert_raises(ULID::OverflowError) do
      ULID.parse('80000000000000000000000000')
    end
  end

  def test_generate
    assert_instance_of(ULID, ULID.generate)
    assert_not_equal(ULID.generate, ULID.generate)

    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_not_equal(time, ulid.to_time)
    assert_equal(true, ulid.to_time < time)
    if RUBY_VERSION >= '2.7'
      assert_equal(time.floor(3), ulid.to_time)
    end
    milliseconds = 42
    assert_equal(Time.at(0, milliseconds, :millisecond), ULID.generate(moment: milliseconds).to_time)

    entropy = 42
    assert_equal(entropy, ULID.generate(entropy: entropy).entropy)
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
  end

  def test_from_integer
    min = ULID.parse('00000000000000000000000000')
    max = ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ')

    assert_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.from_integer(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_i))
    assert_equal(min, ULID.from_integer(min.to_i))
    assert_equal(max, ULID.from_integer(max.to_i))

    assert_raises(ArgumentError) do
      ULID.from_integer(-1)
    end

    assert_raises(ULID::OverflowError) do
      ULID.from_integer(max.to_i.succ)
    end

    assert_raises do
      ULID.from_integer(nil)
    end
  end

  def test_min
    assert_equal(ULID.parse('00000000000000000000000000'), ULID.min)
    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_equal(ulid.timestamp + '0000000000000000', ULID.min(moment: time).to_s)
    milliseconds = 42
    ulid = ULID.generate(moment: milliseconds)
    assert_equal(ulid.timestamp + '0000000000000000', ULID.min(moment: milliseconds).to_s)

    assert_equal(ULID.min(moment: milliseconds), ULID.min(moment: milliseconds))
    assert_not_same(ULID.min(moment: milliseconds), ULID.min(moment: milliseconds))
    assert_equal(false, ULID.min(moment: milliseconds).frozen?)

    # For optimization
    assert_same(ULID.min, ULID.min)
    assert_equal(true, ULID.min.frozen?)
  end

  def test_max
    assert_equal(ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'), ULID.max)
    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_equal(ulid.timestamp + 'ZZZZZZZZZZZZZZZZ', ULID.max(moment: time).to_s)
    milliseconds = 42
    ulid = ULID.generate(moment: milliseconds)
    assert_equal(ulid.timestamp + 'ZZZZZZZZZZZZZZZZ', ULID.max(moment: milliseconds).to_s)

    assert_equal(ULID.max(moment: milliseconds), ULID.max(moment: milliseconds))
    assert_not_same(ULID.max(moment: milliseconds), ULID.max(moment: milliseconds))
    assert_equal(false, ULID.max(moment: milliseconds).frozen?)

    # For optimization
    assert_same(ULID.max, ULID.max)
    assert_equal(true, ULID.max.frozen?)
  end

  def test_eq
    assert_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV').to_s, ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_same(ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_not_equal(ULID.parse('01BX5ZZKBKACTAV9WEVGEMMVRZ'), ULID.parse('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
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

class TestBoundaryULID < Test::Unit::TestCase
  def setup
    @min = ULID.min
    @max = ULID.max
    @min_entropy = ULID.parse('01BX5ZZKBK0000000000000000')
    @max_entropy = ULID.parse('01BX5ZZKBKZZZZZZZZZZZZZZZZ')
  end

  def test_constants
    assert_equal(ULID::MAX_MILLISECONDS, @max.milliseconds)
    assert_equal(ULID::MAX_ENTROPY, @max.entropy)
    assert_equal(ULID::MAX_INTEGER, @max.to_i)
  end

  def test_next
    assert_nil(@max.next)
    assert_equal(ULID.parse('01BX5ZZKBM0000000000000000'), @max_entropy.next)
  end

  def test_pred
    assert_nil(@min.pred)
    assert_equal(ULID.parse('01BX5ZZKBJZZZZZZZZZZZZZZZZ'), @min_entropy.pred)
  end

  def test_octets
    assert_equal([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], @min.octets)
    assert_equal([255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255], @max.octets)
  end
end

class TestFrozenULID < Test::Unit::TestCase
  def setup
    @string = '01ARZ3NDEKTSV4RRFFQ69G5FAV'
    @ulid = ULID.parse(@string)
    @ulid.freeze
    @min = ULID.min.freeze
    @max = ULID.max.freeze
  end

  def test_inspect
    assert_equal('ULID(2016-07-30 23:54:10.259 UTC: 01ARZ3NDEKTSV4RRFFQ69G5FAV)', @ulid.inspect)
  end

  def test_to_i
    assert_equal(1777027686520646174104517696511196507, @ulid.to_i)
  end

  def test_to_time
    assert_equal(Time.at(0, 1469922850259, :millisecond).utc, @ulid.to_time)
  end

  def test_octets
    assert_equal([1, 86, 62, 58, 181, 211, 214, 118, 76, 97, 239, 185, 147, 2, 189, 91], @ulid.octets)
  end

  def test_next
    assert_equal(true, @ulid < @ulid.next)
    assert_nil(@max.next)
  end

  def test_pred
    assert_equal(true, @ulid > @ulid.pred)
    assert_nil(@min.pred)
  end
end

class TestBigData < Test::Unit::TestCase
  def test_generate
    ulids = 1000.times.map do |n|
      if (n % 100).zero?
        sleep(0.01)
      end

      ULID.generate
    end

    assert_equal(1000, ulids.map(&:to_s).uniq.size)
    assert_equal(true, (5..50).cover?(ulids.group_by(&:to_time).size))
    assert_not_equal(ulids, ulids.sort_by(&:to_s))
  end
end
