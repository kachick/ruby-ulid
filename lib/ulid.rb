# coding: us-ascii
# frozen_string_literal: true

# Copyright (C) 2021 Kenichi Kamiya

require('securerandom')

require_relative('ulid/version')
require_relative('ulid/errors')
require_relative('ulid/crockford_base32')
require_relative('ulid/utils')
require_relative('ulid/uuid')
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

  OCTETS_LENGTH = 16

  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175
  MAX_INTEGER = 340282366920938463463374607431768211455

  # @see https://github.com/ulid/spec/pull/57
  # Currently not used as a constant, but kept as a reference for now.
  PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /(?<timestamp>[0-7][#{CrockfordBase32::ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}})(?<randomness>[#{CrockfordBase32::ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}})/i

  STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /\A#{PATTERN_WITH_CROCKFORD_BASE32_SUBSET.source}\z/i

  # Optimized for `ULID.scan`, might be changed the definition with gathered `ULID.scan` spec changed.
  SCANNING_PATTERN = /\b[0-7][#{CrockfordBase32::ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}}[#{CrockfordBase32::ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}}\b/i

  # Similar as Time#inspect since Ruby 2.7, however it is NOT same.
  # Time#inspect trancates needless digits. Keeping full milliseconds with "%3N" will fit for ULID.
  # @see https://bugs.ruby-lang.org/issues/15958
  # @see https://github.com/ruby/ruby/blob/744d17ff6c33b09334508e8110007ea2a82252f5/time.c#L4026-L4078
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  RANDOM_INTEGER_GENERATOR = -> {
    SecureRandom.random_number(MAX_INTEGER)
  }.freeze

  Utils.make_sharable_constants(self)

  private_constant(
    :PATTERN_WITH_CROCKFORD_BASE32_SUBSET,
    :STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET,
    :SCANNING_PATTERN,
    :TIME_FORMAT_IN_INSPECT,
    :RANDOM_INTEGER_GENERATOR,
    :OCTETS_LENGTH,
    :UUID
  )

  private_class_method(:new, :allocate)

  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [ULID]
  # @raise [OverflowError] if the given value is larger than the ULID limit
  # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
  def self.generate(moment: Utils.current_milliseconds, entropy: Utils.reasonable_entropy)
    milliseconds = Utils.milliseconds_from_moment(moment)
    base32hex = Utils.encode_base32hex(milliseconds:, entropy:)
    new(
      milliseconds:,
      entropy:,
      integer: Integer(base32hex, 32, exception: true),
      encoded: CrockfordBase32.from_base32hex(base32hex).freeze
    )
  end

  # Almost same as [.generate] except directly returning String without needless object creation
  #
  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [String]
  def self.encode(moment: Utils.current_milliseconds, entropy: Utils.reasonable_entropy)
    base32hex = Utils.encode_base32hex(milliseconds: Utils.milliseconds_from_moment(moment), entropy:)
    CrockfordBase32.from_base32hex(base32hex)
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
    0.equal?(moment) ? MIN : generate(moment:, entropy: 0)
  end

  # @param [Time, Integer] moment
  # @return [ULID]
  def self.max(moment=MAX_MILLISECONDS)
    MAX_MILLISECONDS.equal?(moment) ? MAX : generate(moment:, entropy: MAX_ENTROPY)
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

    base32hex = integer.to_s(32).rjust(ENCODED_LENGTH, '0')
    base32hex_timestamp = base32hex.slice(0, TIMESTAMP_ENCODED_LENGTH)
    base32hex_randomness = base32hex.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH)

    raise(UnexpectedError) unless base32hex_timestamp && base32hex_randomness

    milliseconds = Integer(base32hex_timestamp, 32, exception: true)
    entropy = Integer(base32hex_randomness, 32, exception: true)

    new(
      milliseconds:,
      entropy:,
      integer:,
      encoded: CrockfordBase32.from_base32hex(base32hex).freeze
    )
  end

  # @param [Range<Time>, Range<nil>, Range[ULID]] period
  # @return [Range<ULID>]
  # @raise [ArgumentError] if the given period is not a `Range[Time]`, `Range[nil]` or `Range[ULID]`
  def self.range(period)
    raise(ArgumentError, 'ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`') unless Range === period

    begin_element, end_element, exclude_end = period.begin, period.end, period.exclude_end?

    begin_ulid = (
      case begin_element
      when Time
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
    in_for_time_at = { in: }.fetch(:in)
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
    parse_variant_format(string).encode
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

  # @param [String, #to_str] uuidish
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for UUID`ish` format
  def self.from_uuidish(uuidish)
    from_integer(UUID.parse_without_version_to_int(uuidish))
  end

  # @param [String, #to_str] uuid
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for UUIDv4 specs
  def self.from_uuidv4(uuid)
    from_integer(UUID.parse_v4_to_int(uuid))
  end

  attr_reader(:milliseconds, :entropy, :encoded)
  protected(:encoded)

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
    freeze
  end

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
    "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{@encoded})"
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
  # @param [String, Integer, nil] in
  def to_time(in: 'UTC')
    Time.at(0, @milliseconds, :millisecond, in: { in: }.fetch(:in))
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def bytes
    digits = @integer.digits(256)
    digits.fill(0, digits.size, OCTETS_LENGTH - digits.size).reverse
  end
  # @deprecated Use [#bytes] instead
  alias_method(:octets, :bytes)

  # @return [String]
  def timestamp
    @encoded.slice(0, TIMESTAMP_ENCODED_LENGTH) || raise(UnexpectedError)
  end

  # @return [String]
  def randomness
    @encoded.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH) || raise(UnexpectedError)
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
      encoded: unmarshaled.encoded
    )
  end

  # @return [self]
  def to_ulid
    self
  end

  # Provided for ULID and UUID converting vice versa with ignoring UUID version and variant spec
  # @return [String]
  def to_uuidish
    UUID::Fields.raw_from_bytes(bytes).to_s.freeze
  end

  # Convert the ULID to UUIDv4 with setting ULID version and variants field
  # @raise [IrreversibleUUIDError] if the converted UUID cannot be reversible with the replacing above 2 fields
  # @see https://github.com/kachick/ruby-ulid/issues/76
  # @param [bool] ignore_reversible
  # @return [String]
  def to_uuidv4(ignore_reversible: false)
    v4 = UUID::Fields.forced_v4_from_bytes(bytes)
    unless ignore_reversible
      uuidish = UUID::Fields.raw_from_bytes(bytes)
      raise(IrreversibleUUIDError) unless (uuidish == v4)
    end

    v4.to_s.freeze
  end

  # @return [ULID]
  def dup
    super.freeze
  end

  # @return [ULID]
  def clone(freeze: true)
    raise(ArgumentError, 'unfreezing ULID is an unexpected operation') unless freeze == true

    super
  end

  MIN = parse('00000000000000000000000000')
  MAX = parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ')

  Ractor.make_shareable(MIN)
  Ractor.make_shareable(MAX)

  private_constant(:MIN, :MAX)
end
