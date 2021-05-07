# coding: utf-8
# frozen_string_literal: true

require_relative 'helper'

class TestULIDClass < Test::Unit::TestCase
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

  def test_constants
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
    assert_match(/given argument does not match to/, err.message)
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
      ULID.range(nil)
    end
    err = assert_raises(ArgumentError) do
      ULID.range(0..42)
    end
    assert_match(/ULID\.range takes only `Range\[Time\]`.+`Range\[nil\]`/, err.message)
    assert_raises(ArgumentError) do
      ULID.range('01ARZ3NDEKTSV4RRFFQ69G5FAV'..'7ZZZZZZZZZZZZZZZZZZZZZZZZZ')
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

    [nil, BasicObject.new, '42'].each do |invalid|
      assert_raises do
        ULID.generate(moment: invalid)
      end
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

    [-1, ULID::MAX_INTEGER.succ].each do |invalid|
      assert_raises(ArgumentError) do
        ULID.sample(invalid)
      end
    end

    [nil, BasicObject.new].each do |invalid|
      assert_raises(TypeError) do
        ULID.sample(invalid)
      end
    end
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
