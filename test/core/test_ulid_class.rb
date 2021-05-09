# coding: utf-8
# frozen_string_literal: true

require_relative '../helper'

class TestULIDClass < Test::Unit::TestCase
  include ULIDAssertions

  def setup
    @actual_timezone = ENV['TZ']
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
    assert_raise(NoMethodError) do
      ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39')
    end
  end

  def test_constant_version
    assert_equal(true, ULID::VERSION.frozen?)
  end

  def test_parse
    string = +'01ARZ3NDEKTSV4RRFFQ69G5FAV'
    dup_string = string.dup
    parsed = ULID.parse(string)

    # Ensure the string is not modified in parser
    assert_equal(false, string.frozen?)
    assert_equal(dup_string, string)

    assert_instance_of(ULID, parsed)
    assert_equal(string, parsed.to_s)
    assert_equal(string, ULID.parse(string.downcase).to_s)

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA'
    ].each do |invalid|
      err = assert_raises(ULID::ParserError) do
        ULID.parse(invalid)
      end
      assert_match(/does not match to/, err.message)
    end

    assert_raises(ArgumentError) do
      ULID.parse
    end

    [nil, 42, string.to_sym, BasicObject.new, Object.new, parsed].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.parse(evil)
      end
      assert_equal('ULID.parse takes only strings', err.message)
    end
  end

  def test_new
    err = assert_raises(NoMethodError) do
      ULID.new(milliseconds: 0, entropy: 42)
    end
    assert_match(/private method `new' called/, err.message)
  end

  def test_from_monotonic_generator
    monotonic_generator = ULID::MonotonicGenerator.new
    monotonic_generator.latest_milliseconds = 0
    monotonic_generator.latest_entropy = 0
    assert_equal(ULID.parse('00000000000000000000000000'), ULID.from_monotonic_generator(monotonic_generator))

    monotonic_generator.latest_milliseconds = -1
    err = assert_raises(ArgumentError) do
      ULID.from_monotonic_generator(monotonic_generator)
    end
    assert_match('milliseconds and entropy should not be negative', err.message)

    monotonic_generator.latest_milliseconds = 0
    monotonic_generator.latest_entropy = -1
    err = assert_raises(ArgumentError) do
      ULID.from_monotonic_generator(monotonic_generator)
    end
    assert_match('milliseconds and entropy should not be negative', err.message)

    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', 42, Time.now].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_monotonic_generator(evil)
      end
      assert_match(/this method provided only for MonotonicGenerator/, err.message)
    end
  end

  def test_valid?
    assert_equal(false, ULID.valid?(nil))
    assert_equal(false, ULID.valid?(''))
    assert_equal(false, ULID.valid?(BasicObject.new))
    assert_equal(false, ULID.valid?(Object.new))
    assert_equal(false, ULID.valid?(42))
    assert_equal(false, ULID.valid?(:'01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(false, ULID.valid?(ULID.sample))
    assert_equal(false, ULID.valid?("01ARZ3NDEKTSV4RRFFQ69G5FAV\n"))
    assert_equal(false, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAU'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID.valid?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID.valid?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID.valid?('80000000000000000000000000'))

    assert_raises(ArgumentError) do
      ULID.valid?
    end
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

    # For optimization
    assert_equal(true, ULID.range(include_end).begin.frozen?)
    assert_equal(true, ULID.range(include_end).end.frozen?)

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

    assert_equal(
      range = ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max(moment: ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds1..time_has_more_value_than_milliseconds1)
    )
    assert_equal(true, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_equal(true, range.cover?(range.begin))
    assert_equal(true, range.cover?(range.end))

    assert_raises(ArgumentError) do
      ULID.range
    end

    assert_same(range, ULID.range(range))
    assert_equal(range.begin..ULID.max, ULID.range(range.begin..nil))

    if RUBY_VERSION >= '2.7'
      assert_equal(ULID.min..range.end, ULID.range(nil..range.end))
    end

    [nil, 42, 1..42, time_has_more_value_than_milliseconds1, ULID.sample.to_s, ULID.sample,
    BasicObject.new, Object.new, range.begin.to_s..range.end.to_s].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.range(evil)
      end
      assert(err.message.start_with?('ULID.range takes only `Range[Time]` or `Range[nil]`'))
    end

    # Below section is for some edge cases ref: https://github.com/kachick/ruby-ulid/issues/74
    assert_equal(
      range = ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1))...ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds1...time_has_more_value_than_milliseconds1)
    )
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_equal(false, range.cover?(range.begin)) # Same as Range[Integer] `(1...1).cover?(1) #=> false`
    assert_equal(false, range.cover?(range.end))

    assert_equal(
      range = ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds2))..ULID.max(moment: ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds2..time_has_more_value_than_milliseconds1)
    )
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_equal(false, range.cover?(range.begin)) # This is bit weird, but same as Range[Integer] `(3..1).cover?(3) #=> false`
    assert_equal(false, range.cover?(range.end))

    assert_equal(
      range = ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds2))...ULID.min(moment: ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds2...time_has_more_value_than_milliseconds1)
    )
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_equal(false, range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_equal(false, range.cover?(range.begin))
    assert_equal(false, range.cover?(range.end))
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

    [nil, 42, ulid, ulid.to_s, BasicObject.new, Object.new].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.floor(evil)
      end
      assert_equal('ULID.floor takes only `Time` instance', err.message)
    end

    assert_raises(ArgumentError) do
      ULID.floor
    end
  end

  def test_scan
    json_string =<<-'EOD'
    {
      "id": "01F4GNAV5ZR6FJQ5SFQC7WDSY3",
      "author": {
        "id": "01F4GNBXW1AM2KWW52PVT3ZY9X",
        "name": "kachick"
      },
      "title": "My awesome blog post",
      "comments": [
        {
          "id": "01F4GNCNC3CH0BCRZBPPDEKBKS",
          "commenter": {
            "id": "01F4GNBXW1AM2KWW52PVT3ZY9X",
            "name": "kachick"
          }
        },
        {
          "id": "01F4GNCXAMXQ1SGBH5XCR6ZH0M",
          "commenter": {
            "id": "01F4GND4RYYSKNAADHQ9BNXAWJ",
            "name": "pankona"
          }
        }
      ]
    }
    EOD

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

    assert_raises(ArgumentError) do
      ULID.scan
    end

    [nil, 42, json_string.to_sym, BasicObject.new, Object.new, expectation.first].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.scan(evil)
      end
      assert_equal('ULID.scan takes only strings', err.message)
    end
  end

  def test_constant_regexp
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.casefold?)
    assert_equal(Encoding::US_ASCII, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.encoding)
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.frozen?)
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n")) # false negative
    assert_equal(false, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(''))
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('00000000000000000000000000'))
    assert_equal(true, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('80000000000000000000000000'))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ULID::PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match('01ARZ3NDEKTSV4RRFFQ69G5FAV').named_captures)

    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.casefold?)
    assert_equal(Encoding::US_ASCII, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.encoding)
    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.frozen?)
    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(false, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?("01ARZ3NDEKTSV4RRFFQ69G5FAV\n"))
    assert_equal(false, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n"))
    assert_equal(false, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(''))
    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('00000000000000000000000000'))
    assert_equal(true, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?('80000000000000000000000000'))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, ULID::STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match('01ARZ3NDEKTSV4RRFFQ69G5FAV').named_captures)

    assert_equal(true, ULID::SCANNING_PATTERN.casefold?)
    assert_equal(Encoding::US_ASCII, ULID::SCANNING_PATTERN.encoding)
    assert_equal(true, ULID::SCANNING_PATTERN.frozen?)
    assert_equal(true, ULID::SCANNING_PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_equal(true, ULID::SCANNING_PATTERN.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n")) # false negative
    assert_equal(false, ULID::SCANNING_PATTERN.match?(''))
    assert_equal(true, ULID::SCANNING_PATTERN.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_equal(true, ULID::SCANNING_PATTERN.match?('00000000000000000000000000'))
    assert_equal(true, ULID::SCANNING_PATTERN.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_equal(false, ULID::SCANNING_PATTERN.match?('80000000000000000000000000'))
    assert_equal([], ULID::SCANNING_PATTERN.names)
  end

  def test_generate
    assert_instance_of(ULID, ULID.generate)
    assert_not_equal(ULID.generate, ULID.generate)

    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_not_equal(time, ulid.to_time)
    assert_equal(true, ulid.to_time < time)
    assert_equal(ULID.floor(time), ulid.to_time)
    milliseconds = 42
    assert_equal(Time.at(0, milliseconds, :millisecond), ULID.generate(moment: milliseconds).to_time)

    entropy = 42
    assert_equal(entropy, ULID.generate(entropy: entropy).entropy)

    [nil, 4.2, 42/24r, '42', ulid, ulid.to_s, BasicObject.new, Object.new].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.generate(moment: evil)
      end
      assert_equal('`moment` should be a `Time` or `Integer as milliseconds`', err.message)
    end
  end

  def test_at
    time = Time.at(946684800, Rational('123456.789')).utc
    assert_instance_of(ULID, ULID.at(time))
    assert_not_equal(ULID.at(time), ULID.at(time))
    ulid = ULID.at(time)
    assert_not_equal(time, ulid.to_time)
    assert_equal(true, ulid.to_time < time)
    assert_equal(ULID.floor(time), ulid.to_time)

    assert_raise(ArgumentError) do
      ULID.at
    end

    [nil, BasicObject.new, 42, '42'].each do |invalid|
      err = assert_raise(ArgumentError) do
        ULID.at(invalid)
      end
      assert_match(/ULID\.at takes only.+Time/, err.message)
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

  def test_sample
    assert_instance_of(ULID, ULID.sample)
    assert_not_equal(ULID.sample, ULID.sample)
    assert_equal([], ULID.sample(0))
    assert_instance_of(Array, ULID.sample(1))
    assert_equal(true, ULID.sample(1).size == 1)
    assert_instance_of(ULID, ULID.sample(1)[0])
    assert_instance_of(Array, ULID.sample(42))
    assert_equal(true, ULID.sample(42).size == 42)
    assert_nil(ULID.sample(42).uniq!)

    ULID.sample(42).each do |ulid|
      assert_acceptable_randomized_string(ulid)
    end

    time1 = Time.at(1620365807)
    time2 = Time.at(1624065807)
    assert_instance_of(ULID, ULID.sample(period: time1..time2))
    assert_equal([], ULID.sample(0, period: time1..time2))
    assert_instance_of(Array, ULID.sample(1, period: time1..time2))
    assert_equal(true, ULID.sample(1, period: time1..time2).size == 1)
    assert_instance_of(ULID, ULID.sample(1, period: time1..time2)[0])
    assert_instance_of(Array, ULID.sample(42, period: time1..time2))
    assert_equal(true, ULID.sample(42, period: time1..time2).size == 42)
    assert_nil(ULID.sample(42, period: time1..time2).uniq!)
    assert_equal(42, ULID.sample(42, period: time1..time2).uniq(&:to_time).size)
    assert(ULID.sample(42, period: time1..time2).all? { |ulid| ULID.range(time1..time2).cover?(ulid) })
    ULID.sample(42, period: time1..time2).each do |ulid|
      assert_acceptable_randomized_string(ulid)
    end

    assert_instance_of(ULID, ULID.sample(period: time1..time1))
    assert_equal([], ULID.sample(0, period: time1..time1))
    assert_instance_of(Array, ULID.sample(1, period: time1..time1))
    assert_equal(true, ULID.sample(1, period: time1..time1).size == 1)
    assert_instance_of(ULID, ULID.sample(1, period: time1..time1)[0])
    assert_instance_of(Array, ULID.sample(42, period: time1..time1))
    assert_equal(42, ULID.sample(42, period: time1..time1).size)
    assert_nil(ULID.sample(42, period: time1..time1).uniq!)
    assert_equal(1, ULID.sample(42, period: time1..time1).uniq(&:to_time).size)
    ULID.sample(42, period: time1..time1).each do |ulid|
      assert_acceptable_randomized_string(ulid)
    end

    ulid = ULID.sample
    err = assert_raises(ArgumentError) do
      ULID.sample(period: ulid...ulid)
    end
    assert_match(/does not have possibilities/, err.message)
    err = assert_raises(ArgumentError) do
      ULID.sample(period: ulid.succ..ulid)
    end
    assert_match(/does not have possibilities/, err.message)
    assert_equal(ulid, ULID.sample(period: ulid..ulid))
    err = assert_raises(ArgumentError) do
      ULID.sample(2, period: ulid..ulid)
    end
    assert_match('given number 2 is larger than given possibilities 1', err.message)
    assert_equal(2, ULID.sample(2, period: ulid..ulid.succ).size)
    assert_equal(0, (ULID.sample(2, period: ulid..ulid.succ) - [ulid, ulid.succ]).size)
    
    [-1, ULID::MAX_INTEGER.succ].each do |out_of_range|
      err = assert_raises(ArgumentError) do
        ULID.sample(out_of_range)
      end
      assert_match(/larger than ULID limit.+or negative/, err.message)
    end

    [nil, BasicObject.new, '42', 4.2].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.sample(evil)
      end
      assert_match('accepts no argument or integer only', err.message)
    end

    err = assert_raises(ArgumentError) do
      ULID.sample(42, 42)
    end
    assert_match('wrong number of arguments', err.message)
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
