# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

require 'securerandom'
require 'singleton'
require 'integer/base'
require_relative 'ulid/version'

# @see https://github.com/ulid/spec
class ULID
  include Comparable

  class Error < StandardError; end
  class OverflowError < Error; end
  class ParserError < Error; end

  # Crockford's Base32. Excluded I, L, O, U.
  # @see https://www.crockford.com/base32.html
  ENCODING_CHARS = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'.chars.map(&:freeze).freeze

  TIME_PART_LENGTH = 10
  RANDOMNESS_PART_LENGTH = 16
  ENCODED_ID_LENGTH = TIME_PART_LENGTH + RANDOMNESS_PART_LENGTH
  TIME_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = TIME_OCTETS_LENGTH + RANDOMNESS_OCTETS_LENGTH
  MAX_MILLISECONDS = 281474976710655
  MAX_ENTROPY = 1208925819614629174706175

  # Same as Time#inspect since Ruby 2.7, just to keep backward compatibility
  # @see https://bugs.ruby-lang.org/issues/15958
  TIME_FORMAT_IN_INSPECT = '%Y-%m-%d %H:%M:%S.%3N %Z'

  class MonotonicGenerator
    include Singleton

    attr_accessor :latest_milliseconds, :latest_entropy

    def initialize
      reset
    end

    # @return [ULID]
    def generate
      milliseconds = ULID.current_milliseconds
      reasonable_entropy = ULID.reasonable_entropy

      @latest_milliseconds ||= milliseconds
      @latest_entropy ||= reasonable_entropy
      if @latest_milliseconds != milliseconds
        @latest_milliseconds = milliseconds
        @latest_entropy = reasonable_entropy
      else
        @latest_entropy += 1
      end

      ULID.new milliseconds: milliseconds, entropy: @latest_entropy
    end

    # @return [self]
    def reset
      @latest_milliseconds = nil
      @latest_entropy = nil
      self
    end

    # @return [void]
    def freeze
      raise TypeError, "cannot freeze #{self.class}"
    end
  end

  MONOTONIC_GENERATOR = MonotonicGenerator.instance

  private_constant :ENCODING_CHARS, :TIME_FORMAT_IN_INSPECT, :MonotonicGenerator

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.generate(moment: current_milliseconds, entropy: reasonable_entropy)
    milliseconds = moment.kind_of?(Time) ? (moment.to_r * 1000).to_i : moment.to_int
    new milliseconds: milliseconds, entropy: entropy
  end

  # @return [ULID]
  def self.monotonic_generate
    MONOTONIC_GENERATOR.generate
  end

  # @return [Integer]
  def self.current_milliseconds
    time_to_milliseconds(Time.now)
  end

  # @param [Time]
  # @return [Integer]
  def self.time_to_milliseconds(time)
    (time.to_r * 1000).to_i
  end

  # @return [Integer]
  def self.reasonable_entropy
    SecureRandom.random_number(MAX_ENTROPY)
  end

  # @param [String, #to_str] string
  # @return [ULID]
  def self.parse(string)
    begin
      string = string.to_str
      unless string.size == ENCODED_ID_LENGTH
        raise "parsable string must be #{ENCODED_ID_LENGTH} characters, but actually given #{string.size} characters"
      end
      timestamp = string.slice(0, TIME_PART_LENGTH)
      randomness = string.slice(TIME_PART_LENGTH, RANDOMNESS_PART_LENGTH)
      milliseconds = Integer::Base.parse(timestamp, ENCODING_CHARS)
      entropy = Integer::Base.parse(randomness, ENCODING_CHARS)
    rescue => err
      raise ParserError, "parsing failure as #{err.inspect} for given #{string.inspect}"
    end
  
    new milliseconds: milliseconds, entropy: entropy
  end

  # @param [String] string
  # @return [Boolean]
  def self.valid?(string)
    parse(string)
  rescue Exception
    false
  else
    true
  end

  def self.octets_from_integer(integer, length:)
    digits = integer.digits(256)
    (length - digits.size).times do
      digits.push 0
    end
    digits.reverse!
  end

  # @see The logics taken from https://bugs.ruby-lang.org/issues/14401, thanks!
  def self.inverse_of_digits(reversed_digits)
    base = 256
    num = 0
    reversed_digits.each do |digit|
      num = (num * base) + digit
    end
    num
  end

  attr_reader :milliseconds, :entropy

  def initialize(milliseconds:, entropy:)
    raise OverflowError, "timestamp overflow: given #{milliseconds}, max: #{MAX_MILLISECONDS}" unless milliseconds <= MAX_MILLISECONDS
    raise OverflowError, "entropy overflow: given #{entropy}, max: #{MAX_ENTROPY}" unless entropy <= MAX_ENTROPY
    raise ArgumentError if milliseconds.negative? || entropy.negative?

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
    other.kind_of?(self.class) ? (to_i <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time.strftime(TIME_FORMAT_IN_INSPECT)}: #{to_str})".freeze
  end

  # @return [Boolean]
  def eql?(other)
    other.equal?(self) || (other.kind_of?(self.class) && other.to_i == to_i)
  end
  alias_method :==, :eql?

  # @return [Time]
  def to_time
    @time ||= Time.at(0, @milliseconds, :millisecond).utc
  end

  # @return [Array<Integer>]
  def octets
    @octets ||= (time_octets + randomness_octets).freeze
  end

  # @return [Array<Integer>]
  def time_octets
    @time_octets ||= self.class.octets_from_integer(@milliseconds, length: TIME_OCTETS_LENGTH).freeze
  end

  # @return [Array<Integer>]
  def randomness_octets
    @randomness_octets ||= self.class.octets_from_integer(@entropy, length: RANDOMNESS_OCTETS_LENGTH).freeze
  end

  # @return [ULID]
  def next
    @next ||= self.class.new(milliseconds: @milliseconds, entropy: @entropy + 1)
  end
  alias_method :succ, :next

  # @return [self]
  def freeze
    # Evaluate all caching
    inspect
    octets
    succ
    to_i
    super
  end
end
