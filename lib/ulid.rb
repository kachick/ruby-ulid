# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

require 'securerandom'

# @see https://github.com/ulid/spec
# @!attribute [r] milliseconds
#   @return [Integer]
# @!attribute [r] entropy
#   @return [Integer]
class ULID
  include Comparable

  class Error < StandardError; end
  class OverflowError < Error; end
  class ParserError < Error; end

  # Excluded I, L, O, U, -.
  # This is the encoding patterns.
  # The decoding issue is written in ULID::CrockfordBase32
  CROCKFORD_BASE32_ENCODING_STRING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'

  TIMESTAMP_ENCODED_LENGTH = 10
  RANDOMNESS_ENCODED_LENGTH = 16
  ENCODED_LENGTH = TIMESTAMP_ENCODED_LENGTH + RANDOMNESS_ENCODED_LENGTH
  TIMESTAMP_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = TIMESTAMP_OCTETS_LENGTH + RANDOMNESS_OCTETS_LENGTH
  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175
  MAX_INTEGER = 340282366920938463463374607431768211455

  # @see https://github.com/ulid/spec/pull/57
  # Currently not used as a constant, but kept as a reference for now.
  PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /(?<timestamp>[0-7][#{CROCKFORD_BASE32_ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}})(?<randomness>[#{CROCKFORD_BASE32_ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}})/i.freeze

  STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET = /\A#{PATTERN_WITH_CROCKFORD_BASE32_SUBSET.source}\z/i.freeze

  # Optimized for `ULID.scan`, might be changed the definition with gathered `ULID.scan` spec changed.
  # This can't contain `\b` for considering UTF-8 (e.g. Japanese), so intentional `false negative` definition.
  SCANNING_PATTERN = /[0-7][#{CROCKFORD_BASE32_ENCODING_STRING}]{#{TIMESTAMP_ENCODED_LENGTH - 1}}[#{CROCKFORD_BASE32_ENCODING_STRING}]{#{RANDOMNESS_ENCODED_LENGTH}}/i.freeze

  # Same as Time#inspect since Ruby 2.7, just to keep backward compatibility
  # @see https://bugs.ruby-lang.org/issues/15958
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  private_class_method :new

  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [ULID]
  def self.generate(moment: current_milliseconds, entropy: reasonable_entropy)
    from_milliseconds_and_entropy(milliseconds: milliseconds_from_moment(moment), entropy: entropy)
  end

  # Short hand of `ULID.generate(moment: time)`
  # @param [Time] time
  # @return [ULID]
  def self.at(time)
    raise ArgumentError, 'ULID.at takes only `Time` instance' unless Time === time
    from_milliseconds_and_entropy(milliseconds: milliseconds_from_time(time), entropy: reasonable_entropy)
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

  RANDOM_INTEGER_GENERATOR = -> {
    SecureRandom.random_number(MAX_INTEGER)
  }

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
  def self.sample(*args, period: nil)
    int_generator = if period
      ulid_range = range(period)
      min, max, exclude_end = ulid_range.begin.to_i, ulid_range.end.to_i, ulid_range.exclude_end?

      possibilities = (max - min) + (exclude_end ? 0 : 1)
      raise ArgumentError, "given range `#{ulid_range.inspect}` does not have possibilities" unless possibilities.positive?

      -> {
        SecureRandom.random_number(possibilities) + min
      }
    else
      RANDOM_INTEGER_GENERATOR
    end

    case args.size
    when 0
      from_integer(int_generator.call)
    when 1
      number = args.first
      raise ArgumentError, 'accepts no argument or integer only' unless Integer === number

      if number > MAX_INTEGER || number.negative?
        raise ArgumentError, "given number `#{number}` is larger than ULID limit `#{MAX_INTEGER}` or negative"
      end

      if period && (number > possibilities)
        raise ArgumentError, "given number `#{number}` is larger than given possibilities `#{possibilities}`"
      end

      Array.new(number) { from_integer(int_generator.call) }
    else
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..1)"
    end
  end

  # @param [String, #to_str] string
  # @return [Enumerator]
  # @yieldparam [ULID] ulid
  # @yieldreturn [self]
  def self.scan(string)
    string = String.try_convert(string)
    raise ArgumentError, 'ULID.scan takes only strings' unless string
    return to_enum(__callee__, string) unless block_given?
    string.scan(SCANNING_PATTERN) do |matched|
      yield parse(matched)
    end
    self
  end

  # @param [Integer] integer
  # @return [ULID]
  # @raise [OverflowError] if the given integer is larger than the ULID limit
  # @raise [ArgumentError] if the given integer is negative number
  def self.from_integer(integer)
    raise ArgumentError, 'ULID.from_integer takes only `Integer`' unless Integer === integer
    raise OverflowError, "integer overflow: given #{integer}, max: #{MAX_INTEGER}" unless integer <= MAX_INTEGER
    raise ArgumentError, "integer should not be negative: given: #{integer}" if integer.negative?

    n32encoded = integer.to_s(32).rjust(ENCODED_LENGTH, '0')
    n32encoded_timestamp = n32encoded.slice(0, TIMESTAMP_ENCODED_LENGTH)
    n32encoded_randomness = n32encoded.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH)

    milliseconds = n32encoded_timestamp.to_i(32)
    entropy = n32encoded_randomness.to_i(32)

    new milliseconds: milliseconds, entropy: entropy, integer: integer
  end

  # @param [Range<Time>, Range<nil>, Range[ULID]] period
  # @return [Range<ULID>]
  # @raise [ArgumentError] if the given period is not a `Range[Time]`, `Range[nil]` or `Range[ULID]`
  def self.range(period)
    raise ArgumentError, 'ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`' unless Range === period
    begin_element, end_element, exclude_end = period.begin, period.end, period.exclude_end?
    return period if self === begin_element && self === end_element

    case begin_element
    when Time
      begin_ulid = min(begin_element)
    when nil
      begin_ulid = MIN
    when self
      begin_ulid = begin_element
    else
      raise ArgumentError, "ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`, given: #{period.inspect}"
    end

    case end_element
    when Time
      if exclude_end
        end_ulid = min(end_element)
      else
        end_ulid = max(end_element)
      end
    when nil
      # The end should be max and include end, because nil end means to cover endless ULIDs until the limit
      end_ulid = MAX
      exclude_end = false
    when self
      end_ulid = end_element
    else
      raise ArgumentError, "ULID.range takes only `Range[Time]`, `Range[nil]` or `Range[ULID]`, given: #{period.inspect}"
    end

    begin_ulid.freeze
    end_ulid.freeze

    Range.new(begin_ulid, end_ulid, exclude_end)
  end

  # @param [Time] time
  # @return [Time]
  def self.floor(time)
    raise ArgumentError, 'ULID.floor takes only `Time` instance' unless Time === time

    if RUBY_VERSION >= '2.7'
      time.floor(3)
    else
      Time.at(0, milliseconds_from_time(time), :millisecond)
    end
  end

  # @api private
  # @return [Integer]
  def self.current_milliseconds
    milliseconds_from_time(Time.now)
  end

  # @param [Time] time
  # @return [Integer]
  private_class_method def self.milliseconds_from_time(time)
    (time.to_r * 1000).to_i
  end

  # @api private
  # @param [Time, Integer] moment
  # @return [Integer]
  def self.milliseconds_from_moment(moment)
    case moment
    when Integer
      moment
    when Time
      milliseconds_from_time(moment)
    else
      raise ArgumentError, '`moment` should be a `Time` or `Integer as milliseconds`'
    end
  end

  # @api private
  # @return [Integer]
  def self.reasonable_entropy
    SecureRandom.random_number(MAX_ENTROPY)
  end

  # @param [String, #to_str] string
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for ULID specs
  def self.parse(string)
    string = String.try_convert(string)
    raise ArgumentError, 'ULID.parse takes only strings' unless string

    unless STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(string)
      raise ParserError, "given `#{string}` does not match to `#{STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.inspect}`"
    end

    from_integer(CrockfordBase32.decode(string))
  end

  # @param [String, #to_str] string
  # @return [Boolean]
  def self.valid?(string)
    string = String.try_convert(string)
    string ? STRICT_PATTERN_WITH_CROCKFORD_BASE32_SUBSET.match?(string) : false
  end

  # @api private
  # @param [Integer] milliseconds
  # @param [Integer] entropy
  # @return [ULID]
  # @raise [OverflowError] if the given value is larger than the ULID limit
  # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
  def self.from_milliseconds_and_entropy(milliseconds:, entropy:)
    raise ArgumentError, 'milliseconds and entropy should be an `Integer`' unless Integer === milliseconds && Integer === entropy
    raise OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}" unless milliseconds <= MAX_MILLISECONDS
    raise OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}" unless entropy <= MAX_ENTROPY
    raise ArgumentError, 'milliseconds and entropy should not be negative' if milliseconds.negative? || entropy.negative?

    n32encoded_timestamp = milliseconds.to_s(32).rjust(TIMESTAMP_ENCODED_LENGTH, '0')
    n32encoded_randomness = entropy.to_s(32).rjust(RANDOMNESS_ENCODED_LENGTH, '0')
    integer = (n32encoded_timestamp + n32encoded_randomness).to_i(32)

    new milliseconds: milliseconds, entropy: entropy, integer: integer
  end

  attr_reader :milliseconds, :entropy

  # @api private
  # @param [Integer] milliseconds
  # @param [Integer] entropy
  # @param [Integer] integer
  # @return [void]
  def initialize(milliseconds:, entropy:, integer:)
    # All arguments check should be done with each constructors, not here
    @integer = integer
    @milliseconds = milliseconds
    @entropy = entropy
  end

  # @return [String]
  def to_s
    @string ||= CrockfordBase32.encode(@integer).freeze
  end

  # @return [Integer]
  def to_i
    @integer
  end
  alias_method :hash, :to_i

  # @return [Integer, nil]
  def <=>(other)
    (ULID === other) ? (@integer <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{to_s})".freeze
  end

  # @return [Boolean]
  def eql?(other)
    equal?(other) || (ULID === other && @integer == other.to_i)
  end
  alias_method :==, :eql?

  # @return [Boolean]
  def ===(other)
    case other
    when ULID
      @integer == other.to_i
    when String
      to_s == other.upcase
    else
      false
    end
  end

  # @return [Time]
  def to_time
    @time ||= begin
      if RUBY_VERSION >= '2.7'
        Time.at(0, @milliseconds, :millisecond, in: 'UTC').freeze
      else
        Time.at(0, @milliseconds, :millisecond).utc.freeze
      end
    end
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def octets
    digits = @integer.digits(256)
    (OCTETS_LENGTH - digits.size).times do
      digits.push 0
    end
    digits.reverse!
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer)]
  def timestamp_octets
    octets.slice(0, TIMESTAMP_OCTETS_LENGTH)
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def randomness_octets
    octets.slice(TIMESTAMP_OCTETS_LENGTH, RANDOMNESS_OCTETS_LENGTH)
  end

  # @return [String]
  def timestamp
    @timestamp ||= to_s.slice(0, TIMESTAMP_ENCODED_LENGTH).freeze
  end

  # @return [String]
  def randomness
    @randomness ||= to_s.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH).freeze
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
  alias_method :next, :succ

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

  # @return [self]
  def dup
    self
  end

  # @return [self]
  def clone(freeze: true)
    self
  end

  undef_method :instance_variable_set

  private

  # @return [void]
  def cache_all_instance_variables
    inspect
    timestamp
    randomness
  end
end

require_relative 'ulid/version'
require_relative 'ulid/crockford_base32'
require_relative 'ulid/monotonic_generator'

class ULID
  MIN = parse('00000000000000000000000000').freeze
  MAX = parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ').freeze

  private_constant :TIME_FORMAT_IN_INSPECT, :MIN, :MAX, :RANDOM_INTEGER_GENERATOR
end
