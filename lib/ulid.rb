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
  class SetupError < ScriptError; end

  # `Subset` of Crockford's Base32. Just excluded I, L, O, U, -.
  # refs:
  #   * https://www.crockford.com/base32.html
  #   * https://github.com/ulid/spec/pull/57
  #   * https://github.com/kachick/ruby-ulid/issues/57
  encoding_string = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
  encoding_chars = encoding_string.chars.map(&:freeze).freeze

  TIMESTAMP_ENCODED_LENGTH = 10
  RANDOMNESS_ENCODED_LENGTH = 16
  ENCODED_LENGTH = TIMESTAMP_ENCODED_LENGTH + RANDOMNESS_ENCODED_LENGTH
  TIMESTAMP_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = TIMESTAMP_OCTETS_LENGTH + RANDOMNESS_OCTETS_LENGTH
  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175
  MAX_INTEGER = 340282366920938463463374607431768211455
  PATTERN = /(?<timestamp>[0-7][#{encoding_string}]{#{TIMESTAMP_ENCODED_LENGTH - 1}})(?<randomness>[#{encoding_string}]{#{RANDOMNESS_ENCODED_LENGTH}})/i.freeze
  STRICT_PATTERN = /\A#{PATTERN.source}\z/i.freeze

  # Same as Time#inspect since Ruby 2.7, just to keep backward compatibility
  # @see https://bugs.ruby-lang.org/issues/15958
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  UNDEFINED = BasicObject.new
  # @return [String]
  def UNDEFINED.to_s
    'ULID::UNDEFINED'
  end

  # @return [String]
  def UNDEFINED.inspect
    to_s
  end
  Kernel.instance_method(:freeze).bind(UNDEFINED).call

  private_class_method :new

  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [ULID]
  def self.generate(moment: current_milliseconds, entropy: reasonable_entropy)
    new milliseconds: milliseconds_from_moment(moment), entropy: entropy
  end

  # Short hand of `ULID.generate(moment: time)`
  # @param [Time] time
  # @return [ULID]
  def self.at(time)
    raise ArgumentError, 'ULID.at takes only `Time` instance' unless Time === time
    new milliseconds: milliseconds_from_time(time), entropy: reasonable_entropy
  end

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.min(moment: 0)
    0.equal?(moment) ? MIN : generate(moment: moment, entropy: 0)
  end

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.max(moment: MAX_MILLISECONDS)
    MAX_MILLISECONDS.equal?(moment) ? MAX : generate(moment: moment, entropy: MAX_ENTROPY)
  end

  # @param [Integer] number
  # @return [ULID, Array<ULID>]
  # @raise [ArgumentError] if the given number is lager than ULID spec limits or given negative number 
  # @note Major difference of `Array#sample` interface is below
  #   * Do not ensure the uniqueness
  #   * Do not take random generator for the arguments
  #   * Raising error instead of truncating elements for the given number
  def self.sample(number=UNDEFINED)
    if UNDEFINED.equal?(number)
      from_integer(SecureRandom.random_number(MAX_INTEGER))
    else
      begin
        int = number.to_int
      rescue
         # Can not use `number.to_s` and `number.inspect` for considering BasicObject here
        raise TypeError, 'accepts no argument or integer only'
      end

      if int > MAX_INTEGER || int.negative?
        raise ArgumentError, "given number is larger than ULID limit #{MAX_INTEGER} or negative: #{number.inspect}"
      end
      int.times.map { from_integer(SecureRandom.random_number(MAX_INTEGER)) }
    end
  end

  # @param [String, #to_str] string
  # @return [Enumerator]
  # @yieldparam [ULID] ulid
  # @yieldreturn [self]
  def self.scan(string)
    string = string.to_str
    return to_enum(__callee__, string) unless block_given?
    string.scan(PATTERN) do |pair|
      yield parse(pair.join)
    end
    self
  end

  # @param [Integer, #to_int] integer
  # @return [ULID]
  # @raise [OverflowError] if the given integer is larger than the ULID limit
  # @raise [ArgumentError] if the given integer is negative number
  def self.from_integer(integer)
    integer = integer.to_int
    raise OverflowError, "integer overflow: given #{integer}, max: #{MAX_INTEGER}" unless integer <= MAX_INTEGER
    raise ArgumentError, "integer should not be negative: given: #{integer}" if integer.negative?

    n32encoded = integer.to_s(32).rjust(ENCODED_LENGTH, '0')
    n32encoded_timestamp = n32encoded.slice(0, TIMESTAMP_ENCODED_LENGTH)
    n32encoded_randomness = n32encoded.slice(TIMESTAMP_ENCODED_LENGTH, RANDOMNESS_ENCODED_LENGTH)

    milliseconds = n32encoded_timestamp.to_i(32)
    entropy = n32encoded_randomness.to_i(32)

    new milliseconds: milliseconds, entropy: entropy, integer: integer
  end

  # @param [Range<Time>, Range<nil>] time_range
  # @return [Range<ULID>]
  # @raise [ArgumentError] if the given time_range is not a `Range[Time]` or `Range[nil]`
  def self.range(time_range)
    raise argument_error_for_range_building(time_range) unless time_range.kind_of?(Range)
    begin_time, end_time, exclude_end = time_range.begin, time_range.end, time_range.exclude_end?

    case begin_time
    when Time
      begin_ulid = min(moment: begin_time)
    when nil
      begin_ulid = MIN
    else
      raise argument_error_for_range_building(time_range)
    end

    case end_time
    when Time
      if exclude_end
        end_ulid = min(moment: end_time)
      else
        end_ulid = max(moment: end_time)
      end
    when nil
      # The end should be max and include end, because nil end means to cover endless ULIDs until the limit
      end_ulid = MAX
      exclude_end = false
    else
      raise argument_error_for_range_building(time_range)
    end

    begin_ulid.freeze
    end_ulid.freeze

    Range.new(begin_ulid, end_ulid, exclude_end)
  end

  # @param [Time] time
  # @return [Time]
  def self.floor(time)
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

  # @api private
  # @param [Time] time
  # @return [Integer]
  def self.milliseconds_from_time(time)
    (time.to_r * 1000).to_i
  end

  # @api private
  # @param [Time, Integer] moment
  # @return [Integer]
  def self.milliseconds_from_moment(moment)
    moment.kind_of?(Time) ? milliseconds_from_time(moment) : moment.to_int
  end

  # @api private
  # @return [Integer]
  def self.reasonable_entropy
    SecureRandom.random_number(MAX_ENTROPY)
  end

  n32_chars = [*'0'..'9', *'A'..'V'].map(&:freeze).freeze
  raise SetupError, 'obvious bug exists in the mapping algorithm' unless n32_chars.size == 32

  n32_char_by_number = {}
  n32_chars.each_with_index do |char, index|
    n32_char_by_number[index] = char
  end
  n32_char_by_number.freeze

  # Currently supporting only for `subset for actual use-case`
  # See below
  #   * https://github.com/ulid/spec/pull/57
  #   * https://github.com/kachick/ruby-ulid/issues/57
  #   * https://github.com/kachick/ruby-ulid/issues/78
  crockford_base32_mappings = {
    'J' => 18,
    'K' => 19,
    'M' => 20,
    'N' => 21,
    'P' => 22,
    'Q' => 23,
    'R' => 24,
    'S' => 25,
    'T' => 26,
    'V' => 27,
    'W' => 28,
    'X' => 29,
    'Y' => 30,
    'Z' => 31
  }.freeze

  N32_CHAR_BY_CROCKFORD_BASE32_CHAR = encoding_chars.each_with_object({}) do |encoding_char, map|
    if n = crockford_base32_mappings[encoding_char]
      char_32 = n32_char_by_number.fetch(n)
      map[encoding_char] = char_32
    end
  end.freeze
  raise SetupError, 'obvious bug exists in the mapping algorithm' unless N32_CHAR_BY_CROCKFORD_BASE32_CHAR.keys == crockford_base32_mappings.keys
  CROCKFORD_BASE32_CHAR_PATTERN = /[#{N32_CHAR_BY_CROCKFORD_BASE32_CHAR.keys.join}]/.freeze

  CROCKFORD_BASE32_CHAR_BY_N32_CHAR = N32_CHAR_BY_CROCKFORD_BASE32_CHAR.invert.freeze
  N32_CHAR_PATTERN = /[#{CROCKFORD_BASE32_CHAR_BY_N32_CHAR.keys.join}]/.freeze

  # @param [String, #to_str] string
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for ULID specs
  def self.parse(string)
    begin
      string = string.to_str
      raise "given argument does not match to `#{STRICT_PATTERN.inspect}`" unless STRICT_PATTERN.match?(string)
    rescue => err
      raise ParserError, "parsing failure as #{err.inspect} for given #{string.inspect}"
    end

    n32encoded = string.upcase.gsub(CROCKFORD_BASE32_CHAR_PATTERN, N32_CHAR_BY_CROCKFORD_BASE32_CHAR)
    from_integer(n32encoded.to_i(32))
  end

  # @return [Boolean]
  def self.valid?(string)
    parse(string)
  rescue Exception
    false
  else
    true
  end

  # @api private
  # @see The logics taken from https://bugs.ruby-lang.org/issues/14401, thanks!
  # @param [Array<Integer>] reversed_digits
  # @return [Integer]
  def self.inverse_of_digits(reversed_digits)
    base = 256
    num = 0
    reversed_digits.each do |digit|
      num = (num * base) + digit
    end
    num
  end

  # @api private
  # @param [MonotonicGenerator] generator
  # @return [ULID]
  def self.from_monotonic_generator(generator)
    raise ArgumentError, 'this method provided only for MonotonicGenerator' unless MonotonicGenerator === generator
    new milliseconds: generator.latest_milliseconds, entropy: generator.latest_entropy
  end

  # @api private
  # @return [ArgumentError]
  private_class_method def self.argument_error_for_range_building(argument)
    ArgumentError.new "ULID.range takes only `Range[Time]` or `Range[nil]`, given: #{argument.inspect}"
  end

  attr_reader :milliseconds, :entropy

  # @api private
  # @param [Integer] milliseconds
  # @param [Integer] entropy
  # @param [Integer] integer
  # @return [void]
  # @raise [OverflowError] if the given value is larger than the ULID limit
  # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
  def initialize(milliseconds:, entropy:, integer: UNDEFINED)
    if UNDEFINED.equal?(integer)
      milliseconds = milliseconds.to_int
      entropy = entropy.to_int

      raise OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}" unless milliseconds <= MAX_MILLISECONDS
      raise OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}" unless entropy <= MAX_ENTROPY
      raise ArgumentError, 'milliseconds and entropy should not be negative' if milliseconds.negative? || entropy.negative?
    else
      @integer = integer
    end

    @milliseconds = milliseconds
    @entropy = entropy
  end

  # @return [String]
  def to_s
    @string ||= to_i.to_s(32).upcase.gsub(N32_CHAR_PATTERN, CROCKFORD_BASE32_CHAR_BY_N32_CHAR).rjust(ENCODED_LENGTH, '0').freeze
  end

  # @return [Integer]
  def to_i
    @integer ||= begin
      n32encoded_timestamp = milliseconds.to_s(32).rjust(TIMESTAMP_ENCODED_LENGTH, '0')
      n32encoded_randomness = entropy.to_s(32).rjust(RANDOMNESS_ENCODED_LENGTH, '0')
      (n32encoded_timestamp + n32encoded_randomness).to_i(32)
    end
  end
  alias_method :hash, :to_i

  # @return [Integer, nil]
  def <=>(other)
    (ULID === other) ? (to_i <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{to_s})".freeze
  end

  # @return [Boolean]
  def eql?(other)
    equal?(other) || (ULID === other && to_i == other.to_i)
  end
  alias_method :==, :eql?

  # @return [Boolean]
  def ===(other)
    case other
    when ULID
      self == other
    when String
      begin
        self == self.class.parse(other)
      rescue Exception
        false
      end
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
    @octets ||= octets_from_integer(to_i).freeze
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer)]
  def timestamp_octets
    @timestamp_octets ||= octets.slice(0, TIMESTAMP_OCTETS_LENGTH).freeze
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def randomness_octets
    @randomness_octets ||= octets.slice(TIMESTAMP_OCTETS_LENGTH, RANDOMNESS_OCTETS_LENGTH).freeze
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

  # @deprecated Use {#patterns} instead. ref: https://github.com/kachick/ruby-ulid/issues/84
  # @return [Regexp]
  def pattern
    patterns.fetch(:named_captures)
  end

  # @deprecated Use {#patterns} instead. ref: https://github.com/kachick/ruby-ulid/issues/84
  # @return [Regexp]
  def strict_pattern
    patterns.fetch(:strict_named_captures)
  end

  # @return [ULID, nil] when called on ULID as `7ZZZZZZZZZZZZZZZZZZZZZZZZZ`, returns `nil` instead of ULID
  def next
    next_int = to_i.next
    return nil if next_int > MAX_INTEGER
    @next ||= self.class.from_integer(next_int)
  end
  alias_method :succ, :next

  # @return [ULID, nil] when called on ULID as `00000000000000000000000000`, returns `nil` instead of ULID
  def pred
    pre_int = to_i.pred
    return nil if pre_int.negative?
    @pred ||= self.class.from_integer(pre_int)
  end

  # @return [self]
  def freeze
    # Need to cache before freezing, because frozen objects can't assign instance variables
    cache_all_instance_variables
    super
  end

  private

  # @param [Integer] integer
  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def octets_from_integer(integer)
    digits = integer.digits(256)
    (OCTETS_LENGTH - digits.size).times do
      digits.push 0
    end
    digits.reverse!
  end

  # @return [void]
  def cache_all_instance_variables
    inspect
    octets
    to_i
    succ
    pred
    timestamp
    randomness
  end
end

require_relative 'ulid/version'
require_relative 'ulid/monotonic_generator'

class ULID
  MIN = parse('00000000000000000000000000').freeze
  MAX = parse('7ZZZZZZZZZZZZZZZZZZZZZZZZZ').freeze

  private_constant :TIME_FORMAT_IN_INSPECT, :MIN, :MAX, :CROCKFORD_BASE32_CHAR_PATTERN, :N32_CHAR_BY_CROCKFORD_BASE32_CHAR, :CROCKFORD_BASE32_CHAR_BY_N32_CHAR, :N32_CHAR_PATTERN, :UNDEFINED
end
