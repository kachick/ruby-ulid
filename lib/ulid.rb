# coding: us-ascii
# frozen_string_literal: true
# Copyright (C) 2021 Kenichi Kamiya

require 'securerandom'
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
  RANDOM_PART_LENGTH = 16
  ENCODED_LENGTH = TIME_PART_LENGTH + RANDOM_PART_LENGTH
  TIME_OCTETS_LENGTH = 6
  RANDOMNESS_OCTETS_LENGTH = 10
  OCTETS_LENGTH = TIME_OCTETS_LENGTH + RANDOMNESS_OCTETS_LENGTH
  MAX_MILLISECONDS = 281474976710655
  MAX_RANDOMNESS = 1208925819614629174706175

  # @param [Integer, Time] moment
  # @return [ULID]
  def self.generate(moment: current_milliseconds, entropy: reasonable_entropy)
    milliseconds = moment.integer? ? moment : (moment.to_r * 1000).to_i
    new milliseconds: milliseconds, entropy: entropy
  end

  # @return [ULID]
  def self.monotonic_generate
    milliseconds = current_milliseconds
    @monotonic_base_entropy ||= reasonable_entropy
    @monotonic_base_milliseconds ||= milliseconds
    if @monotonic_base_milliseconds != milliseconds
      @monotonic_base_milliseconds = milliseconds
      @monotonic_base_entropy = reasonable_entropy
    else
      @monotonic_base_entropy += 1
    end

    new milliseconds: milliseconds, entropy: @monotonic_base_entropy
  end

  # @return [Integer]
  def self.current_milliseconds
    (Time.now.to_r * 1000).to_i
  end

  # @return [Integer]
  def self.reasonable_entropy
    SecureRandom.random_number(MAX_RANDOMNESS)
  end

  # @param [String] string
  # @return [ULID]
  def self.parse(string)
    begin
      string = string.to_str
      raise ParserError unless string.size == ENCODED_LENGTH
      timestamp = string.slice(0, TIME_PART_LENGTH)
      randomness = string.slice(TIME_PART_LENGTH, RANDOM_PART_LENGTH)
      milliseconds = Integer::Base.parse(timestamp, ENCODING_CHARS)
      entropy = Integer::Base.parse(randomness, ENCODING_CHARS)
    rescue => err
      raise ParserError, "parsing failure from #{err.inspect}"
    end
  
    new milliseconds: milliseconds, entropy: entropy
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
    raise OverflowError, "timestamp over flow: given #{milliseconds}, max: #{MAX_MILLISECONDS}" unless milliseconds <= MAX_MILLISECONDS
    raise OverflowError, "entropy over flow: given #{entropy}, max: #{MAX_RANDOMNESS}" unless entropy <= MAX_RANDOMNESS
    raise ArgumentError if milliseconds.negative? || entropy.negative?

    @milliseconds = milliseconds
    @entropy = entropy
  end

  # @return [String]
  def to_s
    @string ||= Integer::Base.string_for(to_i, ENCODING_CHARS).rjust(ENCODED_LENGTH, '0').upcase.freeze
  end

  # @return [Integer]
  def to_i
    @integer ||= self.class.inverse_of_digits(octets)
  end
  alias_method :hash, :to_i

  # @return [Boolean, nil]
  def <=>(other)
    other.kind_of?(self.class) ? (to_i <=> other.to_i) : nil
  end

  # @return [String]
  def inspect
    @inspect ||= "ULID(#{to_time}: #{to_s})".freeze
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
end