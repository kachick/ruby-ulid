# coding: us-ascii
# frozen_string_literal: true

# Copyright (C) 2021 Kenichi Kamiya

class ULID
  # @see https://www.crockford.com/base32.html
  #
  # This module supporting only `subset of original crockford for actual use-case` in ULID context.
  # Original decoding spec allows other characters.
  # But I think ULID should allow `subset` of Crockford's Base32.
  # See below
  #   * https://github.com/ulid/spec/pull/57
  #   * https://github.com/kachick/ruby-ulid/issues/57
  #   * https://github.com/kachick/ruby-ulid/issues/78
  module CrockfordBase32
    class SetupError < UnexpectedError; end

    n32_chars = [*'0'..'9', *'A'..'V'].map(&:freeze).freeze
    raise SetupError, 'obvious bug exists in the mapping algorithm' unless n32_chars.size == 32

    n32_char_by_number = {}
    n32_chars.each_with_index do |char, index|
      n32_char_by_number[index] = char
    end
    n32_char_by_number.freeze

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

    N32_CHAR_BY_CROCKFORD_BASE32_CHAR = CROCKFORD_BASE32_ENCODING_STRING.chars.map(&:freeze).each_with_object({}) do |encoding_char, map|
      if n = crockford_base32_mappings[encoding_char]
        char_32 = n32_char_by_number.fetch(n)
        map[encoding_char] = char_32
      end
    end.freeze
    raise SetupError, 'obvious bug exists in the mapping algorithm' unless N32_CHAR_BY_CROCKFORD_BASE32_CHAR.keys == crockford_base32_mappings.keys

    CROCKFORD_BASE32_CHAR_PATTERN = /[#{N32_CHAR_BY_CROCKFORD_BASE32_CHAR.keys.join}]/.freeze

    CROCKFORD_BASE32_CHAR_BY_N32_CHAR = N32_CHAR_BY_CROCKFORD_BASE32_CHAR.invert.freeze
    N32_CHAR_PATTERN = /[#{CROCKFORD_BASE32_CHAR_BY_N32_CHAR.keys.join}]/.freeze

    STANDARD_BY_VARIANT = {
      'L' => '1',
      'l' => '1',
      'I' => '1',
      'i' => '1',
      'O' => '0',
      'o' => '0',
      '-' => ''
    }.freeze
    VARIANT_PATTERN = /[#{STANDARD_BY_VARIANT.keys.join}]/.freeze

    # @api private
    # @param [String] string
    # @return [Integer]
    def self.decode(string)
      n32encoded = string.upcase.gsub(CROCKFORD_BASE32_CHAR_PATTERN, N32_CHAR_BY_CROCKFORD_BASE32_CHAR)
      n32encoded.to_i(32)
    end

    # @api private
    # @param [Integer] integer
    # @return [String]
    def self.encode(integer)
      n32encoded = integer.to_s(32)
      n32encoded.upcase.gsub(N32_CHAR_PATTERN, CROCKFORD_BASE32_CHAR_BY_N32_CHAR).rjust(ENCODED_LENGTH, '0')
    end

    # @api private
    # @param [String] string
    # @return [String]
    def self.normalize(string)
      string.gsub(VARIANT_PATTERN, STANDARD_BY_VARIANT)
    end
  end
end
