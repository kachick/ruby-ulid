# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: experimental_everything

# Copyright (C) 2021 Kenichi Kamiya

require('securerandom')

require_relative('ulid/version')
require_relative('ulid/errors')
require_relative('ulid/crockford_base32')
require_relative('ulid/utils')
require_relative('ulid/monotonic_generator')

# @see https://github.com/ulid/spec
# @!attribute [r] milliseconds
#   @return [Integer]
# @!attribute [r] entropy
#   @return [Integer]
class ULID
  include(Comparable)

  TIMESTAMP_ENCODED_LENGTH = 10
  RANDOMNESS_ENCODED_LENGTH = 16
  ENCODED_LENGTH = 26

  TIMESTAMP_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = 16

  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175
  MAX_INTEGER = 340282366920938463463374607431768211455

  # @see https://github.com/ulid/spec/pull/57
  # Currently not used as a constant, but kept as a reference for now.
  PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /(?<timestamp>[0-7][#{CrockfordBase32::ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}})(?<randomness>[#{CrockfordBase32::ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}})/i.freeze

  STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /\A#{PATTERN_WITH_CROCKFORD_BASE32_SUBSET.source}\z/i.freeze

  # Optimized for `ULID.scan`, might be changed the definition with gathered `ULID.scan` spec changed.
  SCANNING_PATTERN = /\b[0-7][#{CrockfordBase32::ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}}[#{CrockfordBase32::ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}}\b/i.freeze

  # Similar as Time#inspect since Ruby 2.7, however it is NOT same.
  # Time#inspect trancates needless digits. Keeping full milliseconds with "%3N" will fit for ULID.
  # @see https://bugs.ruby-lang.org/issues/15958
  # @see https://github.com/ruby/ruby/blob/744d17ff6c33b09334508e8110007ea2a82252f5/time.c#L4026-L4078
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  RANDOM_INTEGER_GENERATOR = -> {
    SecureRandom.random_number(MAX_INTEGER)
  }.freeze

  private_constant(
    :PATTERN_WITH_CROCKFORD_BASE32_SUBSET,
    :STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET,
    :SCANNING_PATTERN,
    :TIME_FORMAT_IN_INSPECT,
    :RANDOM_INTEGER_GENERATOR
  )

  private_class_method(:new)

  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [ULID]
  # @raise [OverflowError] if the given value is larger than the ULID limit
  # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
  def self.generate(moment: Utils.current_milliseconds, entropy: Utils.reasonable_entropy)
    milliseconds = Utils.milliseconds_from_moment(moment)
    base32_encoded = Utils.encode_base32(milliseconds: milliseconds, entropy: entropy)
    new(
      milliseconds: milliseconds,
      entropy: entropy,
      integer: base32_encoded.to_i(32),
      encoded: CrockfordBase32.from_base32(base32_encoded).freeze
    )
  end

  # Almost same as [.generate] except directly returning String without needless object creation
  #
  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [String]
  def self.encode(moment: Utils.current_milliseconds, entropy: Utils.reasonable_entropy)
    base32_encoded = Utils.encode_base32(milliseconds: Utils.milliseconds_from_moment(moment), entropy: entropy)
    CrockfordBase32.from_base32(base32_encoded)
  end

  # Short hand of `ULID.generate(moment: time)`
  # @param [Time] time
  # @return [ULID]
  def self.at(time)
    raise(ArgumentError, 'ULID.at takes only `Time` instance') unless Time === time

    generate(moment: time)
  end

  # @param [Time, Integer] moment
  # @return [ULID]
  def self.min(moment=0)
    0.equal?(moment) ? MIN : generate(moment: moment, entropy: 0)
  end

  # @param [Time, Integer] moment
  # @return [ULID]
  def self.max(moment=MAX_MILLISECONDS)
    MAX_MILLISECONDS.equal?(moment) ? MAX : generate(moment: moment, entropy: MAX_ENTROPY)
  end

  # @param [Range<Time>, Range<nil>, Range[ULID], nil] period
  # @overload sample(number, period: nil)
  #   @param [Integer] number
  #   @return [Array<ULID>]
  #   @raise [ArgumentError] if the given number is lager than `ULID spec limits` or `Possibilities of given period`, or given negative number
  # @overload sample(period: nil)
  #   @return [ULID]
  # @note Major difference of `Array#sample` interface is below
  #   * Do not ensure the uniqueness
  #   * Do not take random generator for the arguments
  #   * Raising error instead of truncating elements for the given number
  def self.sample(number=nil, period: nil)
    int_generator = (
      if period
        ulid_range = range(period)
        min, max, exclude_end = ulid_range.begin.to_i, ulid_range.end.to_i, ulid_range.exclude_end?

        possibilities = (max - min) + (exclude_end ? 0 : 1)
        raise(ArgumentError, "given range `#{ulid_range.inspect}` does not have possibilities") unless possibilities.positive?

        -> {
          SecureRandom.random_number(possibilities) + min
        }
      else
        RANDOM_INTEGER_GENERATOR
      end
    )

    case number
    when nil
      from_integer(int_generator.call)
    when Integer
      if number > MAX_INTEGER || number.negative?
        raise(ArgumentError, "given number `#{number}` is larger than ULID limit `#{MAX_INTEGER}` or negative")
      end

      if period && possibilities && (number > possibilities)
        raise(ArgumentError, "given number `#{number}` is larger than given possibilities `#{possibilities}`")
      end

      Array.new(number) { from_integer(int_generator.call) }
    else
      raise(ArgumentError, 'accepts no argument or integer only')
    end
  end

  # @param [String, #to_str] string
  # @return [Enumerator]
  # @yieldparam [ULID] ulid
  # @yieldreturn [self]
  def self.scan(string)
    string = String.try_convert(string)
    raise(ArgumentError, 'ULID.scan takes only strings') unless string
    return to_enum(:scan, string) unless block_given?

    string.scan(SCANNING_PATTERN) do |matched|
      if String === matched
        yield(parse(matched))
      end
    end
    self
  end

  # @param [Integer] integer
  # @return [ULID]
  # @raise [OverflowError] if the given integer is larger than the ULID limit
  # @raise [ArgumentError] if the given integer is negative number
  def self.from_integer(integer)
    raise(ArgumentError, 'ULID.from_integer takes only `Integer`') unless Integer === integer
    raise(OverflowError, "integer overflow: given #{integer}, max: #{MAX_INTEGER}") unless integer <= MAX_INTEGER
    raise(ArgumentError, "integer should not be negative: given: #{integer}") if integer.negative?

    base32encoded = integer.to_s(32).rjust(ENCODED_LENGTH, '0')
    base32encoded_timestamp = base32encoded.slice(0, TIMESTAMP_ENCODED_LENGTH)
    base32encoded_randomness = base32encoded.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH)

    raise(UnexpectedError) unless base32encoded_timestamp && base32encoded_randomness

    milliseconds = base32encoded_timestamp.to_i(32)
    entropy = base32encoded_randomness.to_i(32)

    new(
      milliseconds: milliseconds,
      entropy: entropy,
      integer: integer,
      encoded: CrockfordBase32.from_base32(base32encoded).freeze
    )
  end

  # @param [Range<Time>, Range<nil>, Range[ULID]] period
  # @return [Range<ULID>]
  # @raise [ArgumentError] if the given period is not a `Range[Time]`, `Range[nil]` or `Range[ULID]`
  def self.range(period)
    raise(ArgumentError, 'ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`') unless Range === period

    begin_element, end_element, exclude_end = period.begin, period.end, period.exclude_end?
    new_begin, new_end = false, false

    begin_ulid = (
      case begin_element
      when Time
        new_begin = true
        min(begin_element)
      when nil
        MIN
      when self
        begin_element
      else
        raise(ArgumentError, "ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`, given: #{period.inspect}")
      end
    )

    end_ulid = (
      case end_element
      when Time
        new_end = true
        exclude_end ? min(end_element) : max(end_element)
      when nil
        exclude_end = false
        # The end should be max and include end, because nil end means to cover endless ULIDs until the limit
        MAX
      when self
        end_element
      else
        raise(ArgumentError, "ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`, given: #{period.inspect}")
      end
    )

    begin_ulid.freeze if new_begin
    end_ulid.freeze if new_end

    Range.new(begin_ulid, end_ulid, exclude_end)
  end

  # @param [Time] time
  # @return [Time]
  def self.floor(time)
    raise(ArgumentError, 'ULID.floor takes only `Time` instance') unless Time === time

    time.floor(3)
  end

  # @param [String, #to_str] string
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for ULID specs
  def self.parse(string)
    string = String.try_convert(string)
    raise(ArgumentError, 'ULID.parse takes only strings') unless string

    unless STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(string)
      raise(ParserError, "given `#{string}` does not match to `#{STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.inspect}`")
    end

    from_integer(CrockfordBase32.decode(string))
  end

  # @param [String, #to_str] string
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for ULID specs
  def self.parse_variant_format(string)
    string = String.try_convert(string)
    raise(ArgumentError, 'ULID.parse_variant_format takes only strings') unless string

    normalized_in_crockford = CrockfordBase32.normalize(string)
    parse(normalized_in_crockford)
  end

  # Almost same as `ULID.parse(string).to_time` except directly returning Time instance without needless object creation
  #
  # @param [String, #to_str] string
  # @param [String, Integer, nil] in
  # @return [Time]
  # @raise [ParserError] if the given format is not correct for ULID specs
  def self.decode_time(string, in: 'UTC')
    in_for_time_at = binding.local_variable_get(:in) # Needed because `in` is a reserved word.
    string = String.try_convert(string)
    raise(ArgumentError, 'ULID.decode_time takes only strings') unless string

    unless STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(string)
      raise(ParserError, "given `#{string}` does not match to `#{STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.inspect}`")
    end

    timestamp = string.slice(0, TIMESTAMP_ENCODED_LENGTH).freeze || raise(UnexpectedError)

    Time.at(0, CrockfordBase32.decode(timestamp), :millisecond, in: in_for_time_at)
  end

  # @param [String, #to_str] string
  # @return [String]
  # @raise [ParserError] if the given format is not correct for ULID specs, even if ignored `orthographical variants of the format`
  def self.normalize(string)
    string = String.try_convert(string)
    raise(ArgumentError, 'ULID.normalize takes only strings') unless string

    # Ensure the ULID correctness, because CrockfordBase32 does not always mean to satisfy ULID format
    parse_variant_format(string).to_s
  end

  # @param [String, #to_str] string
  # @return [Boolean]
  def self.normalized?(string)
    normalized = normalize(string)
  rescue Exception
    false
  else
    normalized == string
  end

  # @param [String, #to_str] string
  # @return [Boolean]
  def self.valid_as_variant_format?(string)
    parse_variant_format(string)
  rescue Exception
    false
  else
    true
  end

  # @deprecated Use [.valid_as_variant_format?] or [.normalized?] instead
  #
  # Returns `true` if it is normalized string.
  # Basically the difference of normalized? is to accept downcase or not. This returns true for downcased ULIDs.
  #
  # @return [Boolean]
  def self.valid?(string)
    warn_kwargs = (RUBY_VERSION >= '3.0') ? { category: :deprecated } : {}
    Warning.warn('ULID.valid? is deprecated. Use ULID.valid_as_variant_format? or ULID.normalized? instead.', **warn_kwargs)
    string = String.try_convert(string)
    string ? STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(string) : false
  end

  # @param [ULID, #to_ulid] object
  # @return [ULID, nil]
  # @raise [TypeError] if `object.to_ulid` did not return ULID instance
  def self.try_convert(object)
    begin
      converted = object.to_ulid
    rescue NoMethodError
      nil
    else
      if ULID === converted
        converted
      else
        object_class_name = Utils.safe_get_class_name(object)
        converted_class_name = Utils.safe_get_class_name(converted)
        raise(TypeError, "can't convert #{object_class_name} to ULID (#{object_class_name}#to_ulid gives #{converted_class_name})")
      end
    end
  end

  attr_reader(:milliseconds, :entropy)

  # @return [String]
  def encode
    @encoded
  end
  alias_method(:to_s, :encode)

  # @return [Integer]
  def to_i
    @integer
  end

  # @return [Integer]
  def hash
    [ULID, @integer].hash
  end

  # @return [-1, 0, 1, nil]
  def <=>(other)
    (ULID === other) ? (@integer <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{@encoded})".freeze
  end

  # @return [Boolean]
  def eql?(other)
    equal?(other) || (ULID === other && @integer == other.to_i)
  end
  alias_method(:==, :eql?)

  # Return `true` for same value of ULID, variant formats of strings, same Time in ULID precision(msec).
  # Do not consider integer, octets and partial strings, then returns `false`.
  #
  # @return [Boolean]
  # @see .normalize
  # @see .floor
  def ===(other)
    case other
    when ULID
      @integer == other.to_i
    when String
      begin
        to_i == ULID.parse_variant_format(other).to_i
      rescue Exception
        false
      end
    when Time
      to_time == ULID.floor(other)
    else
      false
    end
  end

  # @return [Time]
  def to_time
    @time ||= Time.at(0, @milliseconds, :millisecond, in: 'UTC').freeze
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def octets
    digits = @integer.digits(256)
    (OCTETS_LENGTH - digits.size).times do
      digits.push(0)
    end
    digits.reverse!
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer)]
  def timestamp_octets
    octets.slice(0, TIMESTAMP_OCTETS_LENGTH) || raise(UnexpectedError)
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def randomness_octets
    octets.slice(TIMESTAMP_OCTETS_LENGTH, RANDOMNESS_OCTETS_LENGTH) || raise(UnexpectedError)
  end

  # @return [String]
  def timestamp
    @timestamp ||= (@encoded.slice(0, TIMESTAMP_ENCODED_LENGTH).freeze || raise(UnexpectedError))
  end

  # @return [String]
  def randomness
    @randomness ||= (@encoded.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH).freeze || raise(UnexpectedError))
  end

  # @note Providing for rough operations. The keys and values is not fixed.
  # @return [Hash{Symbol => Regexp, String}]
  def patterns
    named_captures = /(?<timestamp>#{timestamp})(?<randomness>#{randomness})/i.freeze
    {
      named_captures: named_captures,
      strict_named_captures: /\A#{named_captures.source}\z/i.freeze
    }
  end

  # @return [ULID, nil] when called on ULID as `7ZZZZZZZZZZZZZZZZZZZZZZZZZ`, returns `nil` instead of ULID
  def succ
    succ_int = @integer.succ
    if succ_int >= MAX_INTEGER
      if succ_int == MAX_INTEGER
        MAX
      else
        nil
      end
    else
      ULID.from_integer(succ_int)
    end
  end
  alias_method(:next, :succ)

  # @return [ULID, nil] when called on ULID as `00000000000000000000000000`, returns `nil` instead of ULID
  def pred
    pred_int = @integer.pred
    if pred_int <= 0
      if pred_int == 0
        MIN
      else
        nil
      end
    else
      ULID.from_integer(pred_int)
    end
  end

  # @return [self]
  def freeze
    # Need to cache before freezing, because frozen objects can't assign instance variables
    cache_all_instance_variables
    super
  end

  # @return [Integer]
  def marshal_dump
    @integer
  end

  # @param [Integer] integer
  # @return [void]
  def marshal_load(integer)
    unmarshaled = ULID.from_integer(integer)
    initialize(
      integer: unmarshaled.to_i,
      milliseconds: unmarshaled.milliseconds,
      entropy: unmarshaled.entropy,
      encoded: unmarshaled.to_s
    )
  end

  # @return [self]
  def to_ulid
    self
  end

  # @return [self]
  def dup
    self
  end

  # @return [self]
  def clone(freeze: true)
    self
  end

  undef_method(:instance_variable_set)

  private

  # @param [Integer] milliseconds
  # @param [Integer] entropy
  # @param [Integer] integer
  # @param [String] encoded
  # @return [void]
  def initialize(milliseconds:, entropy:, integer:, encoded:)
    # All arguments check should be done with each constructors, not here
    @integer = integer
    @encoded = encoded
    @milliseconds = milliseconds
    @entropy = entropy
  end

  # @return [void]
  def cache_all_instance_variables
    inspect
    timestamp
    randomness
  end
end

require_relative('ulid/ractor_unshareable_constants')
