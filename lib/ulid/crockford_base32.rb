# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

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
    class SetupError < UnexpectedError
    end

    number_has_same_definition = {
      '0' => '0',
      '1' => '1',
      '2' => '2',
      '3' => '3',
      '4' => '4',
      '5' => '5',
      '6' => '6',
      '7' => '7',
      '8' => '8',
      '9' => '9'
    }.freeze

    upcase_base32_to_crockford = {
      'A' => 'A',
      'B' => 'B',
      'C' => 'C',
      'D' => 'D',
      'E' => 'E',
      'F' => 'F',
      'G' => 'G',
      'H' => 'H',
      'I' => 'J',
      'J' => 'K',
      'K' => 'M',
      'L' => 'N',
      'M' => 'P',
      'N' => 'Q',
      'O' => 'R',
      'P' => 'S',
      'Q' => 'T',
      'R' => 'V',
      'S' => 'W',
      'T' => 'X',
      'U' => 'Y',
      'V' => 'Z'
    }.freeze
    upcase_crockford_to_base32 = upcase_base32_to_crockford.invert.freeze

    # Excluded I, L, O, U, - from Base32
    base32_to_crockford = {
      **number_has_same_definition,
      **upcase_base32_to_crockford,
      **upcase_base32_to_crockford.transform_keys(&:downcase)
    }.freeze
    TR_PATTERN_FROM_BASE32 = base32_to_crockford.keys.join.freeze
    TR_PATTERN_TO_CROCKFORD = base32_to_crockford.values.join.freeze

    crockford_to_base32 = {
      **number_has_same_definition,
      **upcase_crockford_to_base32,
      **upcase_crockford_to_base32.transform_keys(&:downcase)
    }.freeze
    TR_PATTERN_FROM_CROCKFORD = crockford_to_base32.keys.join.freeze
    TR_PATTERN_TO_BASE32 = crockford_to_base32.values.join.freeze

    # Do not include same char both downcase and upcase
    ENCODING_STRING = { **number_has_same_definition, **upcase_base32_to_crockford }.values.join.freeze

    unless (base32_to_crockford.size == crockford_to_base32.size) && (base32_to_crockford.size == 32 + (32 - number_has_same_definition.size))
      raise(SetupError, 'obvious bug exists in mapping algorithm')
    end

    variant_to_normarized = {
      'L' => '1',
      'l' => '1',
      'I' => '1',
      'i' => '1',
      'O' => '0',
      'o' => '0'
    }.freeze
    VARIANT_TR_PATTERN = variant_to_normarized.keys.join.freeze
    NORMALIZED_TR_PATTERN = variant_to_normarized.values.join.freeze

    # @note Avoid to depend regex as possible. `tr(string, string)` is almost 2x Faster than `gsub(regex, hash)` in Ruby 3.1

    # @api private
    # @param [String] string
    # @return [Integer]
    def self.decode(string)
      n32encoded = string.tr(TR_PATTERN_FROM_CROCKFORD, TR_PATTERN_TO_BASE32)
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
      n32encoded.tr(TR_PATTERN_FROM_BASE32, TR_PATTERN_TO_CROCKFORD)
    end
  end
end
