# coding: us-ascii
# frozen_string_literal: true
# shareable_constant_value: literal

# Copyright (C) 2021 Kenichi Kamiya

require_relative('errors')
require_relative('utils')

class ULID
  module UUID
    BASE_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\z/i
    # Imported from https://stackoverflow.com/a/38191104/1212807, thank you!
    V4_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i

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

    # @see https://www.rfc-editor.org/rfc/rfc4122#section-4.1.2
    # @todo Replace to Data class after dropped Ruby 3.1
    # @note Using `Fields = Struct.new` syntax made https://github.com/kachick/ruby-ulid/issues/233 again. So use class syntax instead
    class Fields < Struct.new(:time_low, :time_mid, :time_hi_and_version, :clock_seq_hi_and_res, :clk_seq_low, :node, keyword_init: true)
      def self.raw_from_octets(octets)
        case octets.pack('C*').unpack('NnnnnN')
        in [Integer => time_low, Integer => time_mid, Integer => time_hi_and_version, Integer => clock_seq_hi_and_res, Integer => clk_seq_low, Integer => node]
          new(time_low:, time_mid:, time_hi_and_version:, clock_seq_hi_and_res:, clk_seq_low:, node:).freeze
        end
      end

      def self.forced_v4_from_octets(octets)
        case octets.pack('C*').unpack('NnnnnN')
        in [Integer => time_low, Integer => time_mid, Integer => time_hi_and_version, Integer => clock_seq_hi_and_res, Integer => clk_seq_low, Integer => node]
          new(
            time_low:,
            time_mid:,
            time_hi_and_version: (time_hi_and_version & 0x0fff) | 0x4000,
            clock_seq_hi_and_res: (clock_seq_hi_and_res & 0x3fff) | 0x8000,
            clk_seq_low:,
            node:
          ).freeze
        end
      end

      def to_s
        '%08x-%04x-%04x-%04x-%04x%08x' % values
      end
    end
  end

  Ractor.make_shareable(UUID)

  private_constant(:UUID)
end
