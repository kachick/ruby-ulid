# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require_relative('errors')
require_relative('utils')
require_relative('uuid/fields')

class ULID
  module UUID
    BASE_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\z/i
    # Imported from https://stackoverflow.com/a/38191104/1212807, thank you!
    V4_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i
    V7_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-7[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i

    def self.parse_any_to_int(uuidish)
      encoded = String.try_convert(uuidish)
      raise(ArgumentError, 'should pass a string for UUID parser') unless encoded

      prefix_trimmed = encoded.delete_prefix('urn:uuid:')
      unless BASE_PATTERN.match?(prefix_trimmed)
        raise(ParserError, "given `#{encoded}` does not match to `#{BASE_PATTERN.inspect}`")
      end

      normalized = prefix_trimmed.gsub(/[^0-9A-Fa-f]/, '')
      Integer(normalized, 16, exception: true)
    end

    def self.parse_v4_to_int(uuid)
      encoded = String.try_convert(uuid)
      raise(ArgumentError, 'should pass a string for UUID parser') unless encoded

      prefix_trimmed = encoded.delete_prefix('urn:uuid:')
      unless V4_PATTERN.match?(prefix_trimmed)
        raise(ParserError, "given `#{encoded}` does not match to `#{V4_PATTERN.inspect}`")
      end

      parse_any_to_int(encoded)
    end

    def self.parse_v7_to_int(uuid)
      encoded = String.try_convert(uuid)
      raise(ArgumentError, 'should pass a string for UUID parser') unless encoded

      prefix_trimmed = encoded.delete_prefix('urn:uuid:')
      unless V7_PATTERN.match?(prefix_trimmed)
        raise(ParserError, "given `#{encoded}` does not match to `#{V7_PATTERN.inspect}`")
      end

      parse_any_to_int(encoded)
    end
  end

  Ractor.make_shareable(UUID)

  private_constant(:UUID)
end
