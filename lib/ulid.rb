# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

require 'securerandom'
require 'integer/base'

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

  encoding_string = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
  # Crockford's Base32. Excluded I, L, O, U.
  # @see https://www.crockford.com/base32.html
  ENCODING_CHARS = encoding_string.chars.map(&:freeze).freeze

  TIMESTAMP_PART_LENGTH = 10
  RANDOMNESS_PART_LENGTH = 16
  ENCODED_ID_LENGTH = TIMESTAMP_PART_LENGTH + RANDOMNESS_PART_LENGTH
  TIMESTAMP_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = TIMESTAMP_OCTETS_LENGTH + RANDOMNESS_OCTETS_LENGTH
  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175
  MAX_INTEGER = 340282366920938463463374607431768211455
  PATTERN = /(?<timestamp>[0-7][#{encoding_string}]{#{TIMESTAMP_PART_LENGTH - 1}})(?<randomness>[#{encoding_string}]{#{RANDOMNESS_PART_LENGTH}})/i.freeze
  STRICT_PATTERN = /\A#{PATTERN.source}\z/i.freeze

  # Imported from https://stackoverflow.com/a/38191104/1212807, thank you!
  UUIDV4_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i

  # Same as Time#inspect since Ruby 2.7, just to keep backward compatibility
  # @see https://bugs.ruby-lang.org/issues/15958
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  # @param [Integer, Time] moment
  # @param [Integer] entropy
  # @return [ULID]
  def self.generate(moment: current_milliseconds, entropy: reasonable_entropy)
    new milliseconds: milliseconds_from_moment(moment), entropy: entropy
  end

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.min(moment: 0)
    generate(moment: moment, entropy: 0)
  end

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.max(moment: MAX_MILLISECONDS)
    generate(moment: moment, entropy: MAX_ENTROPY)
  end

  # @deprecated This method actually changes class state. Use {ULID::MonotonicGenerator} instead.
  # @raise [OverflowError] if the entropy part is larger than the ULID limit in same milliseconds
  # @return [ULID]
  def self.monotonic_generate
    warning = "`ULID.monotonic_generate` actually changes class state. Use `ULID::MonotonicGenerator` instead."
    if RUBY_VERSION >= '3.0'
      Warning.warn(warning, category: :deprecated)
    else
      Warning.warn(warning)
    end

    MONOTONIC_GENERATOR.generate
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

  # @param [String, #to_str] uuid
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for UUIDv4 specs
  def self.from_uuidv4(uuid)
    begin
      uuid = uuid.to_str
      prefix_trimmed = uuid.sub(/\Aurn:uuid:/, '')
      raise "given string is not matched to pattern #{UUIDV4_PATTERN.inspect}" unless UUIDV4_PATTERN.match?(prefix_trimmed)
      normalized = prefix_trimmed.gsub(/[^0-9A-Fa-f]/, '')
      from_integer(normalized.to_i(16))
    rescue => err
      raise ParserError, "parsing failure as #{err.inspect} for given #{uuid}"
    end
  end

  # @param [Integer, #to_int] integer
  # @return [ULID]
  # @raise [OverflowError] if the given integer is larger than the ULID limit
  # @raise [ArgumentError] if the given integer is negative number
  # @todo Need optimized for performance
  def self.from_integer(integer)
    integer = integer.to_int
    raise OverflowError, "integer overflow: given #{integer}, max: #{MAX_INTEGER}" unless integer <= MAX_INTEGER
    raise ArgumentError, "integer should not be negative: given: #{integer}" if integer.negative?

    octets = octets_from_integer(integer, length: OCTETS_LENGTH).freeze
    time_octets = octets.slice(0, TIMESTAMP_OCTETS_LENGTH).freeze
    randomness_octets = octets.slice(TIMESTAMP_OCTETS_LENGTH, RANDOMNESS_OCTETS_LENGTH).freeze
    milliseconds = inverse_of_digits(time_octets)
    entropy = inverse_of_digits(randomness_octets)

    new milliseconds: milliseconds, entropy: entropy
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

  # @return [Integer]
  def self.current_milliseconds
    milliseconds_from_time(Time.now)
  end

  # @param [Time] time
  # @return [Integer]
  def self.milliseconds_from_time(time)
    (time.to_r * 1000).to_i
  end

  # @param [Time, Integer] moment
  # @return [Integer]
  def self.milliseconds_from_moment(moment)
    moment.kind_of?(Time) ? milliseconds_from_time(moment) : moment.to_int
  end

  # @return [Integer]
  def self.reasonable_entropy
    SecureRandom.random_number(MAX_ENTROPY)
  end

  # @param [String, #to_str] string
  # @return [ULID]
  # @raise [ParserError] if the given format is not correct for ULID specs
  # @raise [OverflowError] if the given value is larger than the ULID limit
  def self.parse(string)
    begin
      string = string.to_str
      unless string.size == ENCODED_ID_LENGTH
        raise "parsable string must be #{ENCODED_ID_LENGTH} characters, but actually given #{string.size} characters"
      end
      timestamp = string.slice(0, TIMESTAMP_PART_LENGTH)
      randomness = string.slice(TIMESTAMP_PART_LENGTH, RANDOMNESS_PART_LENGTH)
      milliseconds = Integer::Base.parse(timestamp, ENCODING_CHARS)
      entropy = Integer::Base.parse(randomness, ENCODING_CHARS)
    rescue => err
      raise ParserError, "parsing failure as #{err.inspect} for given #{string.inspect}"
    end
  
    new milliseconds: milliseconds, entropy: entropy
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
  # @param [Integer] integer
  # @param [Integer] length
  # @return [Array<Integer>]
  def self.octets_from_integer(integer, length:)
    digits = integer.digits(256)
    (length - digits.size).times do
      digits.push 0
    end
    digits.reverse!
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

  attr_reader :milliseconds, :entropy

  # @api private
  # @param [Integer] milliseconds
  # @param [Integer] entropy
  # @return [void]
  # @raise [OverflowError] if the given value is larger than the ULID limit
  # @raise [ArgumentError] if the given milliseconds and/or entropy is negative number
  def initialize(milliseconds:, entropy:)
    milliseconds = milliseconds.to_int
    entropy = entropy.to_int
    raise OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}" unless milliseconds <= MAX_MILLISECONDS
    raise OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}" unless entropy <= MAX_ENTROPY
    raise ArgumentError, 'milliseconds and entropy should not be negative' if milliseconds.negative? || entropy.negative?

    @milliseconds = milliseconds
    @entropy = entropy
  end

  # @return [String]
  def to_str
    @string ||= Integer::Base.string_for(to_i, ENCODING_CHARS).rjust(ENCODED_ID_LENGTH, '0').upcase.freeze
  end
  alias_method :to_s, :to_str

  # @return [Integer]
  def to_i
    @integer ||= self.class.inverse_of_digits(octets)
  end
  alias_method :hash, :to_i

  # @return [Integer, nil]
  def <=>(other)
    other.kind_of?(ULID) ? (to_i <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{to_str})".freeze
  end

  # @return [Boolean]
  def eql?(other)
    other.equal?(self) || (other.kind_of?(ULID) && other.to_i == to_i)
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
    @octets ||= (timestamp_octets + randomness_octets).freeze
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer)]
  def timestamp_octets
    @timestamp_octets ||= self.class.octets_from_integer(@milliseconds, length: TIMESTAMP_OCTETS_LENGTH).freeze
  end

  # @return [Array(Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer, Integer)]
  def randomness_octets
    @randomness_octets ||= self.class.octets_from_integer(@entropy, length: RANDOMNESS_OCTETS_LENGTH).freeze
  end

  # @return [String]
  def timestamp
    @timestamp ||= matchdata[:timestamp].freeze
  end

  # @return [String]
  def randomness
    @randomness ||= matchdata[:randomness].freeze
  end

  # @return [Regexp]
  def pattern
    @pattern ||= /(?<timestamp>#{timestamp})(?<randomness>#{randomness})/i.freeze
  end

  # @return [Regexp]
  def strict_pattern
    @strict_pattern ||= /\A#{pattern.source}\z/i.freeze
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

  # @return [String]
  def to_uuidv4
    @uidv4 ||= begin
      # This code referenced https://github.com/ruby/ruby/blob/121fa24a3451b45c41ac0a661b64e9fc8600e589/lib/securerandom.rb#L221-L241
      array = octets.pack('C*').unpack('NnnnnN')
      array[2] = (array[2] & 0x0fff) | 0x4000
      array[3] = (array[3] & 0x3fff) | 0x8000
      ('%08x-%04x-%04x-%04x-%04x%08x' % array).freeze
    end
  end

  # @return [self]
  def freeze
    # Need to evaluate all lazy calucations. If not, raises FrozenError when called the method after frozen
    inspect
    octets
    to_i
    succ
    pred
    strict_pattern
    to_uuidv4
    super
  end

  private

  # @return [MatchData]
  def matchdata
    @matchdata ||= STRICT_PATTERN.match(to_str).freeze
  end
end

require_relative 'ulid/version'
require_relative 'ulid/monotonic_generator'

class ULID
  MONOTONIC_GENERATOR = MonotonicGenerator.new

  private_constant :ENCODING_CHARS, :TIME_FORMAT_IN_INSPECT, :UUIDV4_PATTERN
end
