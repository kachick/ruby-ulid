# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require_relative('errors')

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

    # Excluded I, L, O, U, -.
    # This is the encoding patterns.
    # The decoding issue is written in ULID::CrockfordBase32
    ENCODING_STRING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
    raise(SetupError, 'obvious bug exists to define CrockfordBase32 encoding') unless ENCODING_STRING.size == 32

    ORDERED_CROCKFORD_BASE32_CHARS = ENCODING_STRING.chars.map(&:freeze).freeze
    CROCKFORD_BASE32_CHAR_PATTERN = /[#{ENCODING_STRING}]/.freeze

    # @todo Inline the definition to combined HashMap with ORDERED_CROCKFORD_BASE32_CHARS to improve readability
    ORDERED_N32_CHARS = [*'0'..'9', *'A'..'V'].map(&:freeze).freeze
    raise(SetupError, 'obvious bug exists to define the Base32 encoding') unless ORDERED_N32_CHARS.size == ORDERED_CROCKFORD_BASE32_CHARS.size

    N32_CHAR_BY_CROCKFORD_BASE32_CHAR = ORDERED_CROCKFORD_BASE32_CHARS.zip(ORDERED_N32_CHARS).to_h.freeze

    CROCKFORD_BASE32_TR_PATTERN = ORDERED_CROCKFORD_BASE32_CHARS.join.freeze
    N32_TR_PATTERN = N32_CHAR_BY_CROCKFORD_BASE32_CHAR.values.join.freeze

    normarized_by_variant = {
      'L' => '1',
      'l' => '1',
      'I' => '1',
      'i' => '1',
      'O' => '0',
      'o' => '0'
    }.freeze
    VARIANT_TR_PATTERN = normarized_by_variant.keys.join.freeze
    NORMALIZED_TR_PATTERN = normarized_by_variant.values.join.freeze

    # @note Avoid to depend regex as possible. `tr(string, string)` is almost 2x Faster than `gsub(regex, hash)` in Ruby 3.1

    # @api private
    # @param [String] string
    # @return [Integer]
    def self.decode(string)
      n32encoded = string.upcase.tr(CROCKFORD_BASE32_TR_PATTERN, N32_TR_PATTERN)
      n32encoded.to_i(32)
    end

    # @api private
    # @param [Integer] integer
    # @return [String]
    def self.encode(integer)
      n32encoded = integer.to_s(32)
      from_n32(n32encoded).rjust(ENCODED_LENGTH, '0')
    end

    # @api private
    # @param [String] string
    # @return [String]
    def self.normalize(string)
      string.delete('-').tr(VARIANT_TR_PATTERN, NORMALIZED_TR_PATTERN)
    end

    # @api private
    # @param [String] n32encoded
    # @return [String]
    def self.from_n32(n32encoded)
      n32encoded.upcase.tr(N32_TR_PATTERN, CROCKFORD_BASE32_TR_PATTERN)
    end
  end
end
