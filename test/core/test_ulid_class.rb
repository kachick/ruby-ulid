# coding: utf-8
# frozen_string_literal: true

require_relative('../helper')

class TestULIDClass < Test::Unit::TestCase
  include(ULIDAssertions)

  def setup
    @actual_timezone = ENV.fetch('TZ', nil)
    ENV['TZ'] = 'EST' # Just chosen from not UTC and JST
  end

  def test_exposed_constants
    assert_equal(
      [
        :ENCODED_LENGTH,
        :Error,
        :MAX_ENTROPY,
        :MAX_INTEGER,
        :MAX_MILLISECONDS,
        :MonotonicGenerator,
        :OCTETS_LENGTH,
        :OverflowError,
        :ParserError,
        :RANDOMNESS_ENCODED_LENGTH,
        :RANDOMNESS_OCTETS_LENGTH,
        :TIMESTAMP_ENCODED_LENGTH,
        :TIMESTAMP_OCTETS_LENGTH,
        :UnexpectedError,
        :VERSION
      ].sort,
      ULID.constants.sort
    )
  end

  def test_exposed_methods
    exposed_methods = ULID.singleton_methods(false).freeze

    # I'm afraid so `safe` naming in Ruby conflicts as YAML.safe_load :<
    # https://www.docswell.com/s/pink_bangbi/K67RV5-2022-01-06-201330
    assert_equal([], exposed_methods.grep(/safe/).to_a)

    assert_equal(
      [
        :scan,
        :sample,
        :try_convert,
        :max,
        :min,
        :generate,
        :encode,
        :from_integer,
        :normalize,
        :floor,
        :range,
        :at,
        :normalized?,
        :parse,
        :decode_time,
        :valid_as_variant_format?,
        :parse_variant_format
      ].sort,
      exposed_methods.sort
    )
  end

  def test_ensure_testing_environment
    assert_equal(Encoding::UTF_8, ''.encoding)
    assert_equal('EST', Time.now.zone)
    assert_raise(NoMethodError) do
      ULID.from_uuidv4('0983d0a2-ff15-4d83-8f37-7dd945b5aa39')
    end
  end

  def test_frozen
    assert_false(ULID.frozen?)
  end

  def test_constant_version
    assert do
      ULID::VERSION.instance_of?(String)
    end

    assert do
      ULID::VERSION.frozen?
    end

    assert do
      Gem::Version.correct?(ULID::VERSION)
    end
  end

  def test_allocate
    # Ensure do not affect to built-in classes
    assert_instance_of(Object, Object.allocate)

    assert_raises(NoMethodError) do
      ULID.allocate
    end
  end

  def test_parse
    string = +'01ARZ3NDEKTSV4RRFFQ69G5FAV'
    dup_string = string.dup
    parsed = ULID.parse(string)

    # Ensure the string is not modified in parser
    assert_false(string.frozen?)
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

  def test_parse_variant_format
    string = +'01G70Y0Y7G-ZLXWDIREXERGSDoD'
    dup_string = string.dup
    parsed = ULID.parse_variant_format(string)

    # Ensure the string is not modified in parser
    assert_false(string.frozen?)
    assert_equal(dup_string, string)

    assert_instance_of(ULID, parsed)
    assert_equal('01G70Y0Y7GZ1XWD1REXERGSD0D', parsed.to_s)
    assert_equal(ULID.parse_variant_format(string), ULID.parse_variant_format('01G70Y0Y7GZ1XWD1REXERGSD0D'))

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA',
      '01G70Y0Y7G_ZLXWDIREXERGSDoD'
    ].each do |invalid|
      err = assert_raises(ULID::ParserError) do
        ULID.parse_variant_format(invalid)
      end
      assert_match(/does not match to/, err.message)
    end

    assert_raises(ArgumentError) do
      ULID.parse_variant_format
    end

    [nil, 42, string.to_sym, BasicObject.new, Object.new, parsed].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.parse_variant_format(evil)
      end
      assert_equal('ULID.parse_variant_format takes only strings', err.message)
    end
  end

  def test_decode_time
    string = +'01ARZ3NDEKTSV4RRFFQ69G5FAV'
    dup_string = string.dup
    parsed = ULID.parse(string)
    decoded_time = ULID.decode_time(string)

    # Ensure the string is not modified in parser
    assert_false(string.frozen?)
    assert_equal(dup_string, string)

    assert_instance_of(Time, decoded_time)
    assert_equal(parsed.to_time, decoded_time)
    assert_equal(decoded_time, ULID.decode_time(string.downcase))
    assert_true(decoded_time.utc?)
    assert_false(decoded_time.frozen?)

    with_in = ULID.decode_time(string, in: '+09:00')

    assert_false(with_in.utc?)
    assert_equal(32400, with_in.utc_offset)

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA'
    ].each do |invalid|
      err = assert_raises(ULID::ParserError) do
        ULID.decode_time(invalid)
      end
      assert_match(/does not match to/, err.message)
    end

    assert_raises(ArgumentError) do
      ULID.decode_time
    end

    [nil, 42, string.to_sym, BasicObject.new, Object.new, parsed].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.decode_time(evil)
      end
      assert_equal('ULID.decode_time takes only strings', err.message)
    end
  end

  def test_new
    err = assert_raises(NoMethodError) do
      ULID.new(milliseconds: 0, entropy: 42)
    end
    assert_match(/private method `new' called/, err.message)
  end

  def test_normalize
    # This is the core of this feature
    assert_equal(ULID.parse('01ARZ3N0EK1SV4RRFFQ61G5FAV'), ULID.parse(ULID.normalize('-OlARZ3-NoEKISV4rRFF-Q6iG5FAV--')))
    assert_equal(ULID.parse('01ARZ3N0EK1SV4RRFFQ61G5FAV').to_s, ULID.normalize('-olarz3-noekisv4rrff-q6ig5fav--'))

    normalized = '01ARZ3NDEKTSV4RRFFQ69G5FAV'
    downcased = normalized.downcase
    dup_downcased = downcased.dup

    assert(normalized.frozen?)
    assert_not_same(normalized, ULID.normalize(normalized))

    assert_true(ULID.normalize(normalized).frozen?)

    # Ensure the string is not modified in parser
    assert_false(downcased.frozen?)
    assert_not_same(downcased, ULID.normalize(downcased))
    assert_equal(dup_downcased, downcased)

    assert_equal(normalized, ULID.normalize(downcased))
    assert_instance_of(String, ULID.normalize(downcased))

    # This encoding handling is controversial, should be return original encoding?
    assert_equal(Encoding::UTF_8, downcased.encoding)
    assert_equal(Encoding::US_ASCII, ULID.normalize(downcased).encoding)

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA',
      '80000000000000000000000000'
    ].each do |invalid|
      err = assert_raises(ULID::ParserError) do
        ULID.normalize(invalid)
      end
      assert_match(/does not match to/, err.message)
    end

    ULID.sample(1000).each do |sample|
      assert_equal(sample.to_s, ULID.normalize(sample.to_s))
      assert_equal(sample.to_s, ULID.normalize(sample.to_s.downcase))
    end

    assert_raises(ArgumentError) do
      ULID.normalize
    end

    [nil, 42, normalized.to_sym, BasicObject.new, Object.new, ULID.parse(normalized)].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.normalize(evil)
      end
      assert_equal('ULID.normalize takes only strings', err.message)
    end
  end

  def test_normalized?
    assert_false(ULID.normalized?('01G70Y0Y7G-Z1XWDAREXERGSDDD'))

    nasty = '-olarz3-noekisv4rrff-q6ig5fav--'
    assert_false(ULID.normalized?(nasty))
    assert_true(ULID.normalized?(ULID.normalize(nasty)))

    normalized = '01ARZ3NDEKTSV4RRFFQ69G5FAV'
    assert_true(ULID.normalized?(normalized))
    assert_false(ULID.normalized?(normalized.downcase))

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA',
      '80000000000000000000000000'
    ].each do |invalid|
      assert_false(ULID.normalized?(invalid))
    end

    ULID.sample(1000).each do |sample|
      assert_true(ULID.normalized?(sample.to_s))
      assert_false(ULID.normalized?(sample.to_s.downcase))
    end

    assert_raises(ArgumentError) do
      ULID.normalized?
    end

    [nil, 42, normalized.to_sym, BasicObject.new, Object.new, ULID.parse(normalized)].each do |evil|
      assert_false(ULID.normalized?(evil))
    end
  end

  def test_valid_as_variant_format?
    assert_true(ULID.valid_as_variant_format?('01G70Y0Y7G-Z1XWDAREXERGSDDD'))

    nasty = '-olarz3-noekisv4rrff-q6ig5fav--'
    assert_true(ULID.valid_as_variant_format?(nasty))
    assert_true(ULID.valid_as_variant_format?(ULID.normalize(nasty)))

    normalized = '01ARZ3NDEKTSV4RRFFQ69G5FAV'
    assert_true(ULID.valid_as_variant_format?(normalized))
    assert_true(ULID.valid_as_variant_format?(normalized.downcase))

    [
      '',
      "01ARZ3NDEKTSV4RRFFQ69G5FAV\n",
      '01ARZ3NDEKTSV4RRFFQ69G5FAU',
      '01ARZ3NDEKTSV4RRFFQ69G5FA',
      '80000000000000000000000000'
    ].each do |invalid|
      assert_false(ULID.valid_as_variant_format?(invalid))
    end

    ULID.sample(1000).each do |sample|
      assert_true(ULID.valid_as_variant_format?(sample.to_s))
      assert_true(ULID.valid_as_variant_format?(sample.to_s.downcase))
    end

    assert_raises(ArgumentError) do
      ULID.valid_as_variant_format?
    end

    [nil, 42, normalized.to_sym, BasicObject.new, Object.new, ULID.parse(normalized)].each do |evil|
      assert_false(ULID.valid_as_variant_format?(evil))
    end
  end

  def test_range
    time_has_more_value_than_milliseconds1 = Time.at(946684800, Rational('123456.789')) # 2000-01-01 00:00:00.123456789 UTC
    time_has_more_value_than_milliseconds2 = Time.at(1620045632, Rational('123456.789')) # 2021-05-03 12:40:32.123456789 UTC
    include_end = time_has_more_value_than_milliseconds1..time_has_more_value_than_milliseconds2
    exclude_end = time_has_more_value_than_milliseconds1...time_has_more_value_than_milliseconds2

    assert_equal(
      ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max(ULID.floor(time_has_more_value_than_milliseconds2)),
      ULID.range(include_end)
    )

    assert_equal(
      ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))...ULID.min(ULID.floor(time_has_more_value_than_milliseconds2)),
      ULID.range(exclude_end)
    )

    # For optimization
    assert_true(ULID.range(include_end).begin.frozen?)
    assert_true(ULID.range(include_end).end.frozen?)

    include_end_and_nil_end = time_has_more_value_than_milliseconds1..nil
    exclude_end_and_nil_end = time_has_more_value_than_milliseconds1...nil

    assert_equal(
      ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max,
      ULID.range(include_end_and_nil_end)
    )

    # The end should be max and include end, because nil end means to cover endless ULIDs until the limit
    assert_equal(
      ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max,
      ULID.range(exclude_end_and_nil_end)
    )

    assert_equal(
      ULID.min..ULID.max(ULID.floor(time_has_more_value_than_milliseconds2)),
      ULID.range(nil..time_has_more_value_than_milliseconds2)
    )
    assert_equal(
      ULID.min...ULID.min(ULID.floor(time_has_more_value_than_milliseconds2)),
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

    assert_equal(
      range = ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))..ULID.max(ULID.floor(time_has_more_value_than_milliseconds1)),
      from_time = ULID.range(time_has_more_value_than_milliseconds1..time_has_more_value_than_milliseconds1)
    )
    assert_true(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_true(range.cover?(range.begin))
    assert_true(range.cover?(range.end))
    if RUBY_VERSION >= '3.0'
      # Just a note
      assert_true(range.frozen?)
    end
    assert_true(range.begin.frozen?)
    assert_true(range.end.frozen?)
    assert_true(from_time.begin.frozen?)
    assert_true(from_time.end.frozen?)

    assert_raises(ArgumentError) do
      ULID.range
    end

    assert_not_same(range, ULID.range(range))
    assert_equal(range, ULID.range(range))
    assert_true(range.begin.frozen?)
    assert_true(range.end.frozen?)
    assert_equal(range.begin..ULID.max, ULID.range(range.begin..nil))

    assert_equal(ULID.min..range.end, ULID.range(nil..range.end))

    [nil, 42, 1..42, time_has_more_value_than_milliseconds1, ULID.sample.to_s, ULID.sample,
    BasicObject.new, Object.new, range.begin.to_s..range.end.to_s].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.range(evil)
      end
      assert(err.message.start_with?('ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`'))
    end

    # Below section is for some edge cases ref: https://github.com/kachick/ruby-ulid/issues/74
    assert_equal(
      range = ULID.min(ULID.floor(time_has_more_value_than_milliseconds1))...ULID.min(ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds1...time_has_more_value_than_milliseconds1)
    )
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_false(range.cover?(range.begin)) # Same as Range[Integer] `(1...1).cover?(1) #=> false`
    assert_false(range.cover?(range.end))

    assert_equal(
      range = ULID.min(ULID.floor(time_has_more_value_than_milliseconds2))..ULID.max(ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds2..time_has_more_value_than_milliseconds1)
    )
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_false(range.cover?(range.begin)) # This is bit weird, but same as Range[Integer] `(3..1).cover?(3) #=> false`
    assert_false(range.cover?(range.end))

    assert_equal(
      range = ULID.min(ULID.floor(time_has_more_value_than_milliseconds2))...ULID.min(ULID.floor(time_has_more_value_than_milliseconds1)),
      ULID.range(time_has_more_value_than_milliseconds2...time_has_more_value_than_milliseconds1)
    )
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds2)))
    assert_false(range.cover?(ULID.generate(moment: time_has_more_value_than_milliseconds1)))
    assert_false(range.cover?(range.begin))
    assert_false(range.cover?(range.end))
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
    json_string = <<-'JSON'
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
    JSON

    enum = ULID.scan(json_string)
    assert_instance_of(Enumerator, enum)
    assert_nil(enum.size)

    yielded = []
    assert_same(ULID, ULID.scan(json_string) do |ulid|
      yielded << ulid
    end)

    assert_true(yielded.all? { |ulid| ulid.instance_of?(ULID) })
    assert_equal(enum.to_a, yielded)

    expectation = [
      ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3'),
      ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X'),
      ULID.parse('01F4GNCNC3CH0BCRZBPPDEKBKS'),
      ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X'),
      ULID.parse('01F4GNCXAMXQ1SGBH5XCR6ZH0M'),
      ULID.parse('01F4GND4RYYSKNAADHQ9BNXAWJ')
    ]
    assert_equal(expectation, yielded)
    assert_equal(2, expectation.count(ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X')))

    assert_equal([], ULID.scan("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n").to_a)

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

  def test_scan_non_ascii
    assert_equal(
      [
        ULID.parse('01F4GNAV5ZR6FJQ5SFQC7WDSY3'),
        ULID.parse('01F4GNBXW1AM2KWW52PVT3ZY9X')
      ],
      ULID.scan('　01F4GNAV5ZR6FJQ5SFQC7WDSY3　01F4GNCNC3CH0BCRZBPPDEKBKS区切りではない　01F4GNBXW1AM2KWW52PVT3ZY9X').to_a
    )
  end

  def test_constant_regexp
    subset_pattern = ULID.const_get(:PATTERN_WITH_CROCKFORD_BASE32_SUBSET)
    strict_pattern = ULID.const_get(:STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET)
    scanning_pattern = ULID.const_get(:SCANNING_PATTERN)
    assert_true(subset_pattern.casefold?)
    assert_equal(Encoding::US_ASCII, subset_pattern.encoding)
    assert_true(subset_pattern.frozen?)
    assert_true(subset_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_true(subset_pattern.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n")) # false negative
    assert_false(subset_pattern.match?(''))
    assert_true(subset_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_true(subset_pattern.match?('00000000000000000000000000'))
    assert_true(subset_pattern.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_false(subset_pattern.match?('80000000000000000000000000'))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, subset_pattern.match('01ARZ3NDEKTSV4RRFFQ69G5FAV').named_captures)

    assert_true(strict_pattern.casefold?)
    assert_equal(Encoding::US_ASCII, strict_pattern.encoding)
    assert_true(strict_pattern.frozen?)
    assert_true(strict_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_false(strict_pattern.match?("01ARZ3NDEKTSV4RRFFQ69G5FAV\n"))
    assert_false(strict_pattern.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n"))
    assert_false(strict_pattern.match?(''))
    assert_true(strict_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_true(strict_pattern.match?('00000000000000000000000000'))
    assert_true(strict_pattern.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_false(strict_pattern.match?('80000000000000000000000000'))
    assert_equal({'timestamp' => '01ARZ3NDEK', 'randomness' => 'TSV4RRFFQ69G5FAV'}, strict_pattern.match('01ARZ3NDEKTSV4RRFFQ69G5FAV').named_captures)

    assert_true(scanning_pattern.casefold?)
    assert_equal(Encoding::US_ASCII, scanning_pattern.encoding)
    assert_true(scanning_pattern.frozen?)
    assert_true(scanning_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'))
    assert_false(scanning_pattern.match?("\nfoo01ARZ3NDEKTSV4RRFFQ69G5FAVbar\n")) # Since 0.4.0
    assert_true(scanning_pattern.match?(' 01ARZ3NDEKTSV4RRFFQ69G5FAV '))
    assert_true(scanning_pattern.match?('　01ARZ3NDEKTSV4RRFFQ69G5FAV　')) # Intentional using non ASCII whitespace
    assert_false(scanning_pattern.match?(''))
    assert_true(scanning_pattern.match?('01ARZ3NDEKTSV4RRFFQ69G5FAV'.downcase))
    assert_true(scanning_pattern.match?('00000000000000000000000000'))
    assert_true(scanning_pattern.match?('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'))
    assert_false(scanning_pattern.match?('80000000000000000000000000'))
    assert_equal([], scanning_pattern.names)
  end

  def test_generate
    assert_instance_of(ULID, ULID.generate)
    assert_not_equal(ULID.generate, ULID.generate)

    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_not_equal(time, ulid.to_time)
    assert_true(ulid.to_time < time)
    assert_equal(ULID.floor(time), ulid.to_time)
    milliseconds = 42
    assert_equal(Time.at(0, milliseconds, :millisecond), ULID.generate(moment: milliseconds).to_time)

    entropy = 42
    assert_equal(entropy, ULID.generate(entropy: entropy).entropy)
  end

  def test_generate_with_invalid_arguments
    [-1].each do |negative|
      err = assert_raises(ArgumentError) do
        ULID.generate(moment: negative, entropy: 42)
      end
      assert_match('milliseconds and entropy should not be negative', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(moment: 42, entropy: negative)
      end
      assert_match('milliseconds and entropy should not be negative', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(moment: negative, entropy: negative)
      end
      assert_match('milliseconds and entropy should not be negative', err.message)
    end

    [ULID.sample.to_time].each do |invalid_for_entropy|
      err = assert_raises(ArgumentError) do
        ULID.generate(entropy: invalid_for_entropy)
      end
      assert_equal('milliseconds and entropy should be an `Integer`', err.message)
    end

    [nil, 4.2, 42/24r, '42', ULID.sample, ULID.sample.to_s, BasicObject.new, Object.new].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.generate(moment: evil)
      end
      assert_equal('`moment` should be a `Time` or `Integer as milliseconds`', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(entropy: evil)
      end
      assert_equal('milliseconds and entropy should be an `Integer`', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(moment: evil, entropy: 42)
      end
      assert_equal('`moment` should be a `Time` or `Integer as milliseconds`', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(moment: 42, entropy: evil)
      end
      assert_equal('milliseconds and entropy should be an `Integer`', err.message)

      err = assert_raises(ArgumentError) do
        ULID.generate(moment: evil, entropy: evil)
      end
      assert_equal('`moment` should be a `Time` or `Integer as milliseconds`', err.message)
    end
  end

  def test_encode
    assert_instance_of(String, ULID.encode)
    assert_not_equal(ULID.encode, ULID.encode)
    assert_true(ULID.normalized?(ULID.encode))

    time = Time.at(946684800, Rational('123456.789')).utc
    gen = ULID.encode(moment: time)
    ulid = ULID.parse(gen)
    assert_equal(ulid.to_s, gen)
    assert_not_same(ulid.to_s, gen)
    assert_false(gen.frozen?)
    assert_not_equal(time, ulid.to_time)
    assert_true(ulid.to_time < time)
    assert_equal(ULID.floor(time), ulid.to_time)
    milliseconds = 42
    assert_equal(Time.at(0, milliseconds, :millisecond), ULID.parse(ULID.encode(moment: milliseconds)).to_time)

    entropy = 42
    assert_equal(entropy, ULID.parse(ULID.encode(entropy: entropy)).entropy)

    [nil, 4.2, 42/24r, '42', ulid, ulid.to_s, BasicObject.new, Object.new].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.encode(moment: evil)
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
    assert_true(ulid.to_time < time)
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
      ULID.from_integer
    end

    assert_raises(ArgumentError) do
      ULID.from_integer(-1)
    end

    assert_raises(ULID::OverflowError) do
      ULID.from_integer(max.to_i.succ)
    end

    [nil, BasicObject.new, '01ARZ3NDEKTSV4RRFFQ69G5FAV', '42', Time.now, ULID.sample, 4.2, Object.new].each do |evil|
      err = assert_raises(ArgumentError) do
        ULID.from_integer(evil)
      end
      assert_equal('ULID.from_integer takes only `Integer`', err.message)
    end
  end

  def test_min
    assert_equal(ULID.parse('00000000000000000000000000'), ULID.min)
    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_equal(ulid.timestamp + '0000000000000000', ULID.min(time).to_s)
    milliseconds = 42
    ulid = ULID.generate(moment: milliseconds)
    assert_equal(ulid.timestamp + '0000000000000000', ULID.min(milliseconds).to_s)

    assert_equal(ULID.min(milliseconds), ULID.min(milliseconds))
    assert_not_same(ULID.min(milliseconds), ULID.min(milliseconds))
    assert_true(ULID.min(milliseconds).frozen?)

    # For optimization
    assert_same(ULID.min, ULID.min)
    assert_true(ULID.min.frozen?)
  end

  def test_max
    assert_equal(ULID.parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'), ULID.max)
    time = Time.at(946684800, Rational('123456.789')).utc
    ulid = ULID.generate(moment: time)
    assert_equal(ulid.timestamp + 'ZZZZZZZZZZZZZZZZ', ULID.max(time).to_s)
    milliseconds = 42
    ulid = ULID.generate(moment: milliseconds)
    assert_equal(ulid.timestamp + 'ZZZZZZZZZZZZZZZZ', ULID.max(milliseconds).to_s)

    assert_equal(ULID.max(milliseconds), ULID.max(milliseconds))
    assert_not_same(ULID.max(milliseconds), ULID.max(milliseconds))
    assert_true(ULID.max(milliseconds).frozen?)

    # For optimization
    assert_same(ULID.max, ULID.max)
    assert_true(ULID.max.frozen?)
  end

  def test_sample
    assert_instance_of(ULID, ULID.sample)
    assert_not_equal(ULID.sample, ULID.sample)
    assert_equal([], ULID.sample(0))
    assert_instance_of(Array, ULID.sample(1))
    assert_true(ULID.sample(1).size == 1)
    assert_instance_of(ULID, ULID.sample(1)[0])
    assert_instance_of(Array, ULID.sample(42))
    assert_true(ULID.sample(42).size == 42)
    assert_nil(ULID.sample(42).uniq!)

    assert_acceptable_randomized_string(ULID.sample(42))

    time1 = Time.at(1620365807)
    time2 = Time.at(1624065807)
    assert_instance_of(ULID, ULID.sample(period: time1..time2))
    assert_equal([], ULID.sample(0, period: time1..time2))
    assert_instance_of(Array, ULID.sample(1, period: time1..time2))
    assert_true(ULID.sample(1, period: time1..time2).size == 1)
    assert_instance_of(ULID, ULID.sample(1, period: time1..time2)[0])
    assert_instance_of(Array, ULID.sample(42, period: time1..time2))
    assert_true(ULID.sample(42, period: time1..time2).size == 42)
    assert_nil(ULID.sample(42, period: time1..time2).uniq!)
    assert_equal(42, ULID.sample(42, period: time1..time2).uniq(&:to_time).size)
    assert(ULID.sample(42, period: time1..time2).all? { |ulid| ULID.range(time1..time2).cover?(ulid) })
    assert_acceptable_randomized_string(ULID.sample(42, period: time1..time2))

    assert_instance_of(ULID, ULID.sample(period: time1..time1))
    assert_equal([], ULID.sample(0, period: time1..time1))
    assert_instance_of(Array, ULID.sample(1, period: time1..time1))
    assert_true(ULID.sample(1, period: time1..time1).size == 1)
    assert_instance_of(ULID, ULID.sample(1, period: time1..time1)[0])
    assert_instance_of(Array, ULID.sample(42, period: time1..time1))
    assert_equal(42, ULID.sample(42, period: time1..time1).size)
    assert_nil(ULID.sample(42, period: time1..time1).uniq!)
    assert_equal(1, ULID.sample(42, period: time1..time1).uniq(&:to_time).size)
    assert_acceptable_randomized_string(ULID.sample(42, period: time1..time1))

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
    assert_match('given number `2` is larger than given possibilities `1`', err.message)
    assert_equal(2, ULID.sample(2, period: ulid..ulid.succ).size)
    assert_equal(0, (ULID.sample(2, period: ulid..ulid.succ) - [ulid, ulid.succ]).size)

    [-1, ULID::MAX_INTEGER.succ].each do |out_of_range|
      err = assert_raises(ArgumentError) do
        ULID.sample(out_of_range)
      end
      assert_match(/larger than ULID limit.+or negative/, err.message)
    end

    assert_instance_of(ULID, ULID.sample(nil))
    [false, BasicObject.new, '42', 4.2].each do |evil|
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

  def test_try_convert
    ulid = ULID.sample
    assert_same(ulid, ULID.try_convert(ulid))
    assert_nil(ULID.try_convert(ulid.to_s))
    assert_nil(ULID.try_convert(ulid.to_i))
    assert_nil(ULID.try_convert(BasicObject.new))

    convertible = BasicObject.new
    (class << convertible; self; end).class_eval do
      define_method(:to_ulid) do
        ulid
      end
    end
    assert_same(ulid, ULID.try_convert(convertible))

    evil = BasicObject.new
    def evil.to_ulid
      BasicObject.new
    end
    err = assert_raises(TypeError) do
      ULID.try_convert(evil)
    end
    assert_match(/can't convert BasicObject to ULID \(BasicObject#to_ulid gives BasicObject\)/, err.message)

    no_offense = Object.new
    def no_offense.to_ulid
      42
    end
    err = assert_raises(TypeError) do
      ULID.try_convert(no_offense)
    end
    assert_match(/can't convert Object to ULID \(Object#to_ulid gives Integer\)/, err.message)

    accidental = BasicObject.new
    error = Exception.new
    (class << accidental; self; end).class_eval do
      define_method(:to_ulid) do
        ::Kernel.raise(error)
      end
    end
    err = assert_raises(Exception) do
      ULID.try_convert(accidental)
    end
    assert_same(error, err)
  end

  def test_all_constructors_returns_frozen_ulid
    assert_true(ULID.generate.frozen?)
    assert_true(ULID.parse(ULID.sample.encode).frozen?)
    assert_true(ULID.parse_variant_format(ULID.sample.encode).frozen?)
    assert_true(ULID.at(ULID.sample.to_time).frozen?)
    assert_true(ULID.sample.frozen?)
    assert do
      ULID.sample(2).map(&:frozen?).all?(&:itself)
    end
    assert_true(ULID.min.frozen?)
    assert_true(ULID.max.frozen?)
    assert_true(ULID.from_integer(42).frozen?)
    assert do
      ULID.scan('["01F4GNAV5ZR6FJQ5SFQC7WDSY3", "01F4GNBXW1AM2KWW52PVT3ZY9X"]').map(&:frozen?).all?(&:itself)
    end
  end

  def teardown
    ENV['TZ'] = @actual_timezone
  end
end
